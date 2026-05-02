import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../models/question_model.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';
import 'student_quiz_result_screen.dart';

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
  final PageController _pageController = PageController();

  List<QuestionModel> _questions = [];
  int _currentIndex = 0;
  bool _isSubmitting = false;

  // Map of questionId -> selected option index
  final Map<String, int> _answers = {};

  // Countdown timer
  Timer? _timer;
  late int _remainingSeconds;
  bool _autoSubmitted = false;

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
    _pageController.dispose();
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
        if (!_isSubmitting) {
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

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('submitQuizAttempt')
          .call({
            'classId': widget.classId,
            'quizId': widget.quiz.id,
            'answers': _answers,
          });

      if (!mounted) return;

      _timer?.cancel();
      final rawData = result.data as Map;
      final data = Map<String, dynamic>.from(rawData);
      final score = (data['score'] as num?)?.toInt() ?? 0;
      final correct = (data['correct'] as num?)?.toInt() ?? 0;
      final total = (data['total'] as num?)?.toInt() ?? 0;
      final passed = data['passed'] as bool? ?? false;
      final attemptNumber = (data['attemptNumber'] as num?)?.toInt() ?? 1;

      // Parse correctAnswers if function returned them (showAnswer == true)
      final Map<String, List<int>> correctAnswers = {};
      final rawCorrect = data['correctAnswers'];
      if (rawCorrect is Map) {
        rawCorrect.forEach((k, v) {
          if (v is List) {
            correctAnswers[k.toString()] = v
                .whereType<num>()
                .map((n) => n.toInt())
                .toList();
          }
        });
      }

      if (_autoSubmitted) {
        await _showAutoSubmitNotice();
        if (!mounted) return;
      }

      // Replace this screen with the result screen so back from result goes
      // straight to whatever was below us (quiz detail), not back to the
      // answering view.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StudentQuizResultScreen(
            quiz: widget.quiz,
            questions: _questions,
            userAnswers: Map.of(_answers),
            correctAnswers: correctAnswers,
            score: score,
            correct: correct,
            total: total,
            passed: passed,
            isFinalAttempt: attemptNumber >= widget.quiz.attemptLimit,
          ),
        ),
      );
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

  Future<bool> _confirmSubmitAndExit() async {
    final unanswered = _questions.length - _answers.length;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 26),
            SizedBox(width: 10),
            Text('Submit & exit?'),
          ],
        ),
        content: Text(
          unanswered > 0
              ? "Leaving now will submit your quiz. $unanswered question(s) will be marked as unanswered."
              : 'Leaving now will submit your quiz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep working'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Submit & exit'),
          ),
        ],
      ),
    );
    return result ?? false;
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
            'Time limit reached. Your quiz was submitted automatically with the answers you had.'),
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
    return PopScope(
      // Always intercept while on this screen — answering or submitting.
      // After successful submit we pushReplacement to the result screen,
      // which doesn't go through this PopScope, so no special exit case.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isSubmitting) return;
        final shouldSubmit = await _confirmSubmitAndExit();
        if (!mounted || !shouldSubmit) return;
        await _submitQuiz(skipIncompleteWarning: true);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F2FA),
        appBar: AppBar(
          title: Text(widget.quiz.title, style: const TextStyle(fontSize: 18, color: Colors.white)),
          backgroundColor: const Color(0xFF6F5AAA),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _remainingSeconds <= 60 ? Colors.red : const Color(0xFF6F5AAA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _formattedTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
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
                  child: Text('Error loading questions: ${snapshot.error}'));
            }

            _questions = snapshot.data ?? [];
            if (_questions.isEmpty) {
              return const Center(
                  child: Text('No questions available in this quiz.'));
            }

            return _buildAnsweringView();
          },
        ),
      ),
    );
  }

  Widget _buildAnsweringView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFF6F5AAA),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Question ${_currentIndex + 1}/${_questions.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1B20),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _questions.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final q = _questions[index];
                return _buildQuestionCard(
                  index: index,
                  q: q,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavButtonsFor(int index) {
    final isFirst = index == 0;
    final isLast = index == _questions.length - 1;

    final nextOrSubmitButton = FilledButton(
      onPressed: () {
        if (isLast) {
          _submitQuiz();
        } else {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      },
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF6F5AAA),
        minimumSize: const Size(200, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isSubmitting && isLast
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(isLast ? 'Submit' : 'Next', style: const TextStyle(fontSize: 16)),
    );

    if (isFirst) {
      return Center(child: nextOrSubmitButton);
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFF6F5AAA)),
            ),
            child: const Text('Previous', style: TextStyle(color: Color(0xFF6F5AAA), fontSize: 16)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: nextOrSubmitButton,
        ),
      ],
    );
  }

  Widget _buildQuestionCard({required int index, required QuestionModel q}) {
    final selected = _answers[q.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 24), // Increased gap between question and options
            Column(
              children: List.generate(
                q.options.length,
                (optIndex) {
                  final isSelected = selected == optIndex;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6F5AAA).withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6F5AAA) : const Color(0xFFE4DDEE),
                        width: isSelected ? 1.5 : 1.5,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() => _answers[q.id] = optIndex);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? const Color(0xFF6F5AAA) 
                                    : const Color(0xFF6F5AAA).withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                String.fromCharCode(65 + optIndex),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                q.options[optIndex].text,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF49454E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            _buildNavButtonsFor(index),
          ],
        ),
      ),
    );
  }
}
