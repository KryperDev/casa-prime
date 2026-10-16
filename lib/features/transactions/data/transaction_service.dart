import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/auth/data/auth_service.dart';
import '../../notifications/data/notification_service.dart';
import '../domain/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();
  final NotificationService _notif = NotificationService();

  Future<String> addTransaction({
    required String familyId,
    required TransactionType type,
    required double amount,
    required String description,
    required String categoryId,
    required String categoryName,
    String? subcategoryId,
    String? subcategoryName,
    required DateTime date,
    required DateTime competenceDate,
    String? paymentMethod,
    String? accountId,
    String? accountName,
    String? note,
    String? goalId,
    String? purchaseId,
    int? installmentNumber,
    int? totalInstallments,
    bool notify = true,
  }) async {
    final uid = _auth.currentUser!.uid;
    final user = await _auth.fetchCurrentUser();
    final now = DateTime.now();

    final ref = _db
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .doc();

    final tx = {
      'id': ref.id,
      'familyId': familyId,
      'type': type.name,
      'amount': amount,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'subcategoryId': subcategoryId,
      'subcategoryName': subcategoryName,
      'date': Timestamp.fromDate(date),
      'competenceDate': Timestamp.fromDate(competenceDate),
      'paymentMethod': paymentMethod,
      'accountId': accountId,
      'accountName': accountName,
      'note': note,
      'createdBy': uid,
      'createdByName': user?.displayName ?? 'Usuário',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'status': 'active',
      'goalId': goalId,
      'purchaseId': purchaseId,
      'installmentNumber': installmentNumber,
      'totalInstallments': totalInstallments,
    };

    await ref.set(tx);

    await _logAction(
      familyId: familyId,
      action: 'create',
      entityType: 'transaction',
      entityId: ref.id,
      newValue: tx,
    );

    // Notifica outros membros apenas se for lançamento "normal"
    if (notify && purchaseId == null) {
      try {
        final members = await _notif.familyMemberIds(familyId);
        await _notif.notifyUsers(
          userIds: members,
          type: 'transaction_added',
          title: type == TransactionType.income ? 'Nova entrada' : 'Nova despesa',
          body: '${user?.displayName ?? 'Alguém'} lançou "$description" '
              'de R\$ ${amount.toStringAsFixed(2)}.',
          data: {'familyId': familyId, 'transactionId': ref.id},
          excludeUserId: uid,
        );
      } catch (_) {}
    }

    return ref.id;
  }

  Future<void> updateTransaction({
    required String familyId,
    required TransactionModel old,
    required TransactionModel updated,
  }) async {
    final ref = _db
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .doc(updated.id);

    final before = old.toMap();
    final after = updated.toMap()
      ..['updatedAt'] = Timestamp.fromDate(DateTime.now());

    await ref.update(after);

    await _logAction(
      familyId: familyId,
      action: 'update',
      entityType: 'transaction',
      entityId: updated.id,
      oldValue: before,
      newValue: after,
    );

    try {
      final me = _auth.currentUser!.uid;
      final adminId = await _notif.familyAdminId(familyId);
      final targets = <String>{old.createdBy};
      if (adminId != null) targets.add(adminId);
      targets.remove(me);

      await _notif.notifyUsers(
        userIds: targets.toList(),
        type: 'transaction_updated',
        title: 'Lançamento editado',
        body: '"${updated.description}" foi alterado.',
        data: {'familyId': familyId, 'transactionId': updated.id},
        excludeUserId: me,
      );
    } catch (_) {}
  }

  Future<void> deleteTransaction({
    required String familyId,
    required TransactionModel tx,
  }) async {
    final ref = _db
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .doc(tx.id);

    await ref.update({
      'status': 'deleted',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await _logAction(
      familyId: familyId,
      action: 'delete',
      entityType: 'transaction',
      entityId: tx.id,
      oldValue: tx.toMap(),
    );

    try {
      final me = _auth.currentUser!.uid;
      if (tx.createdBy != me) {
        await _notif.notifyUsers(
          userIds: [tx.createdBy],
          type: 'transaction_deleted',
          title: 'Lançamento excluído',
          body: '"${tx.description}" foi removido.',
          data: {'familyId': familyId},
          excludeUserId: me,
        );
      }
    } catch (_) {}
  }

  Stream<List<TransactionModel>> watchTransactions(String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => TransactionModel.fromMap(d.data()))
          .where((t) => t.status == 'active')
          .toList();
    });
  }

  Future<void> _logAction({
    required String familyId,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    final uid = _auth.currentUser!.uid;
    final user = await _auth.fetchCurrentUser();
    await _db
        .collection('families')
        .doc(familyId)
        .collection('audit_logs')
        .add({
      'userId': uid,
      'userName': user?.displayName ?? 'Usuário',
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'oldValue': oldValue,
      'newValue': newValue,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
