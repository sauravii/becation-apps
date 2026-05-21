import 'api_client.dart';

/// Client untuk Express API leaderboard + semester close.
class LeaderboardService {
  /// GET /api/classes/:cid/leaderboard?limit=100
  /// Member of class only. Default + max limit = 100.
  static Future<LeaderboardData> getLeaderboard(
    String classId, {
    int limit = 100,
  }) async {
    final data = await ApiClient.get(
      '/classes/$classId/leaderboard?limit=$limit',
    ) as Map<String, dynamic>;
    return LeaderboardData.fromJson(data);
  }

  /// POST /api/classes/:cid/close-semester  (teacher only)
  /// Snapshot ranking final + award badge juara 1/2/3 + set closedAt.
  /// Idempotent — kalau class sudah closed, return alreadyClosed=true.
  static Future<CloseSemesterResult> closeSemester(String classId) async {
    final data = await ApiClient.post('/classes/$classId/close-semester')
        as Map<String, dynamic>;
    return CloseSemesterResult.fromJson(data);
  }
}

class LeaderboardData {
  final List<LeaderboardEntry> ranking;
  final int total;
  final bool closed;

  LeaderboardData({
    required this.ranking,
    required this.total,
    required this.closed,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    final raw = (json['ranking'] as List?) ?? const [];
    return LeaderboardData(
      ranking: raw
          .whereType<Map>()
          .map((m) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      closed: json['closed'] == true,
    );
  }
}

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int point;
  final int rank;

  LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.point,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        uid: json['uid'] ?? '',
        displayName: json['displayName'] ?? '',
        point: (json['point'] as num?)?.toInt() ?? 0,
        rank: (json['rank'] as num?)?.toInt() ?? 0,
      );
}

class CloseSemesterResult {
  final bool alreadyClosed;
  final List<LeaderboardEntry> ranking;
  final List<BadgeGrant> awardsGranted;

  CloseSemesterResult({
    required this.alreadyClosed,
    required this.ranking,
    required this.awardsGranted,
  });

  factory CloseSemesterResult.fromJson(Map<String, dynamic> json) {
    final rawRanking = (json['ranking'] as List?) ?? const [];
    final rawAwards = (json['awardsGranted'] as List?) ?? const [];
    return CloseSemesterResult(
      alreadyClosed: json['alreadyClosed'] == true,
      ranking: rawRanking
          .whereType<Map>()
          .map((m) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      awardsGranted: rawAwards
          .whereType<Map>()
          .map((m) => BadgeGrant.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class BadgeGrant {
  final int rank;
  final String badgeId;
  final String uid;

  BadgeGrant({
    required this.rank,
    required this.badgeId,
    required this.uid,
  });

  factory BadgeGrant.fromJson(Map<String, dynamic> json) => BadgeGrant(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        badgeId: json['badgeId'] ?? '',
        uid: json['uid'] ?? '',
      );
}
