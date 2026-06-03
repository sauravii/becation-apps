import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

// Service untuk CRUD data user di Firestore collection 'users'.
// CRUD-style read/write sudah punya REST counterpart via Express (suffix `Api`);
// stream + auth-flow helpers tetap pakai Firestore SDK langsung.
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
        'photoUrl': '',
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

  // Ekstrak displayName ter-trim dari snapshot users/{uid}. Return null kalau
  // kosong — biar parsing field Firestore gak bocor ke UI (dashboard greeting).
  static String? displayNameFromDoc(
    DocumentSnapshot<Map<String, dynamic>>? doc,
  ) {
    final name = (doc?.data()?['displayName'] as String?)?.trim();
    return (name != null && name.isNotEmpty) ? name : null;
  }

  static const allowedRoles = {'student', 'teacher'};

  // Update displayName di Firestore + Firebase Auth.
  // Dipanggil dari profile edit page. Trim + non-empty validation di sini.
  static Future<void> updateDisplayName(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }
    await _usersRef.doc(user.uid).update({'displayName': trimmed});
    try {
      await user.updateDisplayName(trimmed);
    } catch (e, st) {
      debugPrint(
        '[UserService] Failed to update FirebaseAuth.displayName: $e\n$st',
      );
    }
  }

  // Count materials yang sudah complete (completedAt != null) di
  // users/{uid}/material_completion subcollection. Dipakai di profile Statistics.
  static Future<int> materialsCompletedCount(String uid) async {
    final agg = await _usersRef
        .doc(uid)
        .collection('material_completion')
        .where('completedAt', isNull: false)
        .count()
        .get();
    return agg.count ?? 0;
  }

  // Upload foto profile ke Storage di path users/{uid}/profile.jpg (fixed ext
   // supaya format apapun selalu overwrite ke 1 file — gak akumulasi profile.png
   // + profile.jpg dst di Storage). Cropper sudah convert ke JPG.
  // Update photoUrl di Firestore + FirebaseAuth. Return download URL.
  // Max size 5MB di-enforce di storage.rules.
  static Future<String> uploadProfilePhoto(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }

    final storagePath = 'users/${user.uid}/profile.jpg';
    final ref = FirebaseStorage.instance.ref(storagePath);

    debugPrint('[UserService] Uploading profile photo: $storagePath');

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final downloadUrl = await task.ref.getDownloadURL();

    await _usersRef.doc(user.uid).update({'photoUrl': downloadUrl});
    try {
      await user.updatePhotoURL(downloadUrl);
    } catch (e, st) {
      debugPrint('[UserService] Failed to update FirebaseAuth.photoURL: $e\n$st');
    }

    return downloadUrl;
  }

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

  // === REST API counterparts (via Express) ===

  // GET /api/users/me — profile user yang lagi login.
  static Future<Map<String, dynamic>> getMeApi() async {
    final data = await ApiClient.get('/users/me') as Map<String, dynamic>;
    return data;
  }

  // GET /api/users/:uid — profile user spesifik.
  static Future<Map<String, dynamic>> getUserApi(String uid) async {
    final data = await ApiClient.get('/users/$uid') as Map<String, dynamic>;
    return data;
  }

  // GET /api/users — list user (optional ?email= exact filter).
  static Future<List<Map<String, dynamic>>> listUsersApi({String? email}) async {
    final qs = (email == null || email.isEmpty)
        ? ''
        : '?email=${Uri.encodeQueryComponent(email)}';
    final data = await ApiClient.get('/users$qs') as Map<String, dynamic>;
    final raw = (data['users'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  // PATCH /api/users/:uid/role — update role via Express.
  static Future<Map<String, dynamic>> updateUserRoleApi(
      String uid, String role) async {
    final data = await ApiClient.patch(
      '/users/$uid/role',
      {'role': role},
    ) as Map<String, dynamic>;
    return data;
  }
}
