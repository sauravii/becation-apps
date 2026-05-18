import 'package:flutter/material.dart';

class QuizCard extends StatelessWidget {
  final String title;
  final int questionCount;
  final int timeLimit;
  final int passingGrade;
  final String topicTitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const QuizCard({
    super.key,
    required this.title,
    required this.questionCount,
    required this.timeLimit,
    required this.passingGrade,
    this.topicTitle = '',
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      '$questionCount question${questionCount == 1 ? '' : 's'}',
      '$timeLimit min${timeLimit == 1 ? '' : 's'}',
      '$passingGrade% to pass',
    ].join(' · ');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE9D6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: const Border(
              bottom: BorderSide(color: Color(0xFFFF7B54), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7B54),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(Icons.quiz, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C1B20),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (topicTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        topicTitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6F5AAA),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
