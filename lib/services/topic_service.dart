import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/topic_model.dart';
import 'api_client.dart';

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

  /// Hapus topic beserta semua material & quiz (termasuk subcollections-nya:
  /// questions, answer_keys, attempts) yang ada di dalamnya.
  ///
  /// Catatan skala: Firestore batch limit 500 ops. Kalau topic punya banyak
  /// quiz dengan banyak attempts, pecah jadi multi-batch (TODO kalau perlu).
  static Future<void> deleteTopicWithContent(
      String classId, String topicId) async {
    final classRef = _firestore.collection('classes').doc(classId);

    // 1. Find all materials and quizzes with this topicId.
    final materialsSnap = await classRef
        .collection('materials')
        .where('topicId', isEqualTo: topicId)
        .get();
    final quizzesSnap = await classRef
        .collection('quizzes')
        .where('topicId', isEqualTo: topicId)
        .get();

    final batch = _firestore.batch();

    // 2. Materials (note: their attachment subcollections become orphan —
    // pre-existing behavior, separate issue).
    for (final doc in materialsSnap.docs) {
      batch.delete(doc.reference);
    }

    // 3. Quizzes — read each quiz's subcollections and queue all for deletion.
    var totalQuestions = 0;
    var totalKeys = 0;
    var totalAttempts = 0;
    for (final quizDoc in quizzesSnap.docs) {
      final quizRef = quizDoc.reference;
      final qs = await quizRef.collection('questions').get();
      final ks = await quizRef.collection('answer_keys').get();
      final ats = await quizRef.collection('attempts').get();
      for (final d in qs.docs) {
        batch.delete(d.reference);
      }
      for (final d in ks.docs) {
        batch.delete(d.reference);
      }
      for (final d in ats.docs) {
        batch.delete(d.reference);
      }
      batch.delete(quizRef);
      totalQuestions += qs.size;
      totalKeys += ks.size;
      totalAttempts += ats.size;
    }

    // 4. Topic itself.
    batch.delete(_topicsRef(classId).doc(topicId));

    await batch.commit();
    debugPrint(
      '[TopicService] Topic deleted: $topicId — '
      '${materialsSnap.size} materials, '
      '${quizzesSnap.size} quizzes '
      '(questions: $totalQuestions, keys: $totalKeys, attempts: $totalAttempts)',
    );
  }

  /// Backward-compat alias. Prefer [deleteTopicWithContent].
  @Deprecated('Use deleteTopicWithContent — also deletes quizzes')
  static Future<void> deleteTopicWithMaterials(
      String classId, String topicId) =>
      deleteTopicWithContent(classId, topicId);

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

  // === REST API counterparts (via Express) ===

  /// GET /api/classes/:cid/topics — list topic via REST.
  static Future<List<Map<String, dynamic>>> listTopicsApi(String classId) async {
    final data =
        await ApiClient.get('/classes/$classId/topics') as Map<String, dynamic>;
    final raw = (data['topics'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  /// POST /api/classes/:cid/topics — create topic via REST.
  /// Server hitung `order` otomatis (gak perlu pass dari client).
  /// Return topic id baru.
  static Future<String> createTopicApi({
    required String classId,
    required String title,
  }) async {
    final data = await ApiClient.post(
      '/classes/$classId/topics',
      {'title': title},
    ) as Map<String, dynamic>;
    return data['id'] as String;
  }

  /// PATCH /api/classes/:cid/topics/:tid — update judul via REST.
  static Future<void> updateTopicTitleApi(
      String classId, String topicId, String newTitle) async {
    await ApiClient.patch(
      '/classes/$classId/topics/$topicId',
      {'title': newTitle},
    );
  }

  /// DELETE /api/classes/:cid/topics/:tid — cascade delete via REST.
  static Future<void> deleteTopicWithContentApi(
      String classId, String topicId) async {
    await ApiClient.delete('/classes/$classId/topics/$topicId');
  }
}
