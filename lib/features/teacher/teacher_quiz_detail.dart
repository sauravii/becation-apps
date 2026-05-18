import 'package:flutter/material.dart';

import '../../models/question_model.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';
import 'quiz_analytics_page.dart';
import 'teacher_classes_dialogs.dart';
import 'teacher_edit_quiz_screen.dart';

enum _QuizMenuAction { edit, delete }

class TeacherQuizDetail extends StatefulWidget {
  final String classId;
  final String quizId;
  final Color classColor;

  const TeacherQuizDetail({
    super.key,
    required this.classId,
    required this.quizId,
    required this.classColor,
  });

  @override
  State<TeacherQuizDetail> createState() => _TeacherQuizDetailState();
}

class _TeacherQuizDetailState extends State<TeacherQuizDetail> {
  static const _bg = Color(0xFFF7F2FA);
  static const _label = Color(0xFF49454E);
  static const _ink = Color(0xFF1C1B20);

  late final Stream<QuizModel?> _quizStream;
  late final Stream<List<QuestionModel>> _questionsStream;
  Map<String, List<int>> _answerKeys = {};
  bool _loadingKeys = true;

  @override
  void initState() {
    super.initState();
    _quizStream = QuizService.quizStream(widget.classId, widget.quizId);
    _questionsStream =
        QuizService.questionsStream(widget.classId, widget.quizId);
    _fetchAnswerKeys();
  }

  Future<void> _fetchAnswerKeys() async {
    try {
      final keys = await QuizService.fetchAnswerKeys(
        widget.classId,
        widget.quizId,
      );
      if (!mounted) return;
      setState(() {
        _answerKeys = keys;
        _loadingKeys = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingKeys = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<QuizModel?>(
          stream: _quizStream,
          builder: (context, quizSnap) {
            final quiz = quizSnap.data;
            return Column(
              children: [
                _buildHeader(quiz),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (quizSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (quiz == null) {
                        return const Center(
                          child: Text(
                            'Quiz not found or has been deleted.',
                            style: TextStyle(color: _label),
                          ),
                        );
                      }
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBanner(quiz),
                            const SizedBox(height: 16),
                            _buildMetadataRow(quiz),
                            const SizedBox(height: 24),
                            _buildQuestionsHeader(quiz),
                            const SizedBox(height: 12),
                            _buildQuestionsList(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(QuizModel? quiz) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: _ink),
          ),
          const Expanded(
            child: Text(
              'Quiz',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (quiz != null) _buildAnalyticsCapsule(quiz),
          if (quiz != null) _buildOverflowMenu(quiz),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCapsule(QuizModel quiz) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuizAnalyticsPage(
                  classId: widget.classId,
                  quizId: widget.quizId,
                  quizTitle: quiz.title,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9D6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF7B54),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights, size: 16, color: Color(0xFFFF7B54)),
                SizedBox(width: 6),
                Text(
                  'Analytics',
                  style: TextStyle(
                    color: Color(0xFFFF7B54),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverflowMenu(QuizModel quiz) {
    return PopupMenuButton<_QuizMenuAction>(
      icon: const Icon(Icons.more_vert, color: _ink),
      onSelected: (action) => _onMenuSelected(action, quiz),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _QuizMenuAction.edit,
          child: Row(
            children: const [
              Icon(Icons.edit_outlined, size: 20, color: _ink),
              SizedBox(width: 12),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _QuizMenuAction.delete,
          child: Row(
            children: const [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onMenuSelected(
    _QuizMenuAction action,
    QuizModel quiz,
  ) async {
    switch (action) {
      case _QuizMenuAction.edit:
        await _onEditPressed(quiz);
        break;
      case _QuizMenuAction.delete:
        await _onDeletePressed(quiz);
        break;
    }
  }

  Future<void> _onEditPressed(QuizModel quiz) async {
    // Need answer_keys merged into questions so the editor knows the correct
    // option for each existing question. _answerKeys is already loaded in
    // initState; if it's still loading, fetch now.
    Map<String, List<int>> keys = _answerKeys;
    if (_loadingKeys) {
      try {
        keys = await QuizService.fetchAnswerKeys(
          widget.classId,
          widget.quizId,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load answers: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final questions = await QuizService.questionsStream(
      widget.classId,
      widget.quizId,
    ).first;
    if (!mounted) return;

    final merged = [
      for (final q in questions) q.withAnswers(keys[q.id] ?? const []),
    ];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeacherEditQuizScreen(
          classId: widget.classId,
          quiz: quiz,
          initialQuestions: merged,
        ),
      ),
    );
  }

  Future<void> _onDeletePressed(QuizModel quiz) async {
    int attemptCount = 0;
    try {
      attemptCount = await QuizService.getTotalAttemptsCount(
        widget.classId,
        widget.quizId,
      );
    } catch (_) {
      // Non-fatal — fall through with 0; the dialog still works.
    }
    if (!mounted) return;

    showDeleteQuizDialog(
      context,
      classId: widget.classId,
      quizId: widget.quizId,
      quizTitle: quiz.title,
      attemptCount: attemptCount,
      onDeleted: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  Widget _buildBanner(QuizModel quiz) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE7DFF8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quiz.topicTitle.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.classColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                quiz.topicTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (quiz.topicTitle.isNotEmpty) const SizedBox(height: 12),
          Text(
            quiz.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(QuizModel quiz) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'TIME LIMIT',
            value: '${quiz.timeLimit}',
            suffix: 'mins',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'PASSING GRADE',
            value: '${quiz.passingGrade}',
            suffix: '%',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'ATTEMPTS',
            value: '${quiz.attemptLimit}',
            suffix: 'max',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String suffix,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAE3F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _label,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  suffix,
                  style: const TextStyle(fontSize: 11, color: _label),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsHeader(QuizModel quiz) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${quiz.questionCount} Question',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              quiz.showAnswer
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 16,
              color: _label,
            ),
            const SizedBox(width: 6),
            Text(
              'Show answer: ${quiz.showAnswer ? 'ON' : 'OFF'}',
              style: const TextStyle(fontSize: 12, color: _label),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionsList() {
    return StreamBuilder<List<QuestionModel>>(
      stream: _questionsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting || _loadingKeys) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final questions = snap.data ?? [];
        if (questions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'This quiz has no questions.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < questions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildQuestionCard(
                  i,
                  questions[i].withAnswers(
                    _answerKeys[questions[i].id] ?? const [],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionCard(int index, QuestionModel q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAE3F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${(index + 1).toString().padLeft(2, '0')}   ${_typeLabel(q.type)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _label,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            q.question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 10),
          ...q.options.asMap().entries.map((e) {
            final isCorrect = e.value.isCorrect;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      isCorrect
                          ? Icons.check_circle
                          : Icons.radio_button_off,
                      size: 18,
                      color: isCorrect ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: _ink,
                        fontWeight:
                            isCorrect ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'MULTIPLE CHOICE';
      default:
        return type.toUpperCase().replaceAll('_', ' ');
    }
  }
}
