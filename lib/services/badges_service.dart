import 'api_client.dart';

/// Client untuk Express API badges.
class BadgesService {
  static Future<List<BadgeItem>> getBadges(String uid) async {
    final data =
        await ApiClient.get('/users/$uid/badges') as Map<String, dynamic>;
    final raw = (data['badges'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => BadgeItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// POST /api/users/:uid/badges  (admin only)
  static Future<BadgeGrantResult> grantBadge(
    String uid,
    String badgeId, {
    Map<String, dynamic>? context,
    String? dedupKey,
  }) async {
    final body = <String, dynamic>{'badgeId': badgeId};
    if (context != null) body['context'] = context;
    if (dedupKey != null) body['dedupKey'] = dedupKey;
    final data =
        await ApiClient.post('/users/$uid/badges', body) as Map<String, dynamic>;
    return BadgeGrantResult.fromJson(data);
  }

  /// DELETE /api/users/:uid/badges/:badgeId  (admin only)
  static Future<void> revokeBadge(String uid, String badgeId) async {
    await ApiClient.delete('/users/$uid/badges/$badgeId');
  }
}

class BadgeItem {
  final String id;
  final String name;
  final String description;
  final String tier;
  final String iconPath;
  final String? iconUrl; // resolved kalau ada di badge_definitions Firestore doc
  final int pointReward;
  final bool isSecret;
  final bool repeatable;
  final String criteriaType;
  final bool earned;
  final int count;
  final DateTime? firstEarnedAt;
  final DateTime? lastEarnedAt;
  final Map<String, dynamic> lastContext;

  BadgeItem({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.iconPath,
    required this.iconUrl,
    required this.pointReward,
    required this.isSecret,
    required this.repeatable,
    required this.criteriaType,
    required this.earned,
    required this.count,
    required this.firstEarnedAt,
    required this.lastEarnedAt,
    required this.lastContext,
  });

  factory BadgeItem.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) =>
        v is String ? DateTime.tryParse(v) : null;
    return BadgeItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      tier: json['tier'] ?? '',
      iconPath: json['iconPath'] ?? '',
      iconUrl: json['iconUrl'] as String?,
      pointReward: (json['pointReward'] as num?)?.toInt() ?? 0,
      isSecret: json['isSecret'] == true,
      repeatable: json['repeatable'] == true,
      criteriaType: json['criteriaType'] ?? '',
      earned: json['earned'] == true,
      count: (json['count'] as num?)?.toInt() ?? 0,
      firstEarnedAt: parse(json['firstEarnedAt']),
      lastEarnedAt: parse(json['lastEarnedAt']),
      lastContext:
          (json['lastContext'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

class BadgeGrantResult {
  final bool awarded;
  final String badgeId;
  final int pointAwarded;
  final int count;
  final String? reason; // "already_earned" | "dedup" | null

  BadgeGrantResult({
    required this.awarded,
    required this.badgeId,
    required this.pointAwarded,
    required this.count,
    required this.reason,
  });

  factory BadgeGrantResult.fromJson(Map<String, dynamic> json) =>
      BadgeGrantResult(
        awarded: json['awarded'] == true,
        badgeId: json['badgeId'] ?? '',
        pointAwarded: (json['pointAwarded'] as num?)?.toInt() ?? 0,
        count: (json['count'] as num?)?.toInt() ?? 0,
        reason: json['reason'] as String?,
      );
}
