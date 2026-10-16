import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../data/recurring_service.dart';
import '../../domain/recurring_model.dart';
import 'edit_recurring_screen.dart';

class RecurringsScreen extends StatelessWidget {
  const RecurringsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final familyService = FamilyService();
    final recurringService = RecurringService();

    return StreamBuilder<FamilyModel?>(
      stream: familyService.watchMyFamily(),
      builder: (context, famSnap) {
        if (!famSnap.hasData) {
          return const Scaffold(body: ListSkeleton());
        }
        final family = famSnap.data!;

        return Scaffold(
          appBar: AppBar(title: const Text('Lançamentos recorrentes')),
          body: StreamBuilder<List<RecurringModel>>(
            stream: recurringService.watchRecurrings(family.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }
              final list = snap.data ?? [];

              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.repeat,
                  title: 'Nenhuma recorrência ainda',
                  subtitle:
                      'Cadastre lançamentos que se repetem todo mês: salário, aluguel, Netflix, academia...',
                  actionLabel: 'Criar primeira',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditRecurringScreen(),
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Card(
                    color: Colors.blue.withValues(alpha: 0.08),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ao abrir o app, os lançamentos vencidos '
                              'são criados automaticamente.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...list.map((r) => _RecurringTile(
                        recurring: r,
                        familyId: family.id,
                      )),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Nova'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EditRecurringScreen(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringModel recurring;
  final String familyId;

  const _RecurringTile({required this.recurring, required this.familyId});

  @override
  Widget build(BuildContext context) {
    final isIncome = recurring.isIncome;
    final color =
        isIncome ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final sign = isIncome ? '+' : '-';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditRecurringScreen(existing: recurring),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(
                  recurring.active ? Icons.repeat : Icons.pause,
                  color: recurring.active ? color : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recurring.description,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!recurring.active)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('pausada',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${recurring.categoryName} • ${recurring.frequency.label}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Próximo: ${Formatters.date(recurring.nextDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: recurring.active ? color : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$sign ${Formatters.money(recurring.amount)}',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
