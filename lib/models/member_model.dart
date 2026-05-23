import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String uid;
  final String displayName;
  final String email;
  final String role;
  final Timestamp? joinedAt;
  final int xp;

  MemberModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    this.joinedAt,
    this.xp = 0,
  });

  bool get isTeacher => role == 'teacher';

  factory MemberModel.fromMap(Map<String, dynamic> data) {
    return MemberModel(
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      joinedAt: data['joinedAt'] as Timestamp?,
      xp: data['xp'] ?? 0,
    );
  }
}
