import 'api_client.dart';

/// Client untuk Express API material progression (track attachment click).
class MaterialProgressService {
  /// POST /api/classes/:cid/materials/:mid/attachments/:aid/access
  /// Panggil saat student klik attachment. Backend:
  ///  - Track aid ke material_completion (arrayUnion)
  ///  - Kalau semua attachment di material sudah di-click → material complete
  ///    + award POINT_MATERIAL_COMPLETE
  ///  - Cek Studyaholic (akses >= jam 22, count >= 5)
  ///  - Cek Flash (kalau topik complete + first to do it)
  static Future<MaterialProgressResult> trackAttachmentAccess({
    required String classId,
    required String materialId,
    required String attachmentId,
  }) async {
    final data = await ApiClient.post(
      '/classes/$classId/materials/$materialId/attachments/$attachmentId/access',
    ) as Map<String, dynamic>;
    return MaterialProgressResult.fromJson(data);
  }
}

class MaterialProgressResult {
  final String materialId;
  final int attachmentClickedCount;
  final int totalAttachments;
  final bool materialCompleted;
  final bool justCompleted;
  final int pointAwarded;
  final List<BadgeEarnInfo> badgesEarned;

  MaterialProgressResult({
    required this.materialId,
    required this.attachmentClickedCount,
    required this.totalAttachments,
    required this.materialCompleted,
    required this.justCompleted,
    required this.pointAwarded,
    required this.badgesEarned,
  });

  factory MaterialProgressResult.fromJson(Map<String, dynamic> json) {
    final raw = (json['badgesEarned'] as List?) ?? const [];
    return MaterialProgressResult(
      materialId: json['materialId'] ?? '',
      attachmentClickedCount:
          (json['attachmentClickedCount'] as num?)?.toInt() ?? 0,
      totalAttachments: (json['totalAttachments'] as num?)?.toInt() ?? 0,
      materialCompleted: json['materialCompleted'] == true,
      justCompleted: json['justCompleted'] == true,
      pointAwarded: (json['pointAwarded'] as num?)?.toInt() ?? 0,
      badgesEarned: raw
          .whereType<Map>()
          .map((m) => BadgeEarnInfo.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class BadgeEarnInfo {
  final String badgeId;
  final int count;
  final int pointBonus;

  BadgeEarnInfo({
    required this.badgeId,
    required this.count,
    required this.pointBonus,
  });

  factory BadgeEarnInfo.fromJson(Map<String, dynamic> json) => BadgeEarnInfo(
        badgeId: json['badgeId'] ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        pointBonus: (json['pointBonus'] as num?)?.toInt() ?? 0,
      );
}
