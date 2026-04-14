import 'package:flutter/material.dart';
import 'material_card.dart';

class TopicItem {
  final String id;
  final String title;
  final List<MaterialItem> materials;
  final VoidCallback? onMoreTap;

  TopicItem({
    required this.id,
    required this.title,
    required this.materials,
    this.onMoreTap,
  });
}

class TopicSection extends StatelessWidget {
  final TopicItem topic;

  const TopicSection({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TopicHeader(title: topic.title, onMoreTap: topic.onMoreTap),
        const Divider(color: Color(0xFF49454E), thickness: 1, height: 20),
        const SizedBox(height: 10),
        ...topic.materials.map(
          (material) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MaterialCard(
              material: material,
              topicTitle: topic.title,
              topicColor: const Color(0xFF6F5AAA),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class TopicHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMoreTap;

  const TopicHeader({super.key, required this.title, this.onMoreTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1B20),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1C1B20)),
            onPressed: onMoreTap,
          ),
        ],
      ),
    );
  }
}
