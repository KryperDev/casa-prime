import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/auth_service.dart';
import '../domain/notification_model.dart';
import '../domain/notification_settings.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  // ============================================================
  //  STREAMS - leitura para o usuário atual
  // ============================================================
  Stream<List<NotificationModel>> watchMyNotifications({int limit = 50}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NotificationModel.fromMap(d.data()))
            .toList());
  }

  Stream<int> watchMyUnreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ============================================================
  //  AÇÕES do destinatário
  // ============================================================
  Future<void> markAsRead(String notificationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(id)
        .delete();
  }

  // ============================================================
  //  CONFIGURAÇÕES do usuário
  // ============================================================
  Stream<NotificationSettings> watchMySettings() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const NotificationSettings());

    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      return NotificationSettings.fromMap(
          data?['notificationSettings'] as Map<String, dynamic>?);
    });
  }

  Future<void> updateMySettings(NotificationSettings s) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'notificationSettings': s.toMap(),
    });
  }

  // ============================================================
  //  DISPARO de notificação (uso interno pelos outros services)
  // ============================================================
  /// Envia notificação para vários usuários.
  /// Cada usuário recebe uma cópia em `users/{uid}/notifications`.
  Future<void> notifyUsers({
    required List<String> userIds,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? excludeUserId,
  }) async {
    final senderUid = _auth.currentUser?.uid;
    if (senderUid == null) return;

    final targets = userIds
        .where((id) => id.isNotEmpty && id != excludeUserId)
        .toSet();

    if (targets.isEmpty) return;

    final batch = _db.batch();
    for (final uid in targets) {
      // Checa a preferência do destinatário antes de criar
      final shouldSend = await _shouldSend(uid, type);
      if (!shouldSend) continue;

      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc();
      batch.set(ref, {
        'id': ref.id,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<bool> _shouldSend(String uid, String type) async {
    final doc = await _db.collection('users').doc(uid).get();
    final settings = NotificationSettings.fromMap(
        doc.data()?['notificationSettings'] as Map<String, dynamic>?);
    switch (type) {
      case 'member_joined':
        return settings.memberJoined;
      case 'invite_accepted':
        return settings.inviteAccepted;
      case 'transaction_added':
        return settings.transactionAdded;
      case 'transaction_updated':
        return settings.transactionUpdated;
      case 'transaction_deleted':
        return settings.transactionDeleted;
      case 'report_ready':
        return settings.reportReady;
      default:
        return true;
    }
  }

  // ============================================================
  //  Utilitário: membros de uma família (para disparo em massa)
  // ============================================================
  Future<List<String>> familyMemberIds(String familyId) async {
    final doc = await _db.collection('families').doc(familyId).get();
    final list = (doc.data()?['memberIds'] ?? []) as List;
    return list.map((e) => e.toString()).toList();
  }

  Future<String?> familyAdminId(String familyId) async {
    final doc = await _db.collection('families').doc(familyId).get();
    return doc.data()?['adminId'] as String?;
  }
}
