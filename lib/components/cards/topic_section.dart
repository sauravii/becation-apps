import 'package:flutter/material.dart';
import 'material_card.dart';
import 'quiz_card.dart';

class QuizItem {
  final String id;
  final String title;
  final int questionCount;
  final int timeLimit;
  final int passingGrade;
  final VoidCallback? onTap;

  QuizItem({
    required this.id,
    required this.title,
    required this.questionCount,
    required this.timeLimit,
    required this.passingGrade,
    this.onTap,
  });
}

class TopicItem {
  final String id;
  final String title;
  final List<MaterialItem> materials;
  final List<QuizItem> quizzes;
  // Callback saat user pilih "Edit" dari menu titik tiga.
  final VoidCallback? onEdit;
  // Callback saat user pilih "Delete" dari menu titik tiga.
  final VoidCallback? onDelete;

  TopicItem({
    required this.id,
    required this.title,
    required this.materials,
    this.quizzes = const [],
    this.onEdit,
    this.onDelete,
  });
}

class TopicSection extends StatelessWidget {
  final TopicItem topic;

  const TopicSection({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final hasQuizzes = topic.quizzes.isNotEmpty;
    final hasMaterials = topic.materials.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TopicHeader(
          title: topic.title,
          onEdit: topic.onEdit,
          onDelete: topic.onDelete,
        ),
        const Divider(color: Color(0xFF49454E), thickness: 1, height: 20),
        const SizedBox(height: 10),
        if (hasQuizzes)
          ...topic.quizzes.map(
            (quiz) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: QuizCard(
                title: quiz.title,
                questionCount: quiz.questionCount,
                timeLimit: quiz.timeLimit,
                passingGrade: quiz.passingGrade,
                onTap: quiz.onTap,
              ),
            ),
          ),
        if (hasMaterials)
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
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TopicHeader({
    super.key,
    required this.title,
    this.onEdit,
    this.onDelete,
  });

  bool get _hasMenu => onEdit != null || onDelete != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1B20),
              ),
            ),
          ),
          if (_hasMenu)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1C1B20)),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit?.call();
                    break;
                  case 'delete':
                    onDelete?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: Color(0xFF1C1B20)),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
