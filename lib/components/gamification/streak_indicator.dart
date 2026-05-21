import 'package:flutter/material.dart';

/// Flame indicator menampilkan jumlah hari streak.
/// Warna escalate: orange → deepOrange (≥ 7 hari) → red (≥ 28 hari).
class StreakIndicator extends StatelessWidget {
  final int streakDay;
  final bool compact;

  const StreakIndicator({
    super.key,
    required this.streakDay,
    this.compact = false,
  });

  Color _color() {
    if (streakDay >= 28) return Colors.red.shade700;
    if (streakDay >= 7) return Colors.deepOrange;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final label = compact
        ? streakDay.toString()
        : '$streakDay day${streakDay == 1 ? '' : 's'}';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
