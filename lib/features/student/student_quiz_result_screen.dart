import 'package:flutter/material.dart';

import '../../models/question_model.dart';
import '../../models/quiz_model.dart';

/// Read-only result view shown after a quiz attempt is submitted. If
/// [correctAnswers] is empty (quiz has showAnswer=off, or this is being
/// reused for a context where keys aren't available), the per-question
/// breakdown is hidden and only the banner + Done button are shown.
class StudentQuizResultScreen extends StatelessWidget {
  final QuizModel quiz;
  final List<QuestionModel> questions;
  final Map<String, int> userAnswers;
  final Map<String, List<int>> correctAnswers;
  final int score;
  final int correct;
  final int total;
  final bool passed;
  final bool isFinalAttempt;

  const StudentQuizResultScreen({
    super.key,
    required this.quiz,
    required this.questions,
    required this.userAnswers,
    required this.correctAnswers,
    required this.score,
    required this.correct,
    required this.total,
    required this.passed,
    this.isFinalAttempt = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      appBar: AppBar(
        title: Text(quiz.title, style: const TextStyle(fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF6F5AAA),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6F5AAA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 4),
                    Text(
                      'Finished',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: questions.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) return _buildResultBanner();
          if (index == questions.length + 1) {
            return _buildDoneButton(context);
          }
          final q = questions[index - 1];
          return _buildQuestionCard(index - 1, q);
        },
      ),
    );
  }

  Widget _buildResultBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: passed ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: passed ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passed ? Icons.check_circle : Icons.cancel,
                size: 28,
                color: passed ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 10),
              Text(
                passed ? 'Passed' : 'Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: passed ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Score: $score / 100',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            (quiz.showAnswer && isFinalAttempt)
                ? '$correct / $total correct  ·  Passing grade ${quiz.passingGrade}%'
                : 'Passing grade ${quiz.passingGrade}%',
            style: const TextStyle(fontSize: 13, color: Color(0xFF49454E)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, QuestionModel q) {
    final selected = userAnswers[q.id];
    final correctIndices = correctAnswers[q.id] ?? const <int>[];
    final showStatus = quiz.showAnswer && isFinalAttempt;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${index + 1}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1B20),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4DDEE), width: 1.5),
            ),
            child: Text(
              q.question,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1B20),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Column(
            children: List.generate(q.options.length, (optIndex) {
              final isCorrect = correctIndices.contains(optIndex);
              final isSelected = selected == optIndex;
              final isWrongPick = isSelected && !isCorrect;
              return _buildOptionTile(
                label: String.fromCharCode(65 + optIndex),
                text: q.options[optIndex].text,
                selected: isSelected,
                correct: isCorrect,
                wrongPick: isWrongPick,
                showStatus: showStatus,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required String label,
    required String text,
    bool selected = false,
    bool correct = false,
    bool wrongPick = false,
    bool showStatus = false,
  }) {
    Color borderColor = const Color(0xFFE4DDEE);
    Color fillColor = Colors.white;
    Color badgeColor = const Color(0xFF6F5AAA);
    Color badgeText = Colors.white;

    if (selected) {
      borderColor = const Color(0xFF6F5AAA);
      fillColor = const Color(0xFFF4F0FB);
    }
    if (showStatus) {
      if (correct) {
        borderColor = const Color(0xFF58B368);
        fillColor = const Color(0xFFEAF6EE);
        badgeColor = const Color(0xFF58B368);
      } else if (wrongPick) {
        borderColor = const Color(0xFFE06B6B);
        fillColor = const Color(0xFFFCEDED);
        badgeColor = const Color(0xFFE06B6B);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w700, color: badgeText),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B2633),
              ),
            ),
          ),
          if (showStatus && (correct || wrongPick))
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                correct ? Icons.check_circle : Icons.cancel,
                color: correct
                    ? const Color(0xFF58B368)
                    : const Color(0xFFE06B6B),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6F5AAA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Done', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
