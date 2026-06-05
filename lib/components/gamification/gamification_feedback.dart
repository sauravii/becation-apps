import 'package:flutter/material.dart';

import '../../services/badges_service.dart';
import 'badge_award_popup.dart';

// Sama dengan logic resolve URL di BadgeAwardPopup — duplicate kecil OK
// dibanding expose helper public yang gak dipakai dimana-mana.
const String _kStorageBucket = 'becation-eac04.firebasestorage.app';
String? _resolveBadgeIconUrl(BadgeItem badge) {
  if (badge.iconUrl != null && badge.iconUrl!.isNotEmpty) return badge.iconUrl;
  if (badge.iconPath.isEmpty) return null;
  final encoded = Uri.encodeComponent(badge.iconPath);
  return 'https://firebasestorage.googleapis.com/v0/b/$_kStorageBucket/o/$encoded?alt=media';
}

/// Helper untuk detect & display reward (point + badge) yang di-award
/// asynchronously oleh backend trigger setelah user action (quiz submit,
/// material complete, ping).
///
/// Pattern penggunaan:
///   1. `captureBefore(uid)` sebelum action → snapshot badge IDs yang udah earned
///   2. User action jalan (Callable / REST / dst)
///   3. `showSnackbar(...)` segera setelah action sukses (fire-and-forget)
///   4. `showBadgePopups(...)` AWAITED sebelum navigation/pop — kalau ada badge
///      baru, popup muncul; context tetap valid karena screen masih alive.
class GamificationFeedback {
  /// Capture snapshot badge counts (badgeId → count) sebelum action.
  /// Pakai count, bukan cuma ID, supaya repeatable badge (e.g. Flash earned
  /// di topic ke-2) tetap ke-detect sebagai "new earn" walaupun ID udah
  /// pernah ada. Return map kosong kalau gagal.
  static Future<Map<String, int>> captureBefore(String uid) async {
    try {
      final badges = await BadgesService.getBadges(uid);
      final counts = <String, int>{};
      for (final b in badges) {
        if (b.earned) counts[b.id] = b.count;
      }
      debugPrint('[GamificationFeedback] captureBefore: ${counts.length} earned → $counts');
      return counts;
    } catch (e) {
      debugPrint('[GamificationFeedback] captureBefore failed: $e');
      return const {};
    }
  }

  /// Snackbar fire-and-forget — tampil segera setelah action sukses.
  static void showSnackbar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF6F5AAA),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Tunggu [waitFor] supaya backend trigger sempat process, lalu diff badge.
  /// Untuk tiap badge baru, show popup sequential (await tiap popup ditutup
  /// dulu sebelum show next). Caller HARUS await ini sebelum Navigator.pop —
  /// kalau enggak, screen unmount duluan dan popup gak akan muncul.
  static Future<void> showBadgePopups({
    required BuildContext context,
    required String uid,
    required Map<String, int> previousBadgeCounts,
    Duration waitFor = const Duration(seconds: 2),
  }) async {
    debugPrint('[GamificationFeedback] showBadgePopups: waiting ${waitFor.inMilliseconds}ms for trigger...');
    await Future.delayed(waitFor);
    if (!context.mounted) {
      debugPrint('[GamificationFeedback] context unmounted after delay, aborting');
      return;
    }

    List<BadgeItem> newBadges;
    try {
      final after = await BadgesService.getBadges(uid);
      final afterCounts = <String, int>{
        for (final b in after) if (b.earned) b.id: b.count,
      };
      debugPrint('[GamificationFeedback] post-trigger: $afterCounts');
      // "New earn" = earned AND (belum pernah earned, atau count bertambah).
      // Yang kedua handle repeatable badges (Flash, dst) — earn ke-N tetap
      // muncul popup walaupun ID-nya udah ada di previous snapshot.
      newBadges = after.where((b) {
        if (!b.earned) return false;
        final prevCount = previousBadgeCounts[b.id] ?? 0;
        return b.count > prevCount;
      }).toList();
      debugPrint('[GamificationFeedback] diff: ${newBadges.length} NEW earns → ${newBadges.map((b) => "${b.id}(x${b.count})").toList()}');
    } catch (e) {
      debugPrint('[GamificationFeedback] fetch-after failed: $e');
      return;
    }
    if (newBadges.isEmpty) {
      debugPrint('[GamificationFeedback] no new badges, skip popup');
      return;
    }
    if (!context.mounted) {
      debugPrint('[GamificationFeedback] context unmounted before showing popup');
      return;
    }

    for (final badge in newBadges) {
      if (!context.mounted) break;
      // Precache image dulu — popup render tanpa loading spinner kalau berhasil.
      final url = _resolveBadgeIconUrl(badge);
      if (url != null) {
        try {
          await precacheImage(NetworkImage(url), context).timeout(
            const Duration(seconds: 3),
            onTimeout: () => null,
          );
        } catch (e) {
          debugPrint('[GamificationFeedback] precache failed for ${badge.id}: $e');
        }
      }
      if (!context.mounted) break;
      debugPrint('[GamificationFeedback] showing popup for badge: ${badge.id} (${badge.name})');
      await BadgeAwardPopup.show(context, badge);
    }
  }
}
