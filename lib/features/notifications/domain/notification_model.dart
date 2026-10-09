import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type;      // 'member_joined', 'invite_accepted',
                          // 'transaction_added', 'transaction_updated',
                          // 'transaction_deleted', 'report_ready'
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.read = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'read': read,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory NotificationModel.fromMap(Map<String, dynamic> m) =>
      NotificationModel(
        id: m['id'] ?? '',
        type: m['type'] ?? '',
        title: m['title'] ?? '',
        body: m['body'] ?? '',
        data: m['data'] != null
            ? Map<String, dynamic>.from(m['data'])
            : null,
        read: m['read'] ?? false,
        createdAt:
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  // Ícone por tipo de notificação
  String get iconKey {
    switch (type) {
      case 'member_joined':
        return 'person_add';
      case 'invite_accepted':
        return 'check_circle';
      case 'transaction_added':
        return 'add_circle';
      case 'transaction_updated':
        return 'edit';
      case 'transaction_deleted':
        return 'delete';
      case 'report_ready':
        return 'bar_chart';
      default:
        return 'notifications';
    }
  }
}
