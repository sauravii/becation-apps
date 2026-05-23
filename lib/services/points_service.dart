import 'api_client.dart';

/// Client untuk Express API points + daily streak ping.
class PointsService {
  /// POST /api/users/me/ping
  /// Panggil di splash/cold-start. Update daily streak, award point harian,
  /// auto-check badge Overachiever kalau hit milestone 28/56/84/...
  static Future<PingResult> ping() async {
    final data = await ApiClient.post('/users/me/ping') as Map<String, dynamic>;
    return PingResult.fromJson(data);
  }

  /// GET /api/users/:uid/points
  /// Self atau admin. Pakai "me" untuk self.
  static Future<PointsInfo> getPoints(String uid) async {
    final data =
        await ApiClient.get('/users/$uid/points') as Map<String, dynamic>;
    return PointsInfo.fromJson(data);
  }

  /// GET /api/users/:uid/points/log
  /// Paginated audit trail. cursor = last doc id dari halaman sebelumnya.
  static Future<PointsLogPage> getPointsLog(
    String uid, {
    int limit = 30,
    String? cursor,
  }) async {
    final qs = <String>['limit=$limit'];
    if (cursor != null && cursor.isNotEmpty) qs.add('cursor=$cursor');
    final data = await ApiClient.get('/users/$uid/points/log?${qs.join('&')}')
        as Map<String, dynamic>;
    return PointsLogPage.fromJson(data);
  }
}

class PingResult {
  final int streakDay;
  final int longestStreak;
  final bool isNewDay;
  final int pointAwarded;
  final int? milestoneReached;
  final bool overachieverEarned;

  PingResult({
    required this.streakDay,
    required this.longestStreak,
    required this.isNewDay,
    required this.pointAwarded,
    required this.milestoneReached,
    required this.overachieverEarned,
  });

  factory PingResult.fromJson(Map<String, dynamic> json) => PingResult(
        streakDay: (json['streakDay'] as num?)?.toInt() ?? 0,
        longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
        isNewDay: json['isNewDay'] == true,
        pointAwarded: (json['pointAwarded'] as num?)?.toInt() ?? 0,
        milestoneReached: (json['milestoneReached'] as num?)?.toInt(),
        overachieverEarned: json['overachieverEarned'] == true,
      );
}

class PointsInfo {
  final String uid;
  final int point;
  final StreakInfo streak;

  PointsInfo({required this.uid, required this.point, required this.streak});

  factory PointsInfo.fromJson(Map<String, dynamic> json) => PointsInfo(
        uid: json['uid'] ?? '',
        point: (json['point'] as num?)?.toInt() ?? 0,
        streak: StreakInfo.fromJson(
          (json['streak'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      );
}

class StreakInfo {
  final int current;
  final int longest;
  final String? lastLoginDate;

  StreakInfo({
    required this.current,
    required this.longest,
    required this.lastLoginDate,
  });

  factory StreakInfo.fromJson(Map<String, dynamic> json) => StreakInfo(
        current: (json['current'] as num?)?.toInt() ?? 0,
        longest: (json['longest'] as num?)?.toInt() ?? 0,
        lastLoginDate: json['lastLoginDate'] as String?,
      );
}

class PointsLogPage {
  final List<PointsLogEntry> logs;
  final String? nextCursor;

  PointsLogPage({required this.logs, required this.nextCursor});

  factory PointsLogPage.fromJson(Map<String, dynamic> json) {
    final raw = (json['logs'] as List?) ?? const [];
    return PointsLogPage(
      logs: raw
          .whereType<Map>()
          .map((m) => PointsLogEntry.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }
}

class PointsLogEntry {
  final String id;
  final int delta;
  final String reason;
  final String refType;
  final String refId;
  final Map<String, dynamic> meta;
  final DateTime? createdAt;

  PointsLogEntry({
    required this.id,
    required this.delta,
    required this.reason,
    required this.refType,
    required this.refId,
    required this.meta,
    required this.createdAt,
  });

  factory PointsLogEntry.fromJson(Map<String, dynamic> json) {
    final ts = json['createdAt'];
    return PointsLogEntry(
      id: json['id'] ?? '',
      delta: (json['delta'] as num?)?.toInt() ?? 0,
      reason: json['reason'] ?? '',
      refType: json['refType'] ?? '',
      refId: json['refId'] ?? '',
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdAt: ts is String ? DateTime.tryParse(ts) : null,
    );
  }
}
