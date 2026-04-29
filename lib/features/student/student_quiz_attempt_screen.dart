import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../models/question_model.dart';
import '../../models/quiz_model.dart';
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
  static const _primary = Color(0xFF5E4B8B);
  static const _bg = Color(0xFFF7F2FA);

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

      setState(() {
        _isSubmitting = false;
        _isReviewing = true;
        _correctAnswers = correctAnswers;
        _score = score;
        _correct = correct;
        _total = total;
        _passed = passed;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: StreamBuilder<List<QuestionModel>>(
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

                  if (_currentIndex >= _questions.length) {
                    _currentIndex = 0;
                  }

                  if (_isReviewing) {
                    return _buildReviewView();
                  }

                  return _buildAnsweringView();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(color: _primary),
      child: Row(
        children: [
          IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              widget.quiz.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Opacity(
            opacity: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, size: 14, color: _timerColor),
                  const SizedBox(width: 6),
                  Text(
                    _formattedTime,
                    style: TextStyle(
                      color: _timerColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnsweringView() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          _buildAttemptInfoCard(showStats: false),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _questions.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final q = _questions[index];
                return _buildQuestionCard(
                  index: index,
                  q: q,
                  interactive: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _questions.length - 1;
    if (isFirst) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: constraints.maxWidth / 2,
              child: FilledButton(
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6F5AAA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Next', style: TextStyle(fontSize: 14)),
              ),
            ),
          );
        },
      );
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
              foregroundColor: const Color(0xFF6F5AAA),
              side: const BorderSide(color: Color(0xFF6F5AAA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Previous', style: TextStyle(fontSize: 14)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: isLast
                ? (_isSubmitting ? null : () => _submitQuiz())
                : () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6F5AAA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isLast ? 'Submit' : 'Next',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
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
      itemCount: _questions.length + 3,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildResultBanner();
        }
        if (index == 1) {
          return _buildAttemptInfoCard(showStats: widget.quiz.showAnswer);
        }
        if (index == _questions.length + 2) {
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

        final q = _questions[index - 2];
        return _buildQuestionCard(index: index - 2, q: q, interactive: false);
      },
    );
  }

  Widget _buildAttemptInfoCard({bool showStats = true}) {
    final answered = _answers.length;
    final remaining = (_questions.length - answered).clamp(
      0,
      _questions.length,
    );
    final wrong = (_total - _correct).clamp(0, _total);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  'Question ${_currentIndex + 1}/${_questions.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1B20),
                  ),
                ),
              ],
            ),
          ),
          if (showStats) ...[
            _buildMiniStat(
              icon: Icons.check_circle,
              color: const Color(0xFF58B368),
              value: '${widget.quiz.showAnswer ? _correct : answered}',
            ),
            const SizedBox(width: 6),
            _buildMiniStat(
              icon: Icons.cancel,
              color: const Color(0xFFE06B6B),
              value: '${widget.quiz.showAnswer ? wrong : remaining}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required Color color,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 12,
          ),
        ),
      ],
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
    final showStatus = _isReviewing && widget.quiz.showAnswer;

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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4DDEE)),
            ),
            child: Text(
              q.question,
              style: const TextStyle(
                fontSize: 14,
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
                onTap: interactive
                    ? () => setState(() => _answers[q.id] = optIndex)
                    : null,
              );
            }),
          ),
          if (interactive) ...[const SizedBox(height: 24), _buildNavButtons()],
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
    VoidCallback? onTap,
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
      ),
    );
  }
}
