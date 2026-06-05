import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/class_model.dart';
import 'api_client.dart';

class ClassService {
  static final _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _classesRef =>
      _firestore.collection('classes');
  static CollectionReference<Map<String, dynamic>> get _classCodesRef =>
      _firestore.collection('class_codes');

  /// Buat kelas baru.
  static Future<String> createClass({
    required String title,
    required String subject,
    required String description,
    required int colorValue,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User belum login');

    final classCode = await _generateUniqueClassCode();
    final teacherName = user.displayName ?? '';

    final classRef = _classesRef.doc();
    final classId = classRef.id;
    final memberRef = classRef.collection('members').doc(user.uid);
    final codeRef = _classCodesRef.doc(classCode);

    final batch = _firestore.batch();
    batch.set(classRef, {
      'title': title,
      'subject': subject,
      'description': description,
      'colorValue': colorValue,
      'classCode': classCode,
      'teacherId': user.uid,
      'teacherName': teacherName,
      'studentCount': 0,
      'memberIds': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(memberRef, {
      'role': 'teacher',
      'displayName': teacherName,
      'email': user.email ?? '',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(codeRef, {'classId': classId});

    await batch.commit();

    debugPrint('[ClassService] Class created: $classId (code: $classCode)');
    return classId;
  }

  // Buat generate class code unik (6 karakter alphanumeric). Kalau udah ada -> Generate ulang
  static Future<String> _generateUniqueClassCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();

    while (true) {
      final code = List.generate(
        6,
        (_) => chars[random.nextInt(chars.length)],
      ).join();

      final existing = await _classCodesRef.doc(code).get();
      if (!existing.exists) return code;
    }
  }

  /// Stream semua kelas milik teacher (realtime, live count).
  static Stream<List<ClassModel>> teacherClassesStream(String teacherId) {
    return _classesRef
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromFirestore(doc))
            .toList());
  }

  /// Count total materials yang dibuat teacher di semua class-nya.
  static Future<int> teacherMaterialsCount(String teacherId) async {
    final classesSnap = await _classesRef
        .where('teacherId', isEqualTo: teacherId)
        .get();
    final counts = await Future.wait(classesSnap.docs.map((classDoc) async {
      final agg = await _firestore
          .collection('classes/${classDoc.id}/materials')
          .count()
          .get();
      return agg.count ?? 0;
    }));
    return counts.fold<int>(0, (a, b) => a + b);
  }

  /// Stream semua kelas milik student (realtime, live count).
  static Stream<List<ClassModel>> studentClassesStream(String studentId) {
    return _classesRef
        .where('memberIds', arrayContains: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['teacherId'] != studentId)
            .map((doc) => ClassModel.fromFirestore(doc))
            .toList());
  }

  static Future<ClassModel?> getClass(String classId) async {
    final doc = await _classesRef.doc(classId).get();
    if (!doc.exists) return null;
    return ClassModel.fromFirestore(doc);
  }

  static Stream<ClassModel?> classStream(String classId) {
    return _classesRef.doc(classId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ClassModel.fromFirestore(doc);
    });
  }

  /// Student join kelas menggunakan class code.
  /// Dioptimasi: read class code → parallel check member + get class → batch write.
  static Future<void> joinClassByCode({required String classCode}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User belum login');

    final codeDoc = await _classCodesRef.doc(classCode.toUpperCase()).get();
    if (!codeDoc.exists) {
      throw Exception('Class code not found');
    }

    final classId = codeDoc.data()!['classId'] as String;
    final classRef = _classesRef.doc(classId);

    // Cek membership secara parallel — lebih cepat daripada sequential.
    final memberDoc =
        await classRef.collection('members').doc(user.uid).get();
    if (memberDoc.exists) {
      throw Exception('You are already a member of this class');
    }

    final displayName = user.displayName ?? '';
    final memberRef = classRef.collection('members').doc(user.uid);

    final batch = _firestore.batch();
    batch.set(memberRef, {
      'role': 'student',
      'displayName': displayName,
      'email': user.email ?? '',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.update(classRef, {
      'studentCount': FieldValue.increment(1),
      'memberIds': FieldValue.arrayUnion([user.uid]),
    });

    await batch.commit();

    debugPrint('[ClassService] Student joined class: $classId');
  }

  /// Student leave kelas.
  static Future<void> leaveClass(String classId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User belum login');

    final classRef = _classesRef.doc(classId);
    final memberRef = classRef.collection('members').doc(user.uid);

    final batch = _firestore.batch();
    batch.delete(memberRef);
    batch.update(classRef, {
      'studentCount': FieldValue.increment(-1),
      'memberIds': FieldValue.arrayRemove([user.uid]),
    });

    await batch.commit();

    debugPrint('[ClassService] Student left class: $classId');
  }

  /// Update info kelas (judul, subject, deskripsi).
  static Future<void> updateClass({
    required String classId,
    required String title,
    required String subject,
    required String description,
  }) async {
    await _classesRef.doc(classId).update({
      'title': title,
      'subject': subject,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[ClassService] Class updated: $classId');
  }

  /// Hapus kelas beserta semua isinya (topics, materials, attachments, members, class code).
  static Future<void> deleteClassWithContents(String classId) async {
    final classRef = _classesRef.doc(classId);
    final classDoc = await classRef.get();
    if (!classDoc.exists) throw Exception('Class not found');

    final classCode = classDoc.data()?['classCode'] as String?;

    // Hapus semua members.
    final members = await classRef.collection('members').get();
    // Hapus semua materials beserta attachments-nya.
    final materials = await classRef.collection('materials').get();
    // Hapus semua topics.
    final topics = await classRef.collection('topics').get();

    final batch = _firestore.batch();

    for (final doc in members.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in materials.docs) {
      // Hapus attachments di setiap material.
      final attachments = await doc.reference.collection('attachments').get();
      for (final att in attachments.docs) {
        batch.delete(att.reference);
      }
      batch.delete(doc.reference);
    }
    for (final doc in topics.docs) {
      batch.delete(doc.reference);
    }

    // Hapus class code dari collection class_codes.
    if (classCode != null) {
      batch.delete(_classCodesRef.doc(classCode));
    }

    // Hapus kelas itu sendiri.
    batch.delete(classRef);

    await batch.commit();
    debugPrint('[ClassService] Class deleted with all contents: $classId');
  }

  /// Remove satu atau lebih student dari kelas.
  static Future<void> removeStudents(
      String classId, List<String> studentUids) async {
    final classRef = _classesRef.doc(classId);
    final batch = _firestore.batch();

    for (final uid in studentUids) {
      batch.delete(classRef.collection('members').doc(uid));
    }

    batch.update(classRef, {
      'studentCount': FieldValue.increment(-studentUids.length),
      'memberIds': FieldValue.arrayRemove(studentUids),
    });

    await batch.commit();
    debugPrint(
        '[ClassService] Removed ${studentUids.length} student(s) from class: $classId');
  }

  /// Stream members di kelas (untuk People tab).
  static Stream<List<Map<String, dynamic>>> classMembersStream(
      String classId) {
    return _classesRef
        .doc(classId)
        .collection('members')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['uid'] = doc.id;
              return data;
            }).toList());
  }

  // === REST API counterparts (Class CRUD via Express) ===

  /// GET /api/classes/teaching — kelas current user sebagai teacher.
  static Future<List<Map<String, dynamic>>> listTeachingClassesApi() async {
    final data =
        await ApiClient.get('/classes/teaching') as Map<String, dynamic>;
    final raw = (data['classes'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  /// GET /api/classes/enrolled — kelas current user sebagai student.
  static Future<List<Map<String, dynamic>>> listEnrolledClassesApi() async {
    final data =
        await ApiClient.get('/classes/enrolled') as Map<String, dynamic>;
    final raw = (data['classes'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  /// GET /api/classes/:cid — detail kelas.
  static Future<Map<String, dynamic>?> getClassApi(String classId) async {
    try {
      return await ApiClient.get('/classes/$classId') as Map<String, dynamic>;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST /api/classes — create kelas + member (teacher) + class_code atomic.
  /// Return class id.
  static Future<String> createClassApi({
    required String title,
    required String subject,
    required String description,
    required int colorValue,
  }) async {
    final data = await ApiClient.post('/classes', {
      'title': title,
      'subject': subject,
      'description': description,
      'colorValue': colorValue,
    }) as Map<String, dynamic>;
    return data['id'] as String;
  }

  /// PATCH /api/classes/:cid — update kelas (title/subject/description).
  static Future<void> updateClassApi({
    required String classId,
    required String title,
    required String subject,
    required String description,
  }) async {
    await ApiClient.patch('/classes/$classId', {
      'title': title,
      'subject': subject,
      'description': description,
    });
  }

  /// DELETE /api/classes/:cid — cascade delete kelas + members + topics +
  /// materials + attachments + quizzes + subcollections + class_code.
  static Future<void> deleteClassWithContentsApi(String classId) async {
    await ApiClient.delete('/classes/$classId');
  }

  // === Membership endpoints via Express ===

  /// POST /api/memberships/join — student join class by code.
  /// Return class id.
  static Future<String> joinClassByCodeApi({required String classCode}) async {
    final data = await ApiClient.post('/memberships/join', {
      'classCode': classCode,
    }) as Map<String, dynamic>;
    return data['classId'] as String;
  }

  /// DELETE /api/classes/:cid/members/me — leave class (self).
  static Future<void> leaveClassApi(String classId) async {
    await ApiClient.delete('/classes/$classId/members/me');
  }

  /// GET /api/classes/:cid/members — list members.
  static Future<List<Map<String, dynamic>>> listClassMembersApi(
      String classId) async {
    final data = await ApiClient.get('/classes/$classId/members')
        as Map<String, dynamic>;
    final raw = (data['members'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  /// POST /api/classes/:cid/members/remove — teacher bulk-remove students.
  static Future<void> removeStudentsApi(
      String classId, List<String> studentUids) async {
    await ApiClient.post('/classes/$classId/members/remove', {
      'uids': studentUids,
    });
  }
}
