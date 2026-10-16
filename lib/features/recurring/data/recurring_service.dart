import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/auth_service.dart';
import '../../transactions/data/transaction_service.dart';
import '../../transactions/domain/transaction_model.dart';
import '../domain/recurring_model.dart';

class RecurringService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();
  final TransactionService _tx = TransactionService();

  // ============================================================
  //  STREAMS
  // ============================================================
  Stream<List<RecurringModel>> watchRecurrings(String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('recurrings')
        .orderBy('nextDate')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RecurringModel.fromMap(d.data()))
            .toList());
  }

  // ============================================================
  //  CREATE
  // ============================================================
  Future<String> createRecurring({
    required String familyId,
    required String description,
    required TransactionType type,
    required double amount,
    required String categoryId,
    required String categoryName,
    String? subcategoryId,
    String? subcategoryName,
    String? paymentMethod,
    String? accountId,
    String? accountName,
    String? note,
    required RecurrenceFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final uid = _auth.currentUser!.uid;
    final user = await _auth.fetchCurrentUser();

    final ref = _db
        .collection('families')
        .doc(familyId)
        .collection('recurrings')
        .doc();

    // A primeira ocorrência é a data de início
    final r = RecurringModel(
      id: ref.id,
      familyId: familyId,
      description: description.trim(),
      type: type,
      amount: amount,
      categoryId: categoryId,
      categoryName: categoryName,
      subcategoryId: subcategoryId,
      subcategoryName: subcategoryName,
      paymentMethod: paymentMethod,
      accountId: accountId,
      accountName: accountName,
      note: note,
      frequency: frequency,
      startDate: startDate,
      nextDate: startDate,
      endDate: endDate,
      active: true,
      createdBy: uid,
      createdByName: user?.displayName ?? 'Usuário',
      createdAt: DateTime.now(),
    );

    await ref.set(r.toMap());
    return ref.id;
  }

  // ============================================================
  //  UPDATE
  // ============================================================
  Future<void> updateRecurring({
    required String familyId,
    required RecurringModel recurring,
  }) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('recurrings')
        .doc(recurring.id)
        .update(recurring.toMap());
  }

  // ============================================================
  //  TOGGLE (pausar / retomar)
  // ============================================================
  Future<void> toggleActive({
    required String familyId,
    required String recurringId,
    required bool active,
  }) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('recurrings')
        .doc(recurringId)
        .update({'active': active});
  }

  // ============================================================
  //  DELETE
  // ============================================================
  Future<void> deleteRecurring({
    required String familyId,
    required String recurringId,
  }) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('recurrings')
        .doc(recurringId)
        .delete();
  }

  // ============================================================
  //  PROCESSAR VENCIDAS
  //  Cria os lançamentos cuja nextDate <= agora
  //  e avança nextDate para a próxima ocorrência.
  //  Segurança: máximo de 60 lançamentos por vez para não travar.
  // ============================================================
  Future<int> processarVencidas(String familyId) async {
    final now = DateTime.now();
    final snap = await _db
        .collection('families')
        .doc(familyId)
        .collection('recurrings')
        .where('active', isEqualTo: true)
        .where('nextDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    if (snap.docs.isEmpty) return 0;

    int total = 0;
    for (final doc in snap.docs) {
      var r = RecurringModel.fromMap(doc.data());

      while (r.nextDate.isBefore(now) ||
          r.nextDate.isAtSameMomentAs(now)) {
        if (r.endDate != null && r.nextDate.isAfter(r.endDate!)) {
          // Chegou ao fim: desativa
          await doc.reference.update({'active': false});
          break;
        }

        // Cria o lançamento
        try {
          await _tx.addTransaction(
            familyId: familyId,
            type: r.type,
            amount: r.amount,
            description: r.description,
            categoryId: r.categoryId,
            categoryName: r.categoryName,
            subcategoryId: r.subcategoryId,
            subcategoryName: r.subcategoryName,
            date: r.nextDate,
            competenceDate: r.nextDate,
            paymentMethod: r.paymentMethod,
            accountId: r.accountId,
            accountName: r.accountName,
            note: r.note != null
                ? '${r.note!} (recorrente)'
                : 'Lançamento recorrente',
          );
          total++;
        } catch (_) {
          // Se falhar, continua
        }

        // Avança
        final proxima = r.computeNext(r.nextDate);
        r = RecurringModel(
          id: r.id,
          familyId: r.familyId,
          description: r.description,
          type: r.type,
          amount: r.amount,
          categoryId: r.categoryId,
          categoryName: r.categoryName,
          subcategoryId: r.subcategoryId,
          subcategoryName: r.subcategoryName,
          paymentMethod: r.paymentMethod,
          accountId: r.accountId,
          accountName: r.accountName,
          note: r.note,
          frequency: r.frequency,
          startDate: r.startDate,
          nextDate: proxima,
          endDate: r.endDate,
          active: r.active,
          createdBy: r.createdBy,
          createdByName: r.createdByName,
          createdAt: r.createdAt,
        );

        if (total > 60) break;
      }

      await doc.reference.update({
        'nextDate': Timestamp.fromDate(r.nextDate),
      });
    }
    return total;
  }
}
