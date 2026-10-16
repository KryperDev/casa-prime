import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount; // quanto já foi guardado
  final DateTime? deadline;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final String status; // 'active' | 'completed' | 'cancelled'
  final String icon;   // nome do ícone (Material)
  final String color;  // hexadecimal, ex: "#1E88E5"

  GoalModel({
    required this.id,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.status = 'active',
    this.icon = 'savings',
    this.color = '#1E88E5',
  });

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);

  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);

  int get daysLeft {
    if (deadline == null) return 0;
    return deadline!.difference(DateTime.now()).inDays;
  }

  bool get isCompleted => status == 'completed' || currentAmount >= targetAmount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status,
        'icon': icon,
        'color': color,
      };

  factory GoalModel.fromMap(Map<String, dynamic> m) => GoalModel(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        description: m['description'],
        targetAmount: (m['targetAmount'] ?? 0).toDouble(),
        currentAmount: (m['currentAmount'] ?? 0).toDouble(),
        deadline: (m['deadline'] as Timestamp?)?.toDate(),
        createdBy: m['createdBy'] ?? '',
        createdByName: m['createdByName'] ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: m['status'] ?? 'active',
        icon: m['icon'] ?? 'savings',
        color: m['color'] ?? '#1E88E5',
      );
}
