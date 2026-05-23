import 'api_client.dart';

/// Client untuk Express API quiz analytics.
class QuizAnalyticsService {
  static Future<AnalyticsSummary> fetchSummary(
      String classId, String quizId) async {
    final data = await ApiClient.get(
      '/classes/$classId/quizzes/$quizId/analytics',
    ) as Map<String, dynamic>;
    return AnalyticsSummary.fromJson(data);
  }

  static Future<List<QuestionAnalytics>> fetchPerQuestion(
      String classId, String quizId) async {
    final data = await ApiClient.get(
      '/classes/$classId/quizzes/$quizId/analytics/per-question',
    ) as Map<String, dynamic>;
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
    final data = await ApiClient.get(
      '/classes/$classId/quizzes/$quizId/attempts?page=$page&limit=$limit&sort=$sort',
    ) as Map<String, dynamic>;
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

  final int totalStudents;
  final int passingGrade;
  final int uniqueParticipants;
  final int failedParticipants;

  AnalyticsSummary({
    required this.totalAttempts,
    required this.avgScore,
    required this.minScore,
    required this.maxScore,
    required this.passRate,
    required this.scoreDistribution,
    this.totalStudents = 0,
    this.passingGrade = 0,
    this.uniqueParticipants = 0,
    this.failedParticipants = 0,
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
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      passingGrade: (json['passingGrade'] as num?)?.toInt() ?? 0,
      uniqueParticipants:
          (json['uniqueParticipants'] as num?)?.toInt() ?? 0,
      failedParticipants:
          (json['failedParticipants'] as num?)?.toInt() ?? 0,
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
  int? correctOptionIndex;
  final double? averageTimeSeconds;

  QuestionAnalytics({
    required this.questionId,
    required this.question,
    required this.correctRate,
    required this.optionDistribution,
    this.correctOptionIndex,
    this.averageTimeSeconds,
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
      correctOptionIndex: (json['correctOptionIndex'] as num?)?.toInt(),
      averageTimeSeconds: (json['averageTimeSeconds'] as num?)?.toDouble(),
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
  final bool passed;
  final int attemptNumber;

  AttemptItem({
    required this.attemptId,
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.submittedAt,
    this.passed = false,
    this.attemptNumber = 1,
  });

  factory AttemptItem.fromJson(Map<String, dynamic> json) {
    final ts = json['submittedAt'];
    return AttemptItem(
      attemptId: json['attemptId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      submittedAt: ts is String ? DateTime.tryParse(ts) : null,
      passed: json['passed'] == true,
      attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 1,
    );
  }
}
