import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/question_model.dart';
import '../../models/quiz_model.dart';
import '../../services/auth_service.dart';
import '../../components/gamification/gamification_feedback.dart';
import '../../services/quiz_service.dart';

class StudentQuizAttemptScreen extends StatefulWidget {
  final String classId;
  final QuizModel quiz;

  const StudentQuizAttemptScreen({
    super.key,
    required this.classId,
    required this.quiz,
  });

  @override
  State<StudentQuizAttemptScreen> createState() =>
      _StudentQuizAttemptScreenState();
}

class _StudentQuizAttemptScreenState extends State<StudentQuizAttemptScreen> {
  late final Stream<List<QuestionModel>> _questionsStream;
  List<QuestionModel> _questions = [];
  bool _isSubmitting = false;

  // Map of questionId -> selected option index
  final Map<String, int> _answers = {};

  // Countdown timer
  Timer? _timer;
  late int _remainingSeconds;
  bool _autoSubmitted = false;

  // Review state (after submission, if quiz.showAnswer == true)
  bool _isReviewing = false;
  Map<String, List<int>> _correctAnswers = {};
  int _score = 0;
  int _correct = 0;
  int _total = 0;
  bool _passed = false;

  @override
  void initState() {
    super.initState();
    _questionsStream = QuizService.questionsStream(
      widget.classId,
      widget.quiz.id,
    );
    _remainingSeconds = widget.quiz.timeLimit * 60;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_remainingSeconds <= 0) {
        t.cancel();
        if (!_isSubmitting && !_isReviewing) {
          _autoSubmitted = true;
          _submitQuiz(skipIncompleteWarning: true);
        }
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  String get _formattedTime {
    final mins = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Color get _timerColor {
    if (_remainingSeconds <= 60) return Colors.red;
    if (_remainingSeconds <= 300) return Colors.orange;
    return const Color(0xFF6F5AAA);
  }

  Future<void> _submitQuiz({bool skipIncompleteWarning = false}) async {
    if (!skipIncompleteWarning && _answers.length < _questions.length) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Incomplete Quiz'),
          content: const Text(
            'You have not answered all questions. Are you sure you want to submit?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit Anyway'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);

    // Capture badge state sebelum submit — buat diff nanti supaya bisa
    // tampilkan popup untuk badge baru / repeat earn yang di-award trigger.
    final uid = AuthService.currentUid ?? '';
    final preBadges = uid.isEmpty
        ? const <String, int>{}
        : await GamificationFeedback.captureBefore(uid);

    try {
      final result = await QuizService.submitQuizAttempt(
        classId: widget.classId,
        quizId: widget.quiz.id,
        answers: _answers,
      );

      if (!mounted) return;

      _timer?.cancel();
      final score = result.score;
      final correct = result.correct;
      final total = result.total;
      final passed = result.passed;
      final correctAnswers = result.correctAnswers;

      // Snackbar — fire-and-forget, tampil instan setelah submit success.
      GamificationFeedback.showSnackbar(
        context,
        passed
            ? 'Quiz completed! Score: $score'
            : 'Quiz submitted. Score: $score',
      );

      if (_autoSubmitted) {
        await _showAutoSubmitNotice();
        if (!mounted) return;
      }

      if (widget.quiz.showAnswer && correctAnswers.isNotEmpty) {
        // Switch screen to review mode — screen tetap alive, popup bisa fire
        // di background tanpa risiko context invalid.
        setState(() {
          _isSubmitting = false;
          _isReviewing = true;
          _correctAnswers = correctAnswers;
          _score = score;
          _correct = correct;
          _total = total;
          _passed = passed;
        });
        if (uid.isNotEmpty) {
          unawaited(GamificationFeedback.showBadgePopups(
            context: context,
            uid: uid,
            previousBadgeCounts: preBadges,
          ));
        }
      } else {
        // No review — show summary dialog, lalu badge popups (sambil screen
        // masih alive), baru pop. Awaited supaya popup tidak ke-skip karena
        // context invalid setelah Navigator.pop.
        await _showResultDialog(score, correct, total, passed);
        if (!mounted) return;
        if (uid.isNotEmpty) {
          await GamificationFeedback.showBadgePopups(
            context: context,
            uid: uid,
            previousBadgeCounts: preBadges,
          );
        }
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit quiz: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showAutoSubmitNotice() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.red, size: 26),
            SizedBox(width: 10),
            Text("Time's up!"),
          ],
        ),
        content: const Text(
          'Time limit reached. Your quiz was submitted automatically with the answers you had.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResultDialog(
    int score,
    int correct,
    int total,
    bool passed,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Quiz Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score: $score / 100',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text('Correct Answers: $correct out of $total'),
            const SizedBox(height: 8),
            Text(
              'Status: ${passed ? "Passed" : "Failed"}',
              style: TextStyle(
                color: passed ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      appBar: AppBar(
        title: Text(widget.quiz.title, style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1B20),
        elevation: 1,
        actions: [
          if (!_isReviewing)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _timerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _timerColor, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: _timerColor),
                      const SizedBox(width: 4),
                      Text(
                        _formattedTime,
                        style: TextStyle(
                          color: _timerColor,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<QuestionModel>>(
        stream: _questionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading questions: ${snapshot.error}'),
            );
          }

          _questions = snapshot.data ?? [];
          if (_questions.isEmpty) {
            return const Center(
              child: Text('No questions available in this quiz.'),
            );
          }

          if (_isReviewing) {
            return _buildReviewView();
          }

          return _buildAnsweringView();
        },
      ),
    );
  }

  Widget _buildAnsweringView() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: _questions.length + 1,
      itemBuilder: (context, index) {
        if (index == _questions.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isSubmitting ? null : () => _submitQuiz(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6F5AAA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Submit Quiz', style: TextStyle(fontSize: 16)),
              ),
            ),
          );
        }

        final q = _questions[index];
        return _buildQuestionCard(index: index, q: q, interactive: true);
      },
    );
  }

  Widget _buildReviewView() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: _questions.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildResultBanner();
        }
        if (index == _questions.length + 1) {
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

        final q = _questions[index - 1];
        return _buildQuestionCard(index: index - 1, q: q, interactive: false);
      },
    );
  }

  Widget _buildResultBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _passed ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _passed ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _passed ? Icons.check_circle : Icons.cancel,
                size: 28,
                color: _passed ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 10),
              Text(
                _passed ? 'Passed' : 'Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _passed ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Score: $_score / 100',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '$_correct / $_total correct  ·  Passing grade ${widget.quiz.passingGrade}%',
            style: const TextStyle(fontSize: 13, color: Color(0xFF49454E)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard({
    required int index,
    required QuestionModel q,
    required bool interactive,
  }) {
    final selected = _answers[q.id];
    final correctIndices = _correctAnswers[q.id] ?? const <int>[];

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
            if (interactive)
              RadioGroup<int>(
                groupValue: selected,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _answers[q.id] = val);
                  }
                },
                child: Column(
                  children: List.generate(
                    q.options.length,
                    (optIndex) => RadioListTile<int>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        q.options[optIndex].text,
                        style: const TextStyle(fontSize: 15),
                      ),
                      value: optIndex,
                    ),
                  ),
                ),
              )
            else
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
                      horizontal: 10,
                      vertical: 8,
                    ),
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
                              fontWeight: isCorrect
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
}
