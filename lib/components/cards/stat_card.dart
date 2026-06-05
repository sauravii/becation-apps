import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool filled;
  final Color? fillColor;
  final Color? borderColor;
  final double? height;
  final double? borderRadius;

  const StatCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.filled = false,
    this.fillColor,
    this.borderColor,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final defaultFillColor = fillColor ?? const Color(0xFF6F5AAA);
    final defaultBorderColor = borderColor ?? const Color(0xFF6F5AAA);
    
    return Expanded(
      child: Container(
        height: height ?? 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: filled ? defaultFillColor : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius ?? 18),
          border: Border.all(color: defaultBorderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: filled ? Colors.white : defaultBorderColor,
              size: 22,
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: filled ? Colors.white : const Color(0xFF1F1F1F),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: filled ? Colors.white70 : Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
