import 'package:flutter/material.dart';

import '../../services/badges_service.dart';
import 'badge_card.dart';

/// Grid responsive untuk display semua badge user.
/// Default 3 column. Pas untuk profile section.
class BadgesGrid extends StatelessWidget {
  final List<BadgeItem> badges;
  final int columns;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const BadgesGrid({
    super.key,
    required this.badges,
    this.columns = 3,
    this.iconSize = 72,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No badges available yet.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return Padding(
      padding: padding,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: 0.78,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: badges.length,
        itemBuilder: (_, i) => BadgeCard(
          badge: badges[i],
          iconSize: iconSize,
        ),
      ),
    );
  }
}
