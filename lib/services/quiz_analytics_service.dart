import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Client untuk Express API quiz analytics.
/// Base URL hardcoded ke project `becation-eac04` region `us-central1`.
class QuizAnalyticsService {
  static const String _baseUrl =
      'https://us-central1-becation-eac04.cloudfunctions.net/api';

  static Future<Map<String, dynamic>> _get(String path) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final token = await user.getIdToken();

    final res = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode >= 400) {
      String msg = 'HTTP ${res.statusCode}';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['error'] is String) {
          msg = body['error'] as String;
        }
      } catch (_) {}
      throw Exception(msg);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<AnalyticsSummary> fetchSummary(
      String classId, String quizId) async {
    final data =
        await _get('/classes/$classId/quizzes/$quizId/analytics');
    return AnalyticsSummary.fromJson(data);
  }

  static Future<List<QuestionAnalytics>> fetchPerQuestion(
      String classId, String quizId) async {
    final data = await _get(
        '/classes/$classId/quizzes/$quizId/analytics/per-question');
    final raw = (data['questions'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => QuestionAnalytics.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  static Future<AttemptsPage> fetchAttempts(
    String classId,
    String quizId, {
    int page = 1,
    int limit = 20,
    String sort = 'submittedAt',
  }) async {
    final data = await _get(
      '/classes/$classId/quizzes/$quizId/attempts?page=$page&limit=$limit&sort=$sort',
    );
    return AttemptsPage.fromJson(data);
  }
}

class AnalyticsSummary {
  final int totalAttempts;
  final int avgScore;
  final int minScore;
  final int maxScore;
  final double passRate;
  final List<ScoreBucket> scoreDistribution;

  AnalyticsSummary({
    required this.totalAttempts,
    required this.avgScore,
    required this.minScore,
    required this.maxScore,
    required this.passRate,
    required this.scoreDistribution,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    final raw = (json['scoreDistribution'] as List?) ?? const [];
    return AnalyticsSummary(
      totalAttempts: (json['totalAttempts'] as num?)?.toInt() ?? 0,
      avgScore: (json['avgScore'] as num?)?.toInt() ?? 0,
      minScore: (json['minScore'] as num?)?.toInt() ?? 0,
      maxScore: (json['maxScore'] as num?)?.toInt() ?? 0,
      passRate: (json['passRate'] as num?)?.toDouble() ?? 0,
      scoreDistribution: raw
          .whereType<Map>()
          .map((m) => ScoreBucket.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class ScoreBucket {
  final String bucket;
  final int count;

  ScoreBucket({required this.bucket, required this.count});

  factory ScoreBucket.fromJson(Map<String, dynamic> json) => ScoreBucket(
        bucket: json['bucket'] ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

class QuestionAnalytics {
  final String questionId;
  final String question;
  final double correctRate;
  final List<OptionDistribution> optionDistribution;

  QuestionAnalytics({
    required this.questionId,
    required this.question,
    required this.correctRate,
    required this.optionDistribution,
  });

  factory QuestionAnalytics.fromJson(Map<String, dynamic> json) {
    final raw = (json['optionDistribution'] as List?) ?? const [];
    return QuestionAnalytics(
      questionId: json['questionId'] ?? '',
      question: json['question'] ?? '',
      correctRate: (json['correctRate'] as num?)?.toDouble() ?? 0,
      optionDistribution: raw
          .whereType<Map>()
          .map((m) =>
              OptionDistribution.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class OptionDistribution {
  final int index;
  final String text;
  final int count;
  final double percentage;

  OptionDistribution({
    required this.index,
    required this.text,
    required this.count,
    required this.percentage,
  });

  factory OptionDistribution.fromJson(Map<String, dynamic> json) =>
      OptionDistribution(
        index: (json['index'] as num?)?.toInt() ?? 0,
        text: json['text'] ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      );
}

class AttemptsPage {
  final List<AttemptItem> items;
  final bool hasMore;
  final int total;

  AttemptsPage({
    required this.items,
    required this.hasMore,
    required this.total,
  });

  factory AttemptsPage.fromJson(Map<String, dynamic> json) {
    final raw = (json['items'] as List?) ?? const [];
    return AttemptsPage(
      items: raw
          .whereType<Map>()
          .map((m) => AttemptItem.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      hasMore: json['hasMore'] == true,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttemptItem {
  final String attemptId;
  final String studentId;
  final String studentName;
  final int score;
  final DateTime? submittedAt;

  AttemptItem({
    required this.attemptId,
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.submittedAt,
  });

  factory AttemptItem.fromJson(Map<String, dynamic> json) {
    final ts = json['submittedAt'];
    return AttemptItem(
      attemptId: json['attemptId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      submittedAt: ts is String ? DateTime.tryParse(ts) : null,
    );
  }
}
