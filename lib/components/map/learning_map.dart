import 'dart:math' as math;
import 'package:flutter/material.dart';

class LearningNode {
  final String id;
  final String title;
  final String type; // 'quiz' or 'material'
  final Color color;
  final Color shadowColor;

  // Ini sekarang bukan IconData lagi.
  // Isinya path asset, contoh:
  // 'lib/assets/icons/class_quiz.png'
  // 'lib/assets/icons/class_material.png'
  final String icon;

  final VoidCallback onTap;

  LearningNode({
    required this.id,
    required this.title,
    required this.type,
    required this.color,
    required this.shadowColor,
    required this.icon,
    required this.onTap,
  });
}

class LearningTopic {
  final String id;
  final String title;
  final List<LearningNode> nodes;

  LearningTopic({
    required this.id,
    required this.title,
    required this.nodes,
  });
}

class LearningMap extends StatelessWidget {
  final List<LearningTopic> topics;

  const LearningMap({
    super.key,
    required this.topics,
  });

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No learning path available yet.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    int globalNodeIndex = 0;

    return ListView.builder(
      reverse: true,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topics.length,
      itemBuilder: (context, topicIndex) {
        final topic = topics[topicIndex];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (topicIndex == 0)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 40, 20, 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9DFF0),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      offset: const Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOPIC ${topicIndex + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6F5AAA),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      topic.title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1C1B20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 20,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color: Color(0xFF49454E),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        topic.title,
                        style: const TextStyle(
                          color: Color(0xFF1C1B20),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        color: Color(0xFF49454E),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
              ),

            ...topic.nodes.map((node) {
              final double currentX = math.sin(globalNodeIndex * 0.8) * 0.5;
              globalNodeIndex++;

              return Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Align(
                  alignment: Alignment(currentX, 0),
                  child: GestureDetector(
                    onTap: node.onTap,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 3D Coin Asset (Image already has 3D effect)
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Center(
                            child: Image.asset(
                              node.icon,
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    color: Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}