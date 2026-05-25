import 'package:flutter/material.dart';

import '../components/gamification/badge_award_popup.dart';
import 'badges_service.dart';

/// Helper untuk detect & display reward (point + badge) yang di-award
/// asynchronously oleh backend trigger setelah user action (quiz submit,
/// material complete, ping).
///
/// Pattern:
///   1. `captureBefore(uid)` sebelum action → snapshot badge IDs yang udah earned
///   2. User action jalan (Callable / REST / dst)
///   3. `showDiffAfter(...)` setelah action → tunggu trigger selesai, diff,
///      tampilkan snackbar untuk point + popup untuk badge baru
class GamificationFeedback {
  /// Capture snapshot badge IDs sebelum action — dipakai untuk diff nanti.
  /// Return Set kosong kalau gagal (jangan throw — feedback bersifat opsional).
  static Future<Set<String>> captureBefore(String uid) async {
    try {
      final badges = await BadgesService.getBadges(uid);
      return badges.where((b) => b.earned).map((b) => b.id).toSet();
    } catch (_) {
      return const {};
    }
  }

  /// Tunggu [waitFor] supaya backend trigger sempat process, lalu diff badge
  /// dan tampilkan popup untuk yang baru. Optional: tampilkan snackbar point.
  ///
  /// [pointDelta] kalau di-pass akan tampil snackbar "Earned +X points".
  /// [waitFor] default 2 detik — cukup untuk trigger Firestore biasanya complete.
  static Future<void> showDiffAfter({
    required BuildContext context,
    required String uid,
    required Set<String> previousBadgeIds,
    int? pointDelta,
    String? customSnackbarMessage,
    Duration waitFor = const Duration(seconds: 2),
  }) async {
    // Snackbar untuk point — tampil dulu (jangan tunggu trigger).
    if (context.mounted &&
        (customSnackbarMessage != null ||
            (pointDelta != null && pointDelta > 0))) {
      final msg = customSnackbarMessage ?? 'Earned +$pointDelta points';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF6F5AAA),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Tunggu trigger backend selesai process badge award.
    await Future.delayed(waitFor);
    if (!context.mounted) return;

    // Re-fetch & diff.
    List<BadgeItem> newBadges;
    try {
      final after = await BadgesService.getBadges(uid);
      newBadges = after
          .where((b) => b.earned && !previousBadgeIds.contains(b.id))
          .toList();
    } catch (_) {
      return;
    }
    if (newBadges.isEmpty || !context.mounted) return;

    // Show popup untuk masing-masing badge baru, sequential.
    for (final badge in newBadges) {
      if (!context.mounted) break;
      await BadgeAwardPopup.show(context, badge);
    }
  }
}
