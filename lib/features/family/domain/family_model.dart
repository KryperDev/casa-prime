import 'package:cloud_firestore/cloud_firestore.dart';

enum PlanType { free, family, plus }

extension PlanTypeX on PlanType {
  String get key {
    switch (this) {
      case PlanType.free:
        return 'free';
      case PlanType.family:
        return 'family';
      case PlanType.plus:
        return 'plus';
    }
  }

  String get label {
    switch (this) {
      case PlanType.free:
        return 'Grátis';
      case PlanType.family:
        return 'Família';
      case PlanType.plus:
        return 'Família Plus';
    }
  }

  static PlanType fromKey(String? key) {
    switch (key) {
      case 'family':
        return PlanType.family;
      case 'plus':
        return PlanType.plus;
      case 'free':
      default:
        return PlanType.free;
    }
  }
}

class FamilyModel {
  final String id;
  final String name;
  final String adminId;
  final String? photoUrl;
  final List<String> memberIds;
  final DateTime createdAt;
  final PlanType planType;

  FamilyModel({
    required this.id,
    required this.name,
    required this.adminId,
    this.photoUrl,
    required this.memberIds,
    required this.createdAt,
    this.planType = PlanType.free,
  });

  bool get canEditCategories => planType != PlanType.free;
  bool get canUseCoupleMode => planType == PlanType.plus;
  bool get canUseEmailReport => planType == PlanType.plus;

  int get maxMembers {
    switch (planType) {
      case PlanType.free:
        return 2;
      case PlanType.family:
        return 5;
      case PlanType.plus:
        return 10;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'adminId': adminId,
        'photoUrl': photoUrl,
        'memberIds': memberIds,
        'createdAt': Timestamp.fromDate(createdAt),
        'planType': planType.key,
      };

  factory FamilyModel.fromMap(Map<String, dynamic> map) => FamilyModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        adminId: map['adminId'] ?? '',
        photoUrl: map['photoUrl'],
        memberIds: List<String>.from(map['memberIds'] ?? []),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        planType: PlanTypeX.fromKey(map['planType'] as String?),
      );
}
