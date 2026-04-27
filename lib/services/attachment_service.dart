import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/attachment_model.dart';

class AttachmentService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static CollectionReference<Map<String, dynamic>> _attachmentsRef(
    String classId,
    String materialId,
  ) =>
      _firestore
          .collection('classes')
          .doc(classId)
          .collection('materials')
          .doc(materialId)
          .collection('attachments');

  /// Upload file ke Firebase Storage lalu simpan metadata ke Firestore.
  /// Return attachment ID.
  static Future<String> uploadFileAttachment({
    required String classId,
    required String materialId,
    required String title,
    required String type,
    required File file,
    required String fileName,
  }) async {
    // Path di Storage: classes/{classId}/materials/{materialId}/{timestamp}_{fileName}
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath =
        'classes/$classId/materials/$materialId/${timestamp}_$fileName';
    final ref = _storage.ref(storagePath);

    debugPrint('[AttachmentService] Uploading file: $storagePath');

    // Upload file.
    final uploadTask = await ref.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Hitung ukuran file yang readable.
    final fileSize = _formatFileSize(file.lengthSync());

    // Ambil extension file (misal "pdf", "pptx", "docx").
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    // Simpan metadata ke Firestore.
    final doc = await _attachmentsRef(classId, materialId).add({
      'title': title,
      'type': type,
      'url': downloadUrl,
      'fileSize': fileSize,
      'fileExtension': ext,
      'storagePath': storagePath,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[AttachmentService] File uploaded & attachment added: ${doc.id}');
    return doc.id;
  }

  /// Tambah attachment berupa link (tanpa upload file).
  static Future<String> addAttachment({
    required String classId,
    required String materialId,
    required String title,
    required String type,
    required String url,
    String fileSize = '',
    String? storagePath,
  }) async {
    final doc = await _attachmentsRef(classId, materialId).add({
      'title': title,
      'type': type,
      'url': url,
      'fileSize': fileSize,
      if (storagePath != null) 'storagePath': storagePath,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[AttachmentService] Attachment added: ${doc.id}');
    return doc.id;
  }

  /// Stream semua attachments di material.
  static Stream<List<AttachmentModel>> attachmentsStream(
    String classId,
    String materialId,
  ) {
    return _attachmentsRef(classId, materialId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttachmentModel.fromFirestore(doc))
            .toList());
  }

  /// Update judul attachment.
  static Future<void> updateAttachmentTitle(
    String classId,
    String materialId,
    String attachmentId,
    String newTitle,
  ) async {
    await _attachmentsRef(classId, materialId).doc(attachmentId).update({
      'title': newTitle,
    });
    debugPrint('[AttachmentService] Attachment title updated: $attachmentId');
  }

  /// Hapus attachment. Kalau ada file di Storage, hapus juga.
  static Future<void> deleteAttachment(
    String classId,
    String materialId,
    String attachmentId,
  ) async {
    // Cek apakah ada file di Storage yang perlu dihapus.
    final doc =
        await _attachmentsRef(classId, materialId).doc(attachmentId).get();
    final storagePath = doc.data()?['storagePath'] as String?;

    if (storagePath != null && storagePath.isNotEmpty) {
      try {
        await _storage.ref(storagePath).delete();
        debugPrint('[AttachmentService] Storage file deleted: $storagePath');
      } catch (e) {
        debugPrint('[AttachmentService] Failed to delete storage file: $e');
      }
    }

    await _attachmentsRef(classId, materialId).doc(attachmentId).delete();
    debugPrint('[AttachmentService] Attachment deleted: $attachmentId');
  }

  /// Format ukuran file ke string yang readable (KB, MB).
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
