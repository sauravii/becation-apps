import 'package:cloud_firestore/cloud_firestore.dart';

/// In-memory option. `isCorrect` is reconstructed by merging a question doc
/// (which only has option text) with its matching `answer_keys` doc — students
/// who read questions directly will always see `isCorrect: false`.
class QuestionOption {
  final String text;
  final bool isCorrect;

  const QuestionOption({required this.text, this.isCorrect = false});

  factory QuestionOption.fromMap(Map<String, dynamic> map) {
    return QuestionOption(
      text: map['text'] ?? '',
      isCorrect: false,
    );
  }
}

class QuestionModel {
  final String id;
  final String type;
  final String question;
  final List<QuestionOption> options;
  final int order;
  final Timestamp? createdAt;

  QuestionModel({
    required this.id,
    this.type = 'multiple_choice',
    required this.question,
    required this.options,
    required this.order,
    this.createdAt,
  });

  /// Index of the first option marked correct, or -1 if none.
  /// Only meaningful after merging with [AnswerKeyModel].
  int get correctIndex => options.indexWhere((o) => o.isCorrect);

  List<int> get correctIndices => [
        for (var i = 0; i < options.length; i++)
          if (options[i].isCorrect) i,
      ];

  /// Merge this question with its answer key. Used by teacher review/edit
  /// flows after fetching both `/questions` and `/answer_keys`.
  QuestionModel withAnswers(List<int> correctIndices) {
    return QuestionModel(
      id: id,
      type: type,
      question: question,
      order: order,
      createdAt: createdAt,
      options: [
        for (var i = 0; i < options.length; i++)
          QuestionOption(
            text: options[i].text,
            isCorrect: correctIndices.contains(i),
          ),
      ],
    );
  }

  factory QuestionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final rawOptions = (data['options'] as List?) ?? const [];
    return QuestionModel(
      id: doc.id,
      type: data['type'] ?? 'multiple_choice',
      question: data['question'] ?? '',
      options: rawOptions
          .whereType<Map>()
          .map((m) => QuestionOption.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      order: (data['order'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}

/// Stored under `quizzes/{quizId}/answer_keys/{questionId}` — same docId as
/// the question. Teacher-only read/write per Firestore rules.
class AnswerKeyModel {
  final String questionId;
  final List<int> correctIndices;

  const AnswerKeyModel({
    required this.questionId,
    required this.correctIndices,
  });

  factory AnswerKeyModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final raw = (data['correctIndices'] as List?) ?? const [];
    return AnswerKeyModel(
      questionId: doc.id,
      correctIndices: raw.whereType<num>().map((n) => n.toInt()).toList(),
    );
  }
}
