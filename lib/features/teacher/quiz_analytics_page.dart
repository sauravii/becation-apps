import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/question_model.dart';
import '../../services/quiz_analytics_service.dart';
import '../../services/quiz_service.dart';
import 'teacher_create_question_screen.dart';

class QuizAnalyticsPage extends StatefulWidget {
  final String classId;
  final String quizId;
  final String quizTitle;
  final int passingGrade;

  const QuizAnalyticsPage({
    super.key,
    required this.classId,
    required this.quizId,
    required this.quizTitle,
    required this.passingGrade,
  });

  @override
  State<QuizAnalyticsPage> createState() => _QuizAnalyticsPageState();
}

class _QuizAnalyticsPageState extends State<QuizAnalyticsPage>
    with SingleTickerProviderStateMixin {
  static const _purple = Color(0xFF6F5AAA);

  late final TabController _tabController;

  AnalyticsSummary? _summary;
  List<QuestionAnalytics>? _perQuestion;
  AttemptsPage? _attempts;

  bool _loadingSummary = true;
  bool _loadingPerQuestion = true;
  bool _loadingAttempts = true;

  String? _errorSummary;
  String? _errorPerQuestion;
  String? _errorAttempts;

  int _attemptsPage = 1;
  static const int _attemptsLimit = 20;
  String _attemptsSort = 'submittedAt';

  String _perQuestionFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadSummary();
    _loadPerQuestion();
    _loadAttempts();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loadingSummary = true;
      _errorSummary = null;
    });
    try {
      final result = await QuizAnalyticsService.fetchSummary(
        widget.classId,
        widget.quizId,
      );
      if (!mounted) return;
      setState(() {
        _summary = result;
        _loadingSummary = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorSummary = e.toString();
        _loadingSummary = false;
      });
    }
  }

  Future<void> _loadPerQuestion() async {
    setState(() {
      _loadingPerQuestion = true;
      _errorPerQuestion = null;
    });
    try {
      final result = await QuizAnalyticsService.fetchPerQuestion(
        widget.classId,
        widget.quizId,
      );

      try {
        final keys = await QuizService.fetchAnswerKeys(
          widget.classId,
          widget.quizId,
        );
        for (var q in result) {
          final indices = keys[q.questionId];
          if (indices != null && indices.isNotEmpty) {
            q.correctOptionIndex = indices.first;
          }
        }
      } catch (_) {
        // Silently ignore if we fail to fetch keys, we just won't show correct answers.
      }

      if (!mounted) return;
      setState(() {
        _perQuestion = result;
        _loadingPerQuestion = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorPerQuestion = e.toString();
        _loadingPerQuestion = false;
      });
    }
  }

  Future<void> _loadAttempts({int? page, String? sort}) async {
    setState(() {
      _loadingAttempts = true;
      _errorAttempts = null;
      if (page != null) _attemptsPage = page;
      if (sort != null) _attemptsSort = sort;
    });
    try {
      final result = await QuizAnalyticsService.fetchAttempts(
        widget.classId,
        widget.quizId,
        page: _attemptsPage,
        limit: _attemptsLimit,
        sort: _attemptsSort,
      );
      if (!mounted) return;
      setState(() {
        _attempts = result;
        _loadingAttempts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorAttempts = e.toString();
        _loadingAttempts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      appBar: AppBar(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        title: Text(
          widget.quizTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Per-Question'),
            Tab(text: 'Attempts'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSummaryTab(),
            _buildPerQuestionTab(),
            _buildAttemptsTab(),
          ],
        ),
      ),
    );
  }

  // ---- Summary tab ----

  Widget _buildSummaryTab() {
    if (_loadingSummary && _summary == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorSummary != null) {
      return _errorView(_errorSummary!, _loadSummary);
    }
    final s = _summary!;
    if (s.totalAttempts == 0) {
      return const _EmptyView(
        icon: Icons.bar_chart,
        message: 'No attempts for this quiz yet',
      );
    }

    QuestionAnalytics? easiestQuestion;
    QuestionAnalytics? hardestQuestion;

    if (_perQuestion != null && _perQuestion!.isNotEmpty) {
      final sortedQuestions = List<QuestionAnalytics>.from(_perQuestion!);
      sortedQuestions.sort((a, b) => a.correctRate.compareTo(b.correctRate));
      hardestQuestion = sortedQuestions.first;
      easiestQuestion = sortedQuestions.last;
    }

    final pendingStudents = s.totalStudents - s.uniqueParticipants;
    final passedAttempts = (s.totalAttempts * s.passRate).round();
    final failedAttempts = s.totalAttempts - passedAttempts;

    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _bigStat(
            'Participation Rate',
            '${s.uniqueParticipants} / ${s.totalStudents} Students',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statCard('Average Score', '${s.avgScore}')),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('Pass Rate', '${(s.passRate * 100).round()}%'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard('Lowest Score', '${s.minScore}')),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Highest Score', '${s.maxScore}')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard('Passing Grade', '${widget.passingGrade}')),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('Failed Attempts', '$failedAttempts'),
              ),
            ],
          ),
          if (pendingStudents > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade800),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$pendingStudents students have not taken this quiz yet.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle('Score Distribution'),
          const SizedBox(height: 8),
          _scoreDistributionChart(s.scoreDistribution),
          if (hardestQuestion != null && easiestQuestion != null) ...[
            const SizedBox(height: 24),
            _sectionTitle('Question Insights'),
            const SizedBox(height: 12),
            _insightCard(
              title: 'Most Missed Question',
              question: hardestQuestion.question,
              correctRate: hardestQuestion.correctRate,
              color: Colors.red.shade50,
              iconColor: Colors.red.shade700,
              icon: Icons.trending_down,
            ),
            const SizedBox(height: 12),
            _insightCard(
              title: 'Most Correctly Answered',
              question: easiestQuestion.question,
              correctRate: easiestQuestion.correctRate,
              color: Colors.green.shade50,
              iconColor: Colors.green.shade700,
              icon: Icons.trending_up,
            ),
          ],
        ],
      ),
    );
  }

  Widget _insightCard({
    required String title,
    required String question,
    required double correctRate,
    required Color color,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  'Correct: ${(correctRate * 100).round()}%',
                  style: TextStyle(
                    color: iconColor.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreDistributionChart(List<ScoreBucket> buckets) {
    final maxCount = buckets.fold<int>(0, (m, b) => b.count > m ? b.count : m);
    final yMax = (maxCount + 1).toDouble();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: yMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: _purple.withValues(alpha: 0.1), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= buckets.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      buckets[idx].bucket,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barGroups: [
            for (var i = 0; i < buckets.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: buckets[i].count.toDouble(),
                    color: _purple,
                    width: 24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ---- Per-question tab ----

  Widget _buildPerQuestionTab() {
    if (_loadingPerQuestion && _perQuestion == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorPerQuestion != null) {
      return _errorView(_errorPerQuestion!, _loadPerQuestion);
    }
    final qs = _perQuestion!;
    if (qs.isEmpty) {
      return const _EmptyView(
        icon: Icons.help_outline,
        message: 'This quiz has no questions yet',
      );
    }

    final sortedQs = List<QuestionAnalytics>.from(qs);
    sortedQs.sort((a, b) => a.correctRate.compareTo(b.correctRate));

    final filteredQs = sortedQs.where((q) {
      final correctPercent = (q.correctRate * 100).round();
      if (_perQuestionFilter == 'Needs Review (< 50%)') {
        return correctPercent < 50;
      } else if (_perQuestionFilter == '100% Correct') {
        return correctPercent == 100;
      }
      return true;
    }).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _filterChip('All'),
              const SizedBox(width: 8),
              _filterChip('Needs Review (< 50%)'),
              const SizedBox(width: 8),
              _filterChip('100% Correct'),
            ],
          ),
        ),
        Expanded(
          child: filteredQs.isEmpty
              ? const _EmptyView(
                  icon: Icons.filter_alt_off,
                  message: 'No questions match the selected filter',
                )
              : RefreshIndicator(
                  onRefresh: _loadPerQuestion,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filteredQs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final originalIndex = qs.indexOf(filteredQs[i]) + 1;
                      return _questionCard(filteredQs[i], originalIndex);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _perQuestionFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _perQuestionFilter = label;
          });
        }
      },
      selectedColor: _purple.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? _purple : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? _purple : Colors.grey.shade300,
      ),
    );
  }

  Future<void> _onEditQuestion(QuestionAnalytics q) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('quizzes')
          .doc(widget.quizId)
          .collection('questions')
          .doc(q.questionId)
          .get();

      if (!doc.exists) throw Exception('Question not found');
      
      final qModel = QuestionModel.fromFirestore(doc);
      final keys = await QuizService.fetchAnswerKeys(widget.classId, widget.quizId);
      final correctIndices = keys[q.questionId] ?? [];
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      final pending = PendingQuestion(
        type: 'Multiple Choice', 
        question: qModel.question,
        options: qModel.options.map((o) => o.text).toList(),
        correctIndex: correctIndices.isNotEmpty ? correctIndices.first : 0,
      );

      final result = await Navigator.of(context).push<PendingQuestion>(
        MaterialPageRoute(
          builder: (_) => TeacherCreateQuestionScreen(
            initial: pending,
            lockType: true,
          ),
        ),
      );

      if (result != null && mounted) {
        setState(() {
          _loadingPerQuestion = true;
        });
        
        await QuizService.updateSingleQuestion(
          classId: widget.classId,
          quizId: widget.quizId,
          questionId: q.questionId,
          edited: QuizDraftQuestion(
            type: 'multiple_choice',
            question: result.question,
            options: result.options.asMap().entries.map((e) => QuestionOption(
              text: e.value,
              isCorrect: e.key == result.correctIndex,
            )).toList(),
          ),
        );
        
        _loadPerQuestion();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Question updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load question: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _questionCard(QuestionAnalytics q, int number) {
    final correctPercent = (q.correctRate * 100).round();

    Color progressColor;
    if (correctPercent < 50) {
      progressColor = Colors.red.shade400;
    } else if (correctPercent < 80) {
      progressColor = Colors.amber.shade400;
    } else {
      progressColor = Colors.green.shade400;
    }

    OptionDistribution? mostChosenWrong;
    if (q.correctOptionIndex != null) {
      final wrongOptions = q.optionDistribution
          .where((o) => o.index != q.correctOptionIndex)
          .toList();
      if (wrongOptions.isNotEmpty) {
        wrongOptions.sort((a, b) => b.count.compareTo(a.count));
        if (wrongOptions.first.count > 0) {
          mostChosenWrong = wrongOptions.first;
        }
      }
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onEditQuestion(q),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Q$number. ${q.question}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade500),
                ],
              ),
              const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Correct Rate: $correctPercent%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (q.averageTimeSeconds != null)
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${q.averageTimeSeconds!.toStringAsFixed(1)}s avg time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: q.correctRate.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          if (mostChosenWrong != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Most Chosen Wrong: ${mostChosenWrong.text} (${mostChosenWrong.count} votes)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _optionDistributionDonut(q.optionDistribution, q.correctOptionIndex),
        ],
      ),
        ),
      ),
    );
  }

  Widget _optionDistributionDonut(
    List<OptionDistribution> options,
    int? correctOptionIndex,
  ) {
    final palette = <Color>[
      const Color(0xFF6F5AAA),
      const Color(0xFFFF7B54),
      const Color(0xFF4FB3BF),
      const Color(0xFFE8B647),
      const Color(0xFF9CCA52),
      const Color(0xFFE26D85),
    ];

    final totalCount = options.fold<int>(0, (sum, o) => sum + o.count);

    if (totalCount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: const Text(
          'No answers yet',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              startDegreeOffset: -90,
              sections: [
                for (var i = 0; i < options.length; i++)
                  if (options[i].count > 0)
                    PieChartSectionData(
                      value: options[i].count.toDouble(),
                      color: palette[i % palette.length],
                      title: '',
                      radius: 22,
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: palette[i % palette.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          options[i].text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: options[i].index == correctOptionIndex
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: options[i].index == correctOptionIndex
                                ? Colors.green.shade700
                                : null,
                          ),
                        ),
                      ),
                      if (options[i].index == correctOptionIndex)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green.shade600,
                          ),
                        ),
                      Text(
                        '${options[i].count} (${(options[i].percentage * 100).round()}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Attempts tab ----

  Widget _buildAttemptsTab() {
    if (_loadingAttempts && _attempts == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorAttempts != null) {
      return _errorView(_errorAttempts!, () => _loadAttempts());
    }
    final page = _attempts!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                '${page.total} attempts',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              const Text('Sort:', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _attemptsSort,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'submittedAt', child: Text('Newest')),
                  DropdownMenuItem(value: 'score', child: Text('Score')),
                ],
                onChanged: (v) {
                  if (v != null) _loadAttempts(page: 1, sort: v);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: page.items.isEmpty
              ? const _EmptyView(
                  icon: Icons.list_alt,
                  message: 'No attempts yet',
                )
              : RefreshIndicator(
                  onRefresh: () => _loadAttempts(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: page.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _attemptTile(page.items[i]),
                  ),
                ),
        ),
        _paginationBar(page),
      ],
    );
  }

  Future<void> _showAttemptDetails(AttemptItem a) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Attempt Details - ${a.studentName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('classes')
                          .doc(widget.classId)
                          .collection('quizzes')
                          .doc(widget.quizId)
                          .collection('attempts')
                          .doc(a.attemptId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                          return const Center(child: Text('Failed to load attempt details'));
                        }
                        
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        final questionSnapshot = data['questionSnapshot'] as List<dynamic>? ?? [];
                        final answers = data['answers'] as Map<String, dynamic>? ?? {};
                        
                        if (questionSnapshot.isEmpty) {
                          return const Center(child: Text('No questions found in this attempt'));
                        }
                        
                        return ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.all(16),
                          itemCount: questionSnapshot.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, i) {
                            final qData = questionSnapshot[i] as Map<String, dynamic>;
                            final qId = qData['id'] as String;
                            final questionText = qData['question'] as String? ?? '';
                            final options = qData['options'] as List<dynamic>? ?? [];
                            final correctIndices = List<int>.from(qData['correctIndices'] ?? []);
                            final studentAnswer = answers[qId] as int?;
                            
                            final isCorrect = studentAnswer != null && correctIndices.contains(studentAnswer);
                            
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        isCorrect ? Icons.check_circle : Icons.cancel,
                                        color: isCorrect ? Colors.green.shade600 : Colors.red.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Q${i+1}. $questionText',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...options.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final text = entry.value['text'] as String? ?? '';
                                    final isStudentChoice = idx == studentAnswer;
                                    final isRightAnswer = correctIndices.contains(idx);
                                    
                                    Color tileColor = Colors.transparent;
                                    Color borderColor = Colors.grey.shade300;
                                    if (isRightAnswer) {
                                      tileColor = Colors.green.shade100;
                                      borderColor = Colors.green.shade400;
                                    } else if (isStudentChoice && !isRightAnswer) {
                                      tileColor = Colors.red.shade100;
                                      borderColor = Colors.red.shade400;
                                    }
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: tileColor,
                                        border: Border.all(color: borderColor),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isStudentChoice ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                            size: 16,
                                            color: isStudentChoice ? _purple : Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
                                          if (isRightAnswer)
                                            Icon(Icons.check, size: 16, color: Colors.green.shade700),
                                          if (isStudentChoice && !isRightAnswer)
                                            Icon(Icons.close, size: 16, color: Colors.red.shade700),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _attemptTile(AttemptItem a) {
    final isPassed = a.passed || a.score >= widget.passingGrade;
    final dateStr = a.submittedAt == null
        ? '-'
        : DateFormat('d MMM yyyy · HH:mm').format(a.submittedAt!.toLocal());
    final correctInfo = a.total > 0 ? '${a.correct}/${a.total} correct' : '';
    final attemptLabel = a.attemptNumber > 1 ? 'Re-attempt #${a.attemptNumber}' : 'Attempt #1';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showAttemptDetails(a),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _purple.withValues(alpha: 0.15),
                child: Text(
                  a.studentName.isNotEmpty ? a.studentName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: _purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          a.studentName.isNotEmpty ? a.studentName : '(no name)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPassed
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isPassed
                                  ? Colors.green.shade200
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Text(
                            isPassed ? 'PASS' : 'FAIL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPassed
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$attemptLabel • $dateStr',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    if (correctInfo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        correctInfo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${a.score}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paginationBar(AttemptsPage page) {
    final canPrev = _attemptsPage > 1;
    final canNext = page.hasMore;
    // Extend white bar ke bottom edge layar tapi konten button (Prev/Next +
    // page label) di-inset sebanyak gesture navbar supaya tetap clickable.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: canPrev
                ? () => _loadAttempts(page: _attemptsPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Prev'),
          ),
          Text('Page $_attemptsPage', style: const TextStyle(fontSize: 13)),
          TextButton.icon(
            onPressed: canNext
                ? () => _loadAttempts(page: _attemptsPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }

  // ---- Shared widgets ----

  Widget _bigStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _purple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_turned_in, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1C1B20),
      ),
    );
  }

  Widget _errorView(String message, Future<void> Function() retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
