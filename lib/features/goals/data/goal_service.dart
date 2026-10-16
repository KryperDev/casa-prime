import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/auth_service.dart';
import '../../transactions/data/transaction_service.dart';
import '../../transactions/domain/transaction_model.dart';
import '../domain/goal_model.dart';

class GoalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();
  final TransactionService _tx = TransactionService();

  // ============================================================
  //  STREAMS
  // ============================================================
  Stream<List<GoalModel>> watchGoals(String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('goals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => GoalModel.fromMap(d.data()))
            .toList());
  }

  // ============================================================
  //  CREATE
  // ============================================================
  Future<String> createGoal({
    required String familyId,
    required String name,
    String? description,
    required double targetAmount,
    DateTime? deadline,
    required String icon,
    required String color,
  }) async {
    final uid = _auth.currentUser!.uid;
    final user = await _auth.fetchCurrentUser();

    final ref = _db
        .collection('families')
        .doc(familyId)
        .collection('goals')
        .doc();

    final goal = GoalModel(
      id: ref.id,
      name: name.trim(),
      description:
          (description?.trim().isEmpty ?? true) ? null : description!.trim(),
      targetAmount: targetAmount,
      currentAmount: 0,
      deadline: deadline,
      createdBy: uid,
      createdByName: user?.displayName ?? 'Usuário',
      createdAt: DateTime.now(),
      icon: icon,
      color: color,
    );

    await ref.set(goal.toMap());
    return ref.id;
  }

  // ============================================================
  //  UPDATE
  // ============================================================
  Future<void> updateGoal({
    required String familyId,
    required GoalModel goal,
  }) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('goals')
        .doc(goal.id)
        .update(goal.toMap());
  }

  // ============================================================
  //  GARANTIR categoria "Metas e Objetivos" na familia
  // ============================================================
  Future<Map<String, String>> _garantirCategoriaMeta(String familyId) async {
    final col = _db
        .collection('families')
        .doc(familyId)
        .collection('categories');

    final existente = await col
        .where('name', isEqualTo: 'Metas e Objetivos')
        .where('type', isEqualTo: 'expense')
        .limit(1)
        .get();

    if (existente.docs.isNotEmpty) {
      final d = existente.docs.first;
      return {'id': d.id, 'name': 'Metas e Objetivos'};
    }

    // Cria
    final ref = col.doc();
    await ref.set({
      'id': ref.id,
      'name': 'Metas e Objetivos',
      'type': 'expense',
      'icon': 'savings',
      'subcategories': <Map<String, dynamic>>[],
    });
    return {'id': ref.id, 'name': 'Metas e Objetivos'};
  }

  // ============================================================
  //  ADICIONAR / RETIRAR VALOR DA META
  //  Se criarLancamento=true, tambem registra uma transacao
  //  na familia (saida para guardar, entrada para resgatar).
  // ============================================================
  Future<void> addToGoal({
    required String familyId,
    required GoalModel goal,
    required double amount, // positivo = guardar, negativo = resgatar
    bool criarLancamento = true,
  }) async {
    final novo = (goal.currentAmount + amount).clamp(0, double.infinity);
    final completo = novo >= goal.targetAmount;

    // 1) Atualiza o valor da meta
    await _db
        .collection('families')
        .doc(familyId)
        .collection('goals')
        .doc(goal.id)
        .update({
      'currentAmount': novo,
      'status': completo ? 'completed' : 'active',
    });

    // 2) Se pedido, cria o lancamento
    if (criarLancamento && amount != 0) {
      final cat = await _garantirCategoriaMeta(familyId);

      if (amount > 0) {
        // Saída: guardou dinheiro
        await _tx.addTransaction(
          familyId: familyId,
          type: TransactionType.expense,
          amount: amount,
          description: 'Guardado para "${goal.name}"',
          categoryId: cat['id']!,
          categoryName: cat['name']!,
          date: DateTime.now(),
          competenceDate: DateTime.now(),
          goalId: goal.id,
        );
      } else {
        // Entrada: resgatou
        await _tx.addTransaction(
          familyId: familyId,
          type: TransactionType.income,
          amount: amount.abs(),
          description: 'Resgatado de "${goal.name}"',
          categoryId: cat['id']!,
          categoryName: cat['name']!,
          date: DateTime.now(),
          competenceDate: DateTime.now(),
          goalId: goal.id,
        );
      }
    }
  }

  // ============================================================
  //  DELETE
  // ============================================================
  Future<void> deleteGoal({
    required String familyId,
    required String goalId,
  }) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('goals')
        .doc(goalId)
        .delete();
  }

  // ============================================================
  //  BUSCAR lancamentos vinculados a uma meta
  // ============================================================
  Stream<List<TransactionModel>> watchGoalTransactions({
    required String familyId,
    required String goalId,
  }) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .where('goalId', isEqualTo: goalId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => TransactionModel.fromMap(d.data()))
          .where((t) => t.status == 'active')
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
