import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Service untuk CRUD data user di Firestore collection 'users'.
class UserService {
  static final _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  // Buat user doc baru (role default: student) atau update lastLogin kalau sudah ada.
  static Future<void> ensureUserDocument(User user) async {
    try {
      debugPrint('[UserService] ensureUserDocument called for ${user.email} (${user.uid})');
      final doc = _usersRef.doc(user.uid);
      final snapshot = await doc.get();

      if (!snapshot.exists) {
        debugPrint('[UserService] Doc not found, creating new user doc...');
        await doc.set({
          'email': user.email,
          'displayName': user.displayName ?? '',
          'role': 'student',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
        debugPrint('[UserService] User doc created!');
      } else {
        debugPrint('[UserService] Doc exists, updating lastLogin...');
        await doc.update({
          'lastLogin': FieldValue.serverTimestamp(),
          if (user.displayName != null) 'displayName': user.displayName,
        });
        debugPrint('[UserService] lastLogin updated!');
      }
    } catch (e) {
      debugPrint('[UserService] ERROR: $e');
    }
  }

  // Ambil role user (return 'student' kalau doc belum ada).
  static Future<String> getUserRole(String uid) async {
    final snapshot = await _usersRef.doc(uid).get();
    return snapshot.data()?['role'] ?? 'student';
  }

  // Stream realtime data user (auto update kalau ada perubahan di Firestore).
  static Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(
    String uid,
  ) {
    return _usersRef.doc(uid).snapshots();
  }

  // Update role user (misal: student -> teacher).
  static Future<void> updateUserRole(String uid, String role) async {
    await _usersRef.doc(uid).update({'role': role});
  }

  // Cari user berdasarkan email (exact match, untuk manage role).
  static Future<List<Map<String, dynamic>>> searchUsersByEmail(
    String email,
  ) async {
    final snapshot =
        await _usersRef.where('email', isEqualTo: email.trim()).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id;
      return data;
    }).toList();
  }

  // Ambil semua user, diurutkan berdasarkan email.
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _usersRef.orderBy('email').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id;
      return data;
    }).toList();
  }
}
