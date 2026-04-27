import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/topic_model.dart';

class TopicService {
  static final _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _topicsRef(String classId) =>
      _firestore.collection('classes').doc(classId).collection('topics');

  /// Buat topic baru di kelas.
  static Future<String> createTopic({
    required String classId,
    required String title,
    required int order,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User belum login');

    final doc = await _topicsRef(classId).add({
      'title': title,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
    });

    debugPrint('[TopicService] Topic created: ${doc.id} in class $classId');
    return doc.id;
  }

  /// Stream semua topic di kelas, diurutkan berdasarkan order.
  static Stream<List<TopicModel>> topicsStream(String classId) {
    return _topicsRef(classId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TopicModel.fromFirestore(doc))
            .toList());
  }

  /// Hitung jumlah topic yang ada (untuk auto-increment order).
  static Future<int> getTopicCount(String classId) async {
    final snapshot = await _topicsRef(classId).get();
    return snapshot.docs.length;
  }

  /// Hapus topic beserta semua material yang ada di dalamnya.
  static Future<void> deleteTopicWithMaterials(
      String classId, String topicId) async {
    final materialsSnapshot = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('materials')
        .where('topicId', isEqualTo: topicId)
        .get();

    final batch = _firestore.batch();

    // Hapus semua material yang terhubung ke topic ini.
    for (final doc in materialsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Hapus topic itu sendiri.
    batch.delete(_topicsRef(classId).doc(topicId));

    await batch.commit();
    debugPrint(
      '[TopicService] Topic deleted: $topicId (${materialsSnapshot.docs.length} materials removed)',
    );
  }

  /// Hapus topic saja (tanpa material).
  static Future<void> deleteTopic(String classId, String topicId) async {
    await _topicsRef(classId).doc(topicId).delete();
    debugPrint('[TopicService] Topic deleted: $topicId');
  }

  /// Update judul topic.
  static Future<void> updateTopicTitle(
      String classId, String topicId, String newTitle) async {
    await _topicsRef(classId).doc(topicId).update({'title': newTitle});
    debugPrint('[TopicService] Topic title updated: $topicId');
  }
}
