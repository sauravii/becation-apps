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

  String? _resolveIconUrl() {
    if (badge.iconUrl != null && badge.iconUrl!.isNotEmpty) return badge.iconUrl;
    if (badge.iconPath.isEmpty) return null;
    final encoded = Uri.encodeComponent(badge.iconPath);
    return 'https://firebasestorage.googleapis.com/v0/b/$_storageBucket/o/$encoded?alt=media';
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolveIconUrl();
    final earned = badge.earned;

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
                            Icons.emoji_events,
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                if (badge.earned && badge.repeatable && badge.count > 1)
                  Chip(
                    label: Text('Earned ${badge.count}x'),
                    backgroundColor: Colors.deepPurple.shade50,
                  )
                else if (badge.earned)
                  Chip(
                    label: const Text('Earned'),
                    backgroundColor: Colors.green.shade50,
                  )
                else
                  Chip(
                    label: Text(badge.isSecret ? 'Secret' : 'Locked'),
                    backgroundColor: Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                const SizedBox(width: 4),
                Text(
                  '+${badge.pointReward}${badge.repeatable ? " per earn" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Chip(
                  label: Text(badge.tier),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
