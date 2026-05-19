import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/material_model.dart';
import 'api_client.dart';

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

  // === REST API counterparts (via Express) ===

  /// GET /api/classes/:cid/materials (optional ?topicId= filter).
  static Future<List<Map<String, dynamic>>> listMaterialsApi(
    String classId, {
    String? topicId,
  }) async {
    final qs = (topicId == null || topicId.isEmpty)
        ? ''
        : '?topicId=${Uri.encodeQueryComponent(topicId)}';
    final data = await ApiClient.get('/classes/$classId/materials$qs')
        as Map<String, dynamic>;
    final raw = (data['materials'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  /// GET /api/classes/:cid/materials/:mid
  static Future<MaterialModel?> getMaterialApi(
      String classId, String materialId) async {
    try {
      final data = await ApiClient.get(
        '/classes/$classId/materials/$materialId',
      ) as Map<String, dynamic>;
      return MaterialModel(
        id: data['id'] ?? '',
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        topicId: data['topicId'] ?? '',
        topicTitle: data['topicTitle'] ?? '',
        createdAt: null,
        createdBy: data['createdBy'] ?? '',
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST /api/classes/:cid/materials
  static Future<String> createMaterialApi({
    required String classId,
    required String topicId,
    required String topicTitle,
    required String title,
    String description = '',
  }) async {
    final data = await ApiClient.post(
      '/classes/$classId/materials',
      {
        'title': title,
        'description': description,
        'topicId': topicId,
        'topicTitle': topicTitle,
      },
    ) as Map<String, dynamic>;
    return data['id'] as String;
  }

  /// PATCH /api/classes/:cid/materials/:mid
  static Future<void> updateMaterialApi({
    required String classId,
    required String materialId,
    required String title,
    String description = '',
  }) async {
    await ApiClient.patch(
      '/classes/$classId/materials/$materialId',
      {'title': title, 'description': description},
    );
  }

  /// DELETE /api/classes/:cid/materials/:mid
  static Future<void> deleteMaterialApi(
      String classId, String materialId) async {
    await ApiClient.delete('/classes/$classId/materials/$materialId');
  }
}
