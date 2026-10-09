import 'package:flutter/material.dart';
import '../data/notification_service.dart';
import '../domain/notification_settings.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NotificationService();

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: StreamBuilder<NotificationSettings>(
        stream: service.watchMySettings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snapshot.data!;

          Future<void> update(NotificationSettings next) =>
              service.updateMySettings(next);

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Escolha quais notificações deseja receber:',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.person_add),
                title: const Text('Membro entrou na família'),
                value: s.memberJoined,
                onChanged: (v) =>
                    update(s.copyWith(memberJoined: v)),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.check_circle),
                title: const Text('Convite aceito'),
                value: s.inviteAccepted,
                onChanged: (v) =>
                    update(s.copyWith(inviteAccepted: v)),
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.add_circle, color: Colors.teal),
                title: const Text('Lançamento adicionado'),
                subtitle: const Text('Quando alguém da família lança algo'),
                value: s.transactionAdded,
                onChanged: (v) =>
                    update(s.copyWith(transactionAdded: v)),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Lançamento editado'),
                value: s.transactionUpdated,
                onChanged: (v) =>
                    update(s.copyWith(transactionUpdated: v)),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Lançamento excluído'),
                value: s.transactionDeleted,
                onChanged: (v) =>
                    update(s.copyWith(transactionDeleted: v)),
              ),
              const Divider(),
              SwitchListTile(
                secondary:
                    const Icon(Icons.bar_chart, color: Colors.purple),
                title: const Text('Relatório mensal disponível'),
                value: s.reportReady,
                onChanged: (v) => update(s.copyWith(reportReady: v)),
              ),
            ],
          );
        },
      ),
    );
  }
}
