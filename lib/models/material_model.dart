import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MaterialModel {
  final String id;
  final String title;
  final String description;
  final String topicId;
  final String topicTitle;
  final Timestamp? createdAt;
  final String createdBy;

  MaterialModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.topicId,
    this.topicTitle = '',
    this.createdAt,
    this.createdBy = '',
  });

  String get formattedTime {
    if (createdAt == null) return '';
    final dt = createdAt!.toDate();
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  // Format tanggal upload — dipakai di classwork list supaya material lama
  // tetap kontekstual (sebelumnya cuma jam, gak ada info hari).
  String get formattedDate {
    if (createdAt == null) return '';
    return DateFormat('d MMM yyyy').format(createdAt!.toDate());
  }

  factory MaterialModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MaterialModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      topicId: data['topicId'] ?? '',
      topicTitle: data['topicTitle'] ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'topicId': topicId,
      'topicTitle': topicTitle,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }
}
