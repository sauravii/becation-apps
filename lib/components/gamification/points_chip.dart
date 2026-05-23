import 'package:flutter/material.dart';

/// Small chip showing total point. Use di app bar / header.
class PointsChip extends StatelessWidget {
  final int point;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const PointsChip({
    super.key,
    required this.point,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: Colors.amber.shade800),
          const SizedBox(width: 4),
          Text(
            point.toString(),
            style: TextStyle(
              color: Colors.amber.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: chip,
    );
  }
}
