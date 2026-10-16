import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/auth_service.dart';
import '../../transactions/data/transaction_service.dart';
import '../../transactions/domain/transaction_model.dart';
import '../domain/installment_model.dart';

class InstallmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();
  final TransactionService _tx = TransactionService();

  // ============================================================
  //  STREAMS
  // ============================================================
  Stream<List<InstallmentModel>> watchInstallments(String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('installments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => InstallmentModel.fromMap(d.data()))
            .toList());
  }

  // ============================================================
  //  CRIAR COMPRA PARCELADA
  //  - Cria o documento da compra em 'installments'
  //  - Cria N lançamentos em 'transactions', um por mês
  // ============================================================
  Future<String> createInstallmentPurchase({
    required String familyId,
    required String description,
    required double totalAmount,
    required int totalInstallments,
    required String categoryId,
    required String categoryName,
    String? subcategoryId,
    String? subcategoryName,
    String? paymentMethod,
    String? accountId,
    String? accountName,
    String? note,
    required DateTime startDate,
  }) async {
    final uid = _auth.currentUser!.uid;
    final user = await _auth.fetchCurrentUser();

    final installmentValue = totalAmount / totalInstallments;
    // Arredonda o valor das parcelas para 2 casas
    final rounded = double.parse(installmentValue.toStringAsFixed(2));
    // Ajusta a última parcela para compensar arredondamento
    final lastValue =
        double.parse((totalAmount - rounded * (totalInstallments - 1))
            .toStringAsFixed(2));

    // Cria o registro da compra
    final purchaseRef = _db
        .collection('families')
        .doc(familyId)
        .collection('installments')
        .doc();

    final purchase = InstallmentModel(
      id: purchaseRef.id,
      familyId: familyId,
      description: description.trim(),
      totalAmount: totalAmount,
      installmentAmount: rounded,
      totalInstallments: totalInstallments,
      categoryId: categoryId,
      categoryName: categoryName,
      subcategoryId: subcategoryId,
      subcategoryName: subcategoryName,
      paymentMethod: paymentMethod,
      accountId: accountId,
      accountName: accountName,
      note: note,
      startDate: startDate,
      createdBy: uid,
      createdByName: user?.displayName ?? 'Usuário',
      createdAt: DateTime.now(),
    );

    await purchaseRef.set(purchase.toMap());

    // Cria as parcelas (1 mês cada)
    for (var i = 0; i < totalInstallments; i++) {
      final data = _addMonths(startDate, i);
      final value = (i == totalInstallments - 1) ? lastValue : rounded;

      await _tx.addTransaction(
        familyId: familyId,
        type: TransactionType.expense,
        amount: value,
        description: '$description (${i + 1}/$totalInstallments)',
        categoryId: categoryId,
        categoryName: categoryName,
        subcategoryId: subcategoryId,
        subcategoryName: subcategoryName,
        date: data,
        competenceDate: data,
        paymentMethod: paymentMethod,
        accountId: accountId,
        accountName: accountName,
        note: note,
        goalId: null,
        purchaseId: purchaseRef.id,
        installmentNumber: i + 1,
        totalInstallments: totalInstallments,
      );
    }

    return purchaseRef.id;
  }

  // ============================================================
  //  EXCLUIR compra inteira (apaga todas as parcelas)
  // ============================================================
  Future<void> deletePurchase({
    required String familyId,
    required String purchaseId,
  }) async {
    // 1) Marca todas as parcelas como 'deleted'
    final txs = await _db
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .where('purchaseId', isEqualTo: purchaseId)
        .get();

    final batch = _db.batch();
    for (final t in txs.docs) {
      batch.update(t.reference, {
        'status': 'deleted',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    // 2) Apaga o documento da compra
    batch.delete(_db
        .collection('families')
        .doc(familyId)
        .collection('installments')
        .doc(purchaseId));
    await batch.commit();
  }

  // ============================================================
  //  BUSCAR parcelas de uma compra
  // ============================================================
  Stream<List<TransactionModel>> watchPurchaseTransactions({
    required String familyId,
    required String purchaseId,
  }) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .where('purchaseId', isEqualTo: purchaseId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => TransactionModel.fromMap(d.data()))
          .where((t) => t.status == 'active')
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  // ============================================================
  //  Helper: soma meses a uma data, respeitando meses curtos
  // ============================================================
  DateTime _addMonths(DateTime from, int months) {
    final totalMonths = from.month + months;
    final year = from.year + ((totalMonths - 1) ~/ 12);
    final month = ((totalMonths - 1) % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = from.day > lastDay ? lastDay : from.day;
    return DateTime(year, month, day, from.hour, from.minute);
  }
}
