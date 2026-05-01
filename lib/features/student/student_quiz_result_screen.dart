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
  });

  bool get _hasReview => correctAnswers.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      appBar: AppBar(
        title: Text(quiz.title, style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1B20),
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: _hasReview ? questions.length + 2 : 3,
        itemBuilder: (context, index) {
          if (index == 0) return _buildResultBanner();
          if (!_hasReview) {
            if (index == 1) return _buildAnswersHiddenNotice();
            return _buildDoneButton(context);
          }
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
            '$correct / $total correct  ·  Passing grade ${quiz.passingGrade}%',
            style: const TextStyle(fontSize: 13, color: Color(0xFF49454E)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswersHiddenNotice() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.visibility_off_outlined,
            color: Color(0xFF6F5AAA),
            size: 22,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Answers hidden',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1B20),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your teacher has hidden the correct answers for this quiz, so the per-question review is not shown.',
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildQuestionCard(int index, QuestionModel q) {
    final selected = userAnswers[q.id];
    final correctIndices = correctAnswers[q.id] ?? const <int>[];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${q.question}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1B20),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate(q.options.length, (optIndex) {
                final isCorrect = correctIndices.contains(optIndex);
                final isSelected = selected == optIndex;
                final isWrongPick = isSelected && !isCorrect;
                Color? bg;
                if (isCorrect) bg = Colors.green.shade50;
                if (isWrongPick) bg = Colors.red.shade50;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green.shade300
                          : isWrongPick
                              ? Colors.red.shade300
                              : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          isCorrect
                              ? Icons.check_circle
                              : isWrongPick
                                  ? Icons.cancel
                                  : Icons.radio_button_off,
                          size: 18,
                          color: isCorrect
                              ? Colors.green
                              : isWrongPick
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          q.options[optIndex].text,
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF1C1B20),
                            fontWeight:
                                isCorrect ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Your pick',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF49454E),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
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
