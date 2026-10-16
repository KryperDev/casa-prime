import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../data/goal_service.dart';
import '../../domain/goal_model.dart';
import 'edit_goal_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final familyService = FamilyService();
    final goalService = GoalService();

    return StreamBuilder<FamilyModel?>(
      stream: familyService.watchMyFamily(),
      builder: (context, famSnap) {
        if (!famSnap.hasData) {
          return const Scaffold(body: ListSkeleton());
        }
        final family = famSnap.data!;

        return Scaffold(
          appBar: AppBar(title: const Text('Metas')),
          body: StreamBuilder<List<GoalModel>>(
            stream: goalService.watchGoals(family.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }
              final goals = snap.data ?? [];

              if (goals.isEmpty) {
                return EmptyState(
                  icon: Icons.savings_outlined,
                  title: 'Nenhuma meta ainda',
                  subtitle:
                      'Que tal criar uma meta para juntar dinheiro com a família? Ex: "Viagem de fim de ano".',
                  actionLabel: 'Criar primeira meta',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditGoalScreen(),
                    ),
                  ),
                );
              }

              final ativas = goals.where((g) => !g.isCompleted).toList();
              final concluidas = goals.where((g) => g.isCompleted).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  if (ativas.isNotEmpty) ...[
                    if (concluidas.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('EM ANDAMENTO',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 1.2)),
                      ),
                    ...ativas.map((g) => _GoalCard(
                          goal: g,
                          familyId: family.id,
                        )),
                  ],
                  if (concluidas.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('CONCLUÍDAS 🎉',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              letterSpacing: 1.2)),
                    ),
                    ...concluidas.map((g) => _GoalCard(
                          goal: g,
                          familyId: family.id,
                        )),
                  ],
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Nova meta'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EditGoalScreen(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final String familyId;

  const _GoalCard({required this.goal, required this.familyId});

  Color get _cor {
    try {
      final hex = goal.color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF1E88E5);
    }
  }

  IconData get _icon {
    switch (goal.icon) {
      case 'flight':
        return Icons.flight;
      case 'home':
        return Icons.home;
      case 'directions_car':
        return Icons.directions_car;
      case 'school':
        return Icons.school;
      case 'phone_android':
        return Icons.phone_android;
      case 'favorite':
        return Icons.favorite;
      case 'beach_access':
        return Icons.beach_access;
      case 'celebration':
        return Icons.celebration;
      case 'savings':
      default:
        return Icons.savings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progress * 100).toStringAsFixed(0);
    final concluida = goal.isCompleted;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditGoalScreen(existing: goal),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _cor.withValues(alpha: 0.15),
                    child: Icon(_icon, color: _cor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (goal.description != null &&
                            goal.description!.isNotEmpty)
                          Text(
                            goal.description!,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (concluida)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('🎉 Concluída',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 8,
                  backgroundColor: _cor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(_cor),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.money(goal.currentAmount),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: _cor, fontSize: 15),
                  ),
                  Text(
                    '$pct% de ${Formatters.money(goal.targetAmount)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              if (goal.deadline != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event,
                        size: 14, color: Colors.grey.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      goal.isCompleted
                          ? 'Concluída'
                          : goal.daysLeft < 0
                              ? 'Prazo expirado'
                              : goal.daysLeft == 0
                                  ? 'Vence hoje'
                                  : '${goal.daysLeft} dia(s) restante(s)',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
