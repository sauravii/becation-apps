import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/material_model.dart';

class MaterialService {
  static final _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _materialsRef(
          String classId) =>
      _firestore.collection('classes').doc(classId).collection('materials');

  /// Buat material baru di kelas, terhubung ke topic tertentu.
  static Future<String> createMaterial({
    required String classId,
    required String topicId,
    required String topicTitle,
    required String title,
    String description = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User belum login');

    final doc = await _materialsRef(classId).add({
      'title': title,
      'description': description,
      'topicId': topicId,
      'topicTitle': topicTitle,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
    });

    debugPrint('[MaterialService] Material created: ${doc.id} in class $classId');
    return doc.id;
  }

  /// Stream semua material di kelas, opsional filter berdasarkan topicId.
  static Stream<List<MaterialModel>> materialsStream(
    String classId, {
    String? topicId,
  }) {
    Query<Map<String, dynamic>> query = _materialsRef(classId);
    if (topicId != null) {
      query = query.where('topicId', isEqualTo: topicId);
    }

    return query.orderBy('createdAt').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => MaterialModel.fromFirestore(doc))
            .toList());
  }

  /// Ambil satu material berdasarkan ID.
  static Future<MaterialModel?> getMaterial(
      String classId, String materialId) async {
    final doc = await _materialsRef(classId).doc(materialId).get();
    if (!doc.exists) return null;
    return MaterialModel.fromFirestore(doc);
  }

  /// Update judul dan deskripsi material.
  static Future<void> updateMaterial({
    required String classId,
    required String materialId,
    required String title,
    String description = '',
  }) async {
    await _materialsRef(classId).doc(materialId).update({
      'title': title,
      'description': description,
    });
    debugPrint('[MaterialService] Material updated: $materialId');
  }

  /// Hapus material.
  static Future<void> deleteMaterial(String classId, String materialId) async {
    await _materialsRef(classId).doc(materialId).delete();
    debugPrint('[MaterialService] Material deleted: $materialId');
  }
}
