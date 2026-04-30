import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/question_model.dart';
import '../models/quiz_model.dart';

class QuizDraftQuestion {
  final String type;
  final String question;
  final List<QuestionOption> options;

  const QuizDraftQuestion({
    this.type = 'multiple_choice',
    required this.question,
    required this.options,
  });
}

class QuizService {
  static final _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _quizzesRef(
          String classId) =>
      _firestore.collection('classes').doc(classId).collection('quizzes');

  static CollectionReference<Map<String, dynamic>> _questionsRef(
          String classId, String quizId) =>
      _quizzesRef(classId).doc(quizId).collection('questions');

  /// Create quiz + all questions atomically in a single batch.
  /// Returns the new quiz ID.
  static Future<String> createQuiz({
    required String classId,
    required String title,
    required String topicId,
    String topicTitle = '',
    required int timeLimit,
    required int passingGrade,
    required int attemptLimit,
    required bool showAnswer,
    required List<QuizDraftQuestion> questions,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User belum login');

    final batch = _firestore.batch();
    final quizRef = _quizzesRef(classId).doc();

    batch.set(quizRef, {
      'title': title,
      'topicId': topicId,
      'topicTitle': topicTitle,
      'timeLimit': timeLimit,
      'passingGrade': passingGrade,
      'attemptLimit': attemptLimit,
      'showAnswer': showAnswer,
      'questionCount': questions.length,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
    });

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final qRef = quizRef.collection('questions').doc();
      // Question doc — strip `isCorrect` to keep answers off the student-readable path.
      batch.set(qRef, {
        'type': q.type,
        'question': q.question,
        'options': q.options.map((o) => {'text': o.text}).toList(),
        'order': i,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Answer key doc — same docId as question, separately gated to teachers only.
      final correctIndices = [
        for (var j = 0; j < q.options.length; j++)
          if (q.options[j].isCorrect) j,
      ];
      final akRef = quizRef.collection('answer_keys').doc(qRef.id);
      batch.set(akRef, {
        'correctIndices': correctIndices,
      });
    }

    await batch.commit();
    debugPrint(
      '[QuizService] Quiz created: ${quizRef.id} in class $classId '
      '(${questions.length} questions)',
    );
    return quizRef.id;
  }

  /// Stream of quizzes in a class, optionally filtered by topic.
  static Stream<List<QuizModel>> quizzesStream(
    String classId, {
    String? topicId,
  }) {
    Query<Map<String, dynamic>> query = _quizzesRef(classId);
    if (topicId != null) {
      query = query.where('topicId', isEqualTo: topicId);
    }
    return query.orderBy('createdAt').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => QuizModel.fromFirestore(doc)).toList());
  }

  /// Get a single quiz.
  static Future<QuizModel?> getQuiz(String classId, String quizId) async {
    final doc = await _quizzesRef(classId).doc(quizId).get();
    if (!doc.exists) return null;
    return QuizModel.fromFirestore(doc);
  }

  /// Stream a single quiz (real-time updates on title, settings, etc).
  static Stream<QuizModel?> quizStream(String classId, String quizId) {
    return _quizzesRef(classId).doc(quizId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return QuizModel.fromFirestore(doc);
    });
  }

  /// Stream of questions in a quiz, ordered by their `order` field.
  /// Options here never include `isCorrect` — students reading this stream
  /// only see the option text. Teachers wanting answers should also call
  /// [fetchAnswerKeys] and merge with [QuestionModel.withAnswers].
  static Stream<List<QuestionModel>> questionsStream(
    String classId,
    String quizId,
  ) {
    return _questionsRef(classId, quizId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuestionModel.fromFirestore(doc))
            .toList());
  }

  /// Teacher-only. Returns a map of questionId → correctIndices for one quiz.
  /// Firestore rules will reject this call for students (permission denied).
  static Future<Map<String, List<int>>> fetchAnswerKeys(
    String classId,
    String quizId,
  ) async {
    final snap = await _quizzesRef(classId)
        .doc(quizId)
        .collection('answer_keys')
        .get();
    return {
      for (final doc in snap.docs)
        doc.id: AnswerKeyModel.fromFirestore(doc).correctIndices,
    };
  }

  /// Update individual quiz fields. Only meta — not questions or answer keys.
  /// Per Firestore rules, only the class teacher can call this.
  static Future<void> updateQuizMeta(
    String classId,
    String quizId, {
    String? title,
    String? topicId,
    String? topicTitle,
    int? timeLimit,
    int? passingGrade,
    int? attemptLimit,
    bool? showAnswer,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (topicId != null) updates['topicId'] = topicId;
    if (topicTitle != null) updates['topicTitle'] = topicTitle;
    if (timeLimit != null) updates['timeLimit'] = timeLimit;
    if (passingGrade != null) updates['passingGrade'] = passingGrade;
    if (attemptLimit != null) updates['attemptLimit'] = attemptLimit;
    if (showAnswer != null) updates['showAnswer'] = showAnswer;

    if (updates.isEmpty) return;
    await _quizzesRef(classId).doc(quizId).update(updates);
    debugPrint('[QuizService] Quiz updated: $quizId — fields: ${updates.keys}');
  }

  /// Get the number of attempts the current student has made for a specific quiz.
  static Future<int> getStudentAttemptsCount(
    String classId,
    String quizId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final snap = await _quizzesRef(classId)
        .doc(quizId)
        .collection('attempts')
        .where('studentId', isEqualTo: user.uid)
        .count()
        .get();

    return snap.count ?? 0;
  }

  /// Total attempt count across all students for a quiz. Teacher-only.
  static Future<int> getTotalAttemptsCount(
    String classId,
    String quizId,
  ) async {
    final snap = await _quizzesRef(classId)
        .doc(quizId)
        .collection('attempts')
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Delete a quiz and all its subcollections (questions, answer_keys, attempts).
  /// Teacher-only per Firestore rules.
  static Future<void> deleteQuiz(String classId, String quizId) async {
    final quizRef = _quizzesRef(classId).doc(quizId);

    final questionsSnap = await quizRef.collection('questions').get();
    final keysSnap = await quizRef.collection('answer_keys').get();
    final attemptsSnap = await quizRef.collection('attempts').get();

    final batch = _firestore.batch();
    for (final d in questionsSnap.docs) {
      batch.delete(d.reference);
    }
    for (final d in keysSnap.docs) {
      batch.delete(d.reference);
    }
    for (final d in attemptsSnap.docs) {
      batch.delete(d.reference);
    }
    batch.delete(quizRef);

    await batch.commit();
    debugPrint(
      '[QuizService] Quiz deleted: $quizId — '
      'questions: ${questionsSnap.size}, '
      'keys: ${keysSnap.size}, '
      'attempts: ${attemptsSnap.size}',
    );
  }
}
