import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/notification_service.dart';
import '../../domain/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como lidas',
            onPressed: () => service.markAllAsRead(),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: service.watchMyNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none,
                        size: 72, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Nenhuma notificação ainda.',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          // Agrupa por dia
          final grouped = <String, List<NotificationModel>>{};
          for (final n in list) {
            final key = Formatters.date(n.createdAt);
            grouped.putIfAbsent(key, () => []).add(n);
          }
          final days = grouped.keys.toList();

          return ListView.builder(
            itemCount: days.length,
            itemBuilder: (context, i) {
              final day = days[i];
              final items = grouped[day]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(day,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                  ),
                  ...items.map((n) => _NotificationTile(
                        notification: n,
                        service: service,
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final NotificationService service;

  const _NotificationTile({
    required this.notification,
    required this.service,
  });

  IconData _icon() {
    switch (notification.iconKey) {
      case 'person_add':
        return Icons.person_add;
      case 'check_circle':
        return Icons.check_circle;
      case 'add_circle':
        return Icons.add_circle;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'bar_chart':
        return Icons.bar_chart;
      default:
        return Icons.notifications;
    }
  }

  Color _color() {
    switch (notification.iconKey) {
      case 'person_add':
        return Colors.blue;
      case 'check_circle':
        return Colors.green;
      case 'add_circle':
        return Colors.teal;
      case 'edit':
        return Colors.orange;
      case 'delete':
        return Colors.red;
      case 'bar_chart':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => service.deleteNotification(notification.id),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        color: notification.read ? null : color.withValues(alpha: 0.06),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(_icon(), color: color),
          ),
          title: Text(notification.title,
              style: TextStyle(
                  fontWeight: notification.read
                      ? FontWeight.normal
                      : FontWeight.bold)),
          subtitle: Text(
            '${notification.body}\n'
            '${Formatters.dateTime(notification.createdAt)}',
            style: const TextStyle(fontSize: 12),
          ),
          isThreeLine: true,
          onTap: () {
            if (!notification.read) {
              service.markAsRead(notification.id);
            }
          },
        ),
      ),
    );
  }
}

