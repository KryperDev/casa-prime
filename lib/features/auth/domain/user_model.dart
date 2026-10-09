import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String? photoUrl;
  final String? familyId;
  final String role;
  final String? relationship;
  final String? customRelationship;
  final DateTime createdAt;
  final String status;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
    this.photoUrl,
    this.familyId,
    this.role = 'member',
    this.relationship,
    this.customRelationship,
    required this.createdAt,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'username': username,
        'photoUrl': photoUrl,
        'familyId': familyId,
        'role': role,
        'relationship': relationship,
        'customRelationship': customRelationship,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] ?? '',
        email: map['email'] ?? '',
        displayName: map['displayName'] ?? '',
        username: map['username'] ?? '',
        photoUrl: map['photoUrl'],
        familyId: map['familyId'],
        role: map['role'] ?? 'member',
        relationship: map['relationship'],
        customRelationship: map['customRelationship'],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: map['status'] ?? 'active',
      );

  UserModel copyWith({
    String? displayName,
    String? username,
    String? photoUrl,
    String? familyId,
    String? role,
    String? relationship,
    String? customRelationship,
    String? status,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        username: username ?? this.username,
        photoUrl: photoUrl ?? this.photoUrl,
        familyId: familyId ?? this.familyId,
        role: role ?? this.role,
        relationship: relationship ?? this.relationship,
        customRelationship: customRelationship ?? this.customRelationship,
        createdAt: createdAt,
        status: status ?? this.status,
      );
}
