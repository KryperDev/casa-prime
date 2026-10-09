import 'package:cloud_firestore/cloud_firestore.dart';

class InviteModel {
  final String id;
  final String token;
  final String familyId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool revoked;
  final int usageCount;

  InviteModel({
    required this.id,
    required this.token,
    required this.familyId,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
    this.revoked = false,
    this.usageCount = 0,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isActive => !revoked && !isExpired;

  Map<String, dynamic> toMap() => {
        'id': id,
        'token': token,
        'familyId': familyId,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'revoked': revoked,
        'usageCount': usageCount,
      };

  factory InviteModel.fromMap(String id, Map<String, dynamic> map) => InviteModel(
        id: id,
        token: map['token'] ?? '',
        familyId: map['familyId'] ?? '',
        createdBy: map['createdBy'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
        revoked: map['revoked'] ?? false,
        usageCount: map['usageCount'] ?? 0,
      );
}
