import 'package:flutter/material.dart';

import '../../services/badges_service.dart';
import '../skeleton_circle_avatar.dart';

/// Popup announcement waktu user dapat badge baru. Dipakai setelah quiz
/// completion / material completion / streak milestone.
/// Show via [BadgeAwardPopup.show] — auto handle showDialog + barrier dismiss.
class BadgeAwardPopup extends StatelessWidget {
  static const String _storageBucket = 'becation-eac04.firebasestorage.app';

  final BadgeItem badge;

  const BadgeAwardPopup({super.key, required this.badge});

  /// Static helper — show popup sebagai modal dialog. Barrier dismiss
  /// disabled supaya gak ke-tutup gak sengaja saat user tap luar; user harus
  /// klik tombol "Awesome!" untuk close. useRootNavigator supaya tetap
  /// muncul kalau parent screen kebetulan pop.
  static Future<void> show(BuildContext context, BadgeItem badge) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      useRootNavigator: true,
      builder: (_) => BadgeAwardPopup(badge: badge),
    );
  }

  String? _iconUrl() {
    if (badge.iconUrl != null && badge.iconUrl!.isNotEmpty) {
      return badge.iconUrl;
    }
    if (badge.iconPath.isEmpty) return null;
    final encoded = Uri.encodeComponent(badge.iconPath);
    return 'https://firebasestorage.googleapis.com/v0/b/$_storageBucket/o/$encoded?alt=media';
  }

  @override
  Widget build(BuildContext context) {
    final url = _iconUrl();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Congrats! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6F5AAA),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You earned a new badge',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            // Badge image — large di tengah supaya jadi focus.
            // frameBuilder kasih shimmer skeleton saat image belum decode
            // (precache di GamificationFeedback biasanya udah warm cache,
            // jadi skeleton cuma muncul kalau precache miss/network slow).
            SizedBox(
              width: 120,
              height: 120,
              child: url != null
                  ? ClipOval(
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        frameBuilder:
                            (_, child, frame, wasSyncLoaded) {
                          if (frame == null) {
                            return const SkeletonCircleAvatar(radius: 60);
                          }
                          return child;
                        },
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.emoji_events,
                          size: 80,
                          color: Color(0xFF6F5AAA),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.emoji_events,
                      size: 80,
                      color: Color(0xFF6F5AAA),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1B20),
              ),
            ),
            if (badge.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
            if (badge.pointReward > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: Color(0xFFE65100)),
                    const SizedBox(width: 4),
                    Text(
                      '+${badge.pointReward} points',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6F5AAA),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
