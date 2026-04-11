import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Service untuk CRUD data user di Firestore collection 'users'.
class UserService {
  static final _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  // Buat user doc baru (role default: student) atau update lastLogin kalau sudah ada.
  // [displayName] opsional — dipakai saat register email/password untuk menyimpan
  // nama yang diisi user. Kalau null, ambil dari user.displayName (Google Sign-In).
  // Throws on failure — callers harus handle error sendiri.
  static Future<void> ensureUserDocument(
    User user, {
    String? displayName,
  }) async {
    debugPrint(
      '[UserService] ensureUserDocument called for ${user.email} (${user.uid})',
    );
    final name = displayName ?? user.displayName ?? '';
    final doc = _usersRef.doc(user.uid);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      debugPrint('[UserService] Doc not found, creating new user doc...');
      await doc.set({
        'email': user.email,
        'displayName': name,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
      debugPrint('[UserService] User doc created!');
    } else {
      debugPrint('[UserService] Doc exists, updating lastLogin...');
      await doc.update({
        'lastLogin': FieldValue.serverTimestamp(),
        if (name.isNotEmpty) 'displayName': name,
      });
      debugPrint('[UserService] lastLogin updated!');
    }

    // Sinkronkan juga displayName di FirebaseAuth user supaya greeting bisa langsung
    // pakai nama ini tanpa perlu nunggu Firestore.
    if (name.isNotEmpty && user.displayName != name) {
      try {
        await user.updateDisplayName(name);
      } catch (e, st) {
        debugPrint(
          '[UserService] Failed to update FirebaseAuth.displayName: $e\n$st',
        );
      }
    }
  }

  // Sinkronkan displayName di FirebaseAuth dari Firestore kalau belum terisi.
  // Dipanggil misalnya saat splash / auto-login supaya dashboard langsung pakai nama.
  static Future<void> syncAuthDisplayNameFromFirestore(User user) async {
    try {
      final snapshot = await _usersRef.doc(user.uid).get();
      final data = snapshot.data();

      if (data == null) return;

      final firestoreName = (data['displayName'] as String?)?.trim();

      if (firestoreName != null &&
          firestoreName.isNotEmpty &&
          user.displayName != firestoreName) {
        await user.updateDisplayName(firestoreName);
      }
    } catch (e, st) {
      debugPrint(
        '[UserService] Failed to sync auth displayName from Firestore: $e\n$st',
      );
    }
  }

  // Cek apakah user sudah terdaftar di Firestore (punya doc di collection 'users').
  static Future<bool> isUserRegistered(String uid) async {
    final snapshot = await _usersRef.doc(uid).get();
    return snapshot.exists;
  }

  // Ambil role user (return 'student' kalau doc belum ada).
  static Future<String> getUserRole(String uid) async {
    final snapshot = await _usersRef.doc(uid).get();
    return snapshot.data()?['role'] ?? 'student';
  }

  // Stream realtime data user (auto update kalau ada perubahan di Firestore).
  static Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _usersRef.doc(uid).snapshots();
  }

  static const allowedRoles = {'student', 'teacher'};

  // Update role user (misal: student -> teacher).
  static Future<void> updateUserRole(String uid, String role) async {
    if (!allowedRoles.contains(role)) {
      throw ArgumentError('Invalid role "$role". Allowed: $allowedRoles');
    }
    await _usersRef.doc(uid).update({'role': role});
  }

  // Cari user berdasarkan email (exact match, untuk manage role).
  static Future<List<Map<String, dynamic>>> searchUsersByEmail(
    String email,
  ) async {
    final snapshot = await _usersRef
        .where('email', isEqualTo: email.trim())
        .get();
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
