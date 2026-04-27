import 'package:cloud_firestore/cloud_firestore.dart';

class AttachmentModel {
  final String id;
  final String title;
  final String type; // "pdf", "presentation", "link", "doc", "image"
  final String url;
  final String fileSize;
  final String fileExtension;
  final String? storagePath;
  final Timestamp? createdAt;

  AttachmentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
    this.fileSize = '',
    this.fileExtension = '',
    this.storagePath,
    this.createdAt,
  });

  /// Subtitle formatted: "PDF • 2.5 MB" untuk file, "Web Link" untuk link.
  String get formattedSubtitle {
    if (type == 'link') return fileSize.isNotEmpty ? fileSize : 'Web Link';
    final ext = fileExtension.isNotEmpty ? fileExtension.toUpperCase() : '';
    final size = fileSize.isNotEmpty ? fileSize : '';
    if (ext.isNotEmpty && size.isNotEmpty) return '$ext • $size';
    if (ext.isNotEmpty) return ext;
    if (size.isNotEmpty) return size;
    return type;
  }

  factory AttachmentModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AttachmentModel(
      id: doc.id,
      title: data['title'] ?? '',
      type: data['type'] ?? 'link',
      url: data['url'] ?? '',
      fileSize: data['fileSize'] ?? '',
      fileExtension: data['fileExtension'] ?? '',
      storagePath: data['storagePath'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'url': url,
      'fileSize': fileSize,
      if (storagePath != null) 'storagePath': storagePath,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
