import 'package:cloud_firestore/cloud_firestore.dart';

class TopicModel {
  final String id;
  final String title;
  final int order;
  final Timestamp? createdAt;
  final String createdBy;

  TopicModel({
    required this.id,
    required this.title,
    required this.order,
    this.createdAt,
    this.createdBy = '',
  });

  factory TopicModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TopicModel(
      id: doc.id,
      title: data['title'] ?? '',
      order: data['order'] ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'order': order,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }
}
