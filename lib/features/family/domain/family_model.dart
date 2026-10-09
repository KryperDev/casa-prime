import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  final String id;
  final String name;
  final String adminId;
  final String? photoUrl;
  final List<String> memberIds;
  final DateTime createdAt;

  FamilyModel({
    required this.id,
    required this.name,
    required this.adminId,
    this.photoUrl,
    required this.memberIds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'adminId': adminId,
        'photoUrl': photoUrl,
        'memberIds': memberIds,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory FamilyModel.fromMap(Map<String, dynamic> map) => FamilyModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        adminId: map['adminId'] ?? '',
        photoUrl: map['photoUrl'],
        memberIds: List<String>.from(map['memberIds'] ?? []),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
