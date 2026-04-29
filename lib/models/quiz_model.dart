import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String title;
  final String topicId;
  final String topicTitle;
  final int timeLimit;
  final int passingGrade;
  final int attemptLimit;
  final bool showAnswer;
  final int questionCount;
  final Timestamp? createdAt;
  final String createdBy;

  QuizModel({
    required this.id,
    required this.title,
    required this.topicId,
    this.topicTitle = '',
    required this.timeLimit,
    required this.passingGrade,
    required this.attemptLimit,
    this.showAnswer = true,
    this.questionCount = 0,
    this.createdAt,
    this.createdBy = '',
  });

  factory QuizModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return QuizModel(
      id: doc.id,
      title: data['title'] ?? '',
      topicId: data['topicId'] ?? '',
      topicTitle: data['topicTitle'] ?? '',
      timeLimit: (data['timeLimit'] as num?)?.toInt() ?? 0,
      passingGrade: (data['passingGrade'] as num?)?.toInt() ?? 0,
      attemptLimit: (data['attemptLimit'] as num?)?.toInt() ?? 1,
      showAnswer: data['showAnswer'] ?? true,
      questionCount: (data['questionCount'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'topicId': topicId,
      'topicTitle': topicTitle,
      'timeLimit': timeLimit,
      'passingGrade': passingGrade,
      'attemptLimit': attemptLimit,
      'showAnswer': showAnswer,
      'questionCount': questionCount,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }
}
