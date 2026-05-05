import 'package:flutter/material.dart';

import '../../models/quiz_model.dart';
import 'student_quiz_attempt_screen.dart';

/// Pre-quiz intro/preparation screen. Shows quiz info + warning before
/// the student commits to starting. Tapping "Mulai Quiz" pushReplaces this
/// route with the attempt screen so back from attempt won't return here.
class StudentQuizIntroScreen extends StatelessWidget {
  final String classId;
  final QuizModel quiz;
  final int attemptCount;

  const StudentQuizIntroScreen({
    super.key,
    required this.classId,
    required this.quiz,
    required this.attemptCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1B20),
        elevation: 1,
        title: const Text('Quiz', style: TextStyle(fontSize: 18)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildInfoRow(),
              const SizedBox(height: 20),
              _buildWarning(),
              const Spacer(flex: 3),
              _buildStartButton(context),
              const SizedBox(height: 8),
              _buildCancelButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF6F5AAA).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.quiz_outlined,
            size: 40,
            color: Color(0xFF6F5AAA),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          quiz.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1C1B20),
            height: 1.3,
          ),
        ),
        if (quiz.topicTitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            quiz.topicTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF49454E),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.timer_outlined,
            value: '${quiz.timeLimit} min',
            label: 'Duration',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoCard(
            icon: Icons.flag_outlined,
            value: '${quiz.passingGrade}%',
            label: 'Pass grade',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoCard(
            icon: Icons.repeat_rounded,
            value: '${attemptCount + 1}/${quiz.attemptLimit}',
            label: 'Attempt',
          ),
        ),
      ],
    );
  }

  Widget _buildWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade800,
            size: 22,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Once you start, you can't exit without submitting.",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1B20),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'The timer starts immediately and this attempt counts even if you leave mid-quiz.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF49454E),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => StudentQuizAttemptScreen(
                classId: classId,
                quiz: quiz,
              ),
            ),
          );
        },
        icon: const Icon(Icons.play_arrow_rounded, size: 22),
        label: const Text(
          'Start Quiz',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6F5AAA),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text(
        'Cancel',
        style: TextStyle(color: Color(0xFF49454E)),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _InfoCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF6F5AAA), size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1B20),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF49454E),
            ),
          ),
        ],
      ),
    );
  }
}
