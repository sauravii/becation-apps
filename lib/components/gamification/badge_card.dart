import 'package:flutter/material.dart';

import '../../services/badges_service.dart';

/// Card untuk satu badge. Greyed kalau belum earned. Untuk repeatable badge
/// dengan count > 1, tampilkan multiplier "xN" di pojok kanan bawah.
class BadgeCard extends StatelessWidget {
  /// Bucket Firebase Storage Becation. Dipakai untuk construct iconUrl
  /// fallback kalau API tidak return iconUrl.
  static const String _storageBucket = 'becation-eac04.firebasestorage.app';

  final BadgeItem badge;
  final double iconSize;
  final VoidCallback? onTap;

  const BadgeCard({
    super.key,
    required this.badge,
    this.iconSize = 72,
    this.onTap,
  });

  bool get _isLockedSecret => badge.isSecret && !badge.earned;

  String? _resolveIconUrl() {
    if (_isLockedSecret) return null; // jangan resolve URL kalau secret locked
    if (badge.iconUrl != null && badge.iconUrl!.isNotEmpty) return badge.iconUrl;
    if (badge.iconPath.isEmpty) return null;
    final encoded = Uri.encodeComponent(badge.iconPath);
    return 'https://firebasestorage.googleapis.com/v0/b/$_storageBucket/o/$encoded?alt=media';
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolveIconUrl();
    final earned = badge.earned;
    final lockedSecret = _isLockedSecret;

    return InkWell(
      onTap: onTap ?? () => _showInfo(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: url != null
                      ? ClipOval(
                          child: ColorFiltered(
                            colorFilter: earned
                                ? const ColorFilter.mode(
                                    Colors.transparent, BlendMode.multiply)
                                : const ColorFilter.matrix([
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0, 0, 0, 1, 0,
                                  ]),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.emoji_events,
                                size: iconSize * 0.5,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            lockedSecret
                                ? Icons.help_outline
                                : Icons.emoji_events,
                            size: iconSize * 0.5,
                            color: Colors.grey,
                          ),
                        ),
                ),
                if (earned && badge.repeatable && badge.count > 1)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        'x${badge.count}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: earned ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    final lockedSecret = _isLockedSecret;
    // Secret badge selalu pakai pill "Secret" purple (gantiin tier). Untuk
    // badge non-secret, pakai mapping tier biasa.
    final tier = badge.isSecret ? _secretPill() : _tierInfo(badge.tier);
    final status = _statusInfo();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 24 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    badge.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (tier != null) ...[
                  _pillBadge(tier),
                  const SizedBox(width: 6),
                ],
                _pillBadge(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              lockedSecret
                  ? 'This badge is hidden. Keep exploring to discover how to unlock it!'
                  : badge.description,
              style: const TextStyle(color: Colors.black54),
            ),
            if (!lockedSecret) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '+${badge.pointReward}${badge.repeatable ? " per earn" : ""}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pillBadge(_PillInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: info.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: info.fg,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  _PillInfo _statusInfo() {
    // Secret badge: status pill juga pakai purple supaya seragam dgn tier pill
    // (lock/unlock state tetap tampil — user request: "indikator locked
    // unlocked juga" dapat warna purple).
    if (badge.earned && badge.repeatable && badge.count > 1) {
      return _PillInfo(
        'Unlocked ${badge.count}x',
        const Color(0xFFEDE7F6),
        const Color(0xFF4527A0),
      );
    }
    if (badge.earned) {
      if (badge.isSecret) {
        return const _PillInfo(
          'Unlocked',
          Color(0xFFEDE7F6),
          Color(0xFF4527A0),
        );
      }
      return const _PillInfo(
        'Unlocked',
        Color(0xFFE8F5E9),
        Color(0xFF2E7D32),
      );
    }
    if (badge.isSecret) {
      return const _PillInfo(
        'Locked',
        Color(0xFFEDE7F6),
        Color(0xFF4527A0),
      );
    }
    return const _PillInfo(
      'Locked',
      Color(0xFFEEEEEE),
      Color(0xFF616161),
    );
  }

  _PillInfo _secretPill() => const _PillInfo(
        'Secret',
        Color(0xFFF3E5F5),
        Color(0xFF6A1B9A),
      );

  _PillInfo? _tierInfo(String tier) {
    switch (tier) {
      case 'hardest':
      case 'hard':
        return const _PillInfo(
          'Hard',
          Color(0xFFFFEBEE),
          Color(0xFFC62828),
        );
      case 'medium':
        return const _PillInfo(
          'Medium',
          Color(0xFFFFF8E1),
          Color(0xFF8D6E00),
        );
      case 'easy':
      case 'easiest':
        return const _PillInfo(
          'Easy',
          Color(0xFFE8F5E9),
          Color(0xFF2E7D32),
        );
      case 'reward':
        return const _PillInfo(
          'Reward',
          Color(0xFFFFF3E0),
          Color(0xFFE65100),
        );
      default:
        return null;
    }
  }
}

class _PillInfo {
  final String label;
  final Color bg;
  final Color fg;
  const _PillInfo(this.label, this.bg, this.fg);
}
