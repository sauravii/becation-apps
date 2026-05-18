import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/question_model.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';
import 'teacher_create_question_screen.dart';
import 'teacher_select_topic_screen.dart';

/// One row in the editor list. Either an existing question (id != null) or a
/// new draft (id == null). Both are fully editable. [dirty] tracks whether
/// an existing question's content was modified — only dirty existing rows get
/// rewritten on save (clean ones just get an order update).
class _EditableQuestion {
  final String? id;
  String type;
  String question;
  List<String> options;
  int correctIndex;
  bool dirty = false;

  _EditableQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  bool get isExisting => id != null;

  factory _EditableQuestion.fromExisting(QuestionModel q) {
    return _EditableQuestion(
      id: q.id,
      type: q.type,
      question: q.question,
      options: q.options.map((o) => o.text).toList(),
      correctIndex: q.options.indexWhere((o) => o.isCorrect),
    );
  }

  factory _EditableQuestion.fromDraft(PendingQuestion p) {
    return _EditableQuestion(
      id: null,
      type: _typeKeyFromDisplay(p.type),
      question: p.question,
      options: List.of(p.options),
      correctIndex: p.correctIndex,
    );
  }

  PendingQuestion toPending() {
    return PendingQuestion(
      type: _typeDisplayFromKey(type),
      question: question,
      options: List.of(options),
      correctIndex: correctIndex,
    );
  }

  /// Mutate from an editor result. Preserves [id]; sets [dirty]=true.
  void updateFromPending(PendingQuestion p) {
    type = _typeKeyFromDisplay(p.type);
    question = p.question;
    options = List.of(p.options);
    correctIndex = p.correctIndex;
    dirty = true;
  }
}

String _typeKeyFromDisplay(String display) {
  if (display == 'Multiple Choice') return 'multiple_choice';
  return display.toLowerCase().replaceAll(' ', '_');
}

String _typeDisplayFromKey(String key) {
  if (key == 'multiple_choice') return 'Multiple Choice';
  return key
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class TeacherEditQuizScreen extends StatefulWidget {
  final String classId;
  final QuizModel quiz;
  final List<QuestionModel> initialQuestions;

  const TeacherEditQuizScreen({
    super.key,
    required this.classId,
    required this.quiz,
    required this.initialQuestions,
  });

  @override
  State<TeacherEditQuizScreen> createState() => _TeacherEditQuizScreenState();
}

class _TeacherEditQuizScreenState extends State<TeacherEditQuizScreen> {
  static const _purple = Color(0xFF6F5AAA);
  static const _bg = Color(0xFFF7F2FA);
  static const _label = Color(0xFF49454E);
  static const _hint = Color(0xFF9A9499);
  static const _ink = Color(0xFF1C1B20);

  final _titleController = TextEditingController();
  final _scrollController = ScrollController();
  SelectedTopic? _topic;
  int? _timeLimit;
  int? _passingGrade;
  int _attemptLimit = 1;
  bool _showAnswer = true;
  final List<_EditableQuestion> _questions = [];
  late final Set<String> _initialIds;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();

    final q = widget.quiz;
    _titleController.text = q.title;
    _topic = SelectedTopic(id: q.topicId, title: q.topicTitle);
    _timeLimit = q.timeLimit;
    _passingGrade = q.passingGrade;
    _attemptLimit = q.attemptLimit;
    _showAnswer = q.showAnswer;

    _questions.addAll(
      widget.initialQuestions.map(_EditableQuestion.fromExisting),
    );
    _initialIds = widget.initialQuestions.map((e) => e.id).toSet();

    // Listener attached AFTER pre-fill so initial setText doesn't trip _hasChanges.
    _titleController.addListener(() {
      _hasChanges = true;
      setState(() {});
    });
  }

  void _markChanged() {
    _hasChanges = true;
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'Your unsaved edits to this quiz will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty &&
      _topic?.id != null &&
      _timeLimit != null &&
      _passingGrade != null &&
      _questions.isNotEmpty &&
      !_isSaving;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Block system back when there are unsaved changes (or save in flight).
      // Programmatic Navigator.pop() bypasses this, so post-save pop still works.
      canPop: !_hasChanges && !_isSaving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isSaving) return;
        final navigator = Navigator.of(context);
        final shouldDiscard = await _confirmDiscard();
        if (shouldDiscard && mounted) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleCard(),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTimeLimitCard()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildPassingGradeCard()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildAttemptLimitCard(),
                      const SizedBox(height: 16),
                      _buildShowAnswerToggle(),
                      const SizedBox(height: 20),
                      _buildQuestionsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(color: _bg),
      child: Row(
        children: [
          IconButton(
            onPressed: _isSaving ? null : () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: _ink),
          ),
          const Expanded(
            child: Text(
              'Edit Quiz',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSaveButton(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _canSave ? _save : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: _canSave ? _purple : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Save',
                style: TextStyle(
                  color: _canSave ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildLabel(
    String text, {
    bool required = false,
    Color color = _label,
    double size = 13,
    FontWeight weight = FontWeight.w600,
  }) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: size, fontWeight: weight, color: color),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]
            : const [],
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAE3F2)),
      ),
      child: child,
    );
  }

  Widget _buildTitleCard() {
    return _buildCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Quiz title', required: true),
          const SizedBox(height: 2),
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 15, color: _ink),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              hintStyle: TextStyle(color: _hint),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF79747E)),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF79747E)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _purple, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildTopicRow(),
        ],
      ),
    );
  }

  Widget _buildTopicRow() {
    if (_topic?.id == null) {
      return InkWell(
        onTap: _isSaving ? null : _openSelectTopic,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Add topic *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _purple,
              decoration: TextDecoration.underline,
              decorationColor: _purple,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: _isSaving ? null : _openSelectTopic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE7DFF8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _topic!.title ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _isSaving
                    ? null
                    : () {
                        setState(() => _topic = null);
                        _markChanged();
                      },
                child: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCapsLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _label,
          letterSpacing: 0.5,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]
            : const [],
      ),
    );
  }

  Widget _buildClickableValueRow({
    required int? value,
    required int placeholder,
    required String suffix,
  }) {
    final isSet = value != null;
    final displayValue = value ?? placeholder;
    final valueColor = isSet ? _ink : _hint;
    final suffixColor = isSet ? _label : _hint;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$displayValue',
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: isSet ? 20 : 18,
            fontWeight: isSet ? FontWeight.w700 : FontWeight.w600,
            color: valueColor,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          suffix,
          style: TextStyle(
            fontSize: isSet ? 13 : 12,
            color: suffixColor,
            fontWeight: isSet ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeLimitCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _isSaving ? null : _openTimeLimitDialog,
      child: _buildCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSmallCapsLabel('TIME LIMIT', required: true),
            const SizedBox(height: 6),
            _buildClickableValueRow(
              value: _timeLimit,
              placeholder: 60,
              suffix: 'mins',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassingGradeCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _isSaving ? null : _openPassingGradeDialog,
      child: _buildCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSmallCapsLabel('PASSING GRADE', required: true),
            const SizedBox(height: 6),
            _buildClickableValueRow(
              value: _passingGrade,
              placeholder: 70,
              suffix: '%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptLimitCard() {
    return _buildCard(
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ATTEMPT LIMIT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _label,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Max times a student can retake',
                  style: TextStyle(fontSize: 12, color: _label),
                ),
              ],
            ),
          ),
          _buildCounter(),
        ],
      ),
    );
  }

  Widget _buildCounter() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F4),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _counterButton(
            icon: Icons.remove,
            onTap: _attemptLimit > 1
                ? () {
                    setState(() => _attemptLimit--);
                    _markChanged();
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$_attemptLimit',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
          _counterButton(
            icon: Icons.add,
            onTap: _attemptLimit < 10
                ? () {
                    setState(() => _attemptLimit++);
                    _markChanged();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _counterButton({required IconData icon, VoidCallback? onTap}) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 18,
          color: disabled ? Colors.grey.shade400 : _ink,
        ),
      ),
    );
  }

  Widget _buildShowAnswerToggle() {
    return Row(
      children: [
        Transform.scale(
          scaleX: 0.9,
          scaleY: 0.85,
          child: Switch(
            value: _showAnswer,
            onChanged: _isSaving
                ? null
                : (v) {
                    setState(() => _showAnswer = v);
                    _markChanged();
                  },
            activeThumbColor: Colors.white,
            activeTrackColor: _purple,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'SHOW ANSWER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _label,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_questions.isNotEmpty) ...[
          Text(
            '${_questions.length} Question',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _questions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildQuestionCard(i, _questions[i]),
            ),
        ],
        _outlineActionButton(
          icon: Icons.add,
          label: 'Add question',
          onTap: _isSaving ? null : _onAddQuestion,
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int index, _EditableQuestion q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAE3F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${(index + 1).toString().padLeft(2, '0')}   ${_typeDisplayFromKey(q.type).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _label,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() => _questions.removeAt(index));
                        _markChanged();
                      },
                icon: const Icon(Icons.delete_outline, size: 20),
                color: _ink,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: _isSaving ? null : () => _onEditQuestion(index),
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: _ink,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              q.question,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...q.options.asMap().entries.map((e) {
            final isCorrect = e.key == q.correctIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      isCorrect ? Icons.check_circle : Icons.radio_button_off,
                      size: 18,
                      color: isCorrect ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(fontSize: 14, color: _ink),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _outlineActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEAE3F2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: disabled ? Colors.grey.shade400 : _ink,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: disabled ? Colors.grey.shade400 : _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Actions =====

  Future<void> _openSelectTopic() async {
    final result = await Navigator.of(context).push<SelectedTopic>(
      MaterialPageRoute(
        builder: (_) => TeacherSelectTopicScreen(
          classId: widget.classId,
          initial: _topic,
        ),
      ),
    );
    if (result != null) {
      setState(() => _topic = result);
      _markChanged();
    }
  }

  Future<void> _openTimeLimitDialog() async {
    final result = await _showIntDialog(
      title: 'Choose time limit',
      label: 'Time limit (minutes)',
      hint: '60',
      minValue: 1,
      maxValue: 1440,
    );
    if (result != null) {
      setState(() => _timeLimit = result);
      _markChanged();
    }
  }

  Future<void> _openPassingGradeDialog() async {
    final result = await _showIntDialog(
      title: 'Choose passing grade',
      label: 'Passing grade',
      hint: '70',
      maxValue: 100,
    );
    if (result != null) {
      setState(() => _passingGrade = result);
      _markChanged();
    }
  }

  Future<int?> _showIntDialog({
    required String title,
    required String label,
    required String hint,
    int? minValue,
    int? maxValue,
  }) {
    final controller = TextEditingController();
    String? errorText;

    return showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final hasError = errorText != null;
          final lineColor = hasError ? Colors.red : _purple;
          final labelColor = hasError ? Colors.red : _purple;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 16, color: _ink),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hint,
                    hintStyle: const TextStyle(color: _hint),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: lineColor, width: 1.5),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: lineColor, width: 2),
                    ),
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                  },
                ),
                if (hasError) ...[
                  const SizedBox(height: 6),
                  Text(
                    errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(foregroundColor: _purple),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () {
                  final raw = controller.text.trim();
                  if (raw.isEmpty) {
                    setDialogState(
                      () => errorText = 'This field cannot be blank',
                    );
                    return;
                  }
                  final parsed = int.tryParse(raw);
                  if (parsed == null) {
                    setDialogState(() => errorText = 'Must be a number');
                    return;
                  }
                  if (minValue != null && parsed < minValue) {
                    setDialogState(() => errorText = 'Min value is $minValue');
                    return;
                  }
                  if (maxValue != null && parsed > maxValue) {
                    setDialogState(() => errorText = 'Max value is $maxValue');
                    return;
                  }
                  Navigator.pop(dialogContext, parsed);
                },
                style: TextButton.styleFrom(foregroundColor: _ink),
                child: const Text(
                  'Confirm',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onAddQuestion() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await Navigator.of(context).push<PendingQuestion>(
      MaterialPageRoute(
        builder: (_) => const TeacherCreateQuestionScreen(lockType: true),
      ),
    );
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();

    if (result == null) return;
    setState(() => _questions.add(_EditableQuestion.fromDraft(result)));
    _markChanged();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      });
    });
  }

  Future<void> _onEditQuestion(int index) async {
    final q = _questions[index];

    FocusManager.instance.primaryFocus?.unfocus();

    final result = await Navigator.of(context).push<PendingQuestion>(
      MaterialPageRoute(
        builder: (_) => TeacherCreateQuestionScreen(
          initial: q.toPending(),
          lockType: true,
        ),
      ),
    );
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();

    if (result != null) {
      setState(() {
        if (q.isExisting) {
          // Mutate in place to preserve id; mark dirty so save rewrites it.
          q.updateFromPending(result);
        } else {
          // New draft: replace with fresh instance.
          _questions[index] = _EditableQuestion.fromDraft(result);
        }
      });
      _markChanged();
    }
  }

  QuizDraftQuestion _toDraft(_EditableQuestion q) {
    return QuizDraftQuestion(
      type: q.type,
      question: q.question,
      options: q.options
          .asMap()
          .entries
          .map(
            (e) => QuestionOption(
              text: e.value,
              isCorrect: e.key == q.correctIndex,
            ),
          )
          .toList(),
    );
  }

  Future<void> _save() async {
    if (!_canSave) return;

    final topic = _topic!;
    final timeLimit = _timeLimit!;
    final passingGrade = _passingGrade!;

    final kept = <QuizKeptQuestion>[];
    final newDrafts = <QuizDraftQuestion>[];
    for (final q in _questions) {
      if (q.isExisting) {
        kept.add(QuizKeptQuestion(
          id: q.id!,
          edited: q.dirty ? _toDraft(q) : null,
        ));
      } else {
        newDrafts.add(_toDraft(q));
      }
    }
    final keptIdSet = {for (final k in kept) k.id};
    final removedIds =
        _initialIds.where((id) => !keptIdSet.contains(id)).toList();

    setState(() => _isSaving = true);

    try {
      await QuizService.updateQuizFull(
        classId: widget.classId,
        quizId: widget.quiz.id,
        title: _titleController.text.trim(),
        topicId: topic.id ?? '',
        topicTitle: topic.title ?? '',
        timeLimit: timeLimit,
        passingGrade: passingGrade,
        attemptLimit: _attemptLimit,
        showAnswer: _showAnswer,
        keptOrdered: kept,
        removedQuestionIds: removedIds,
        newQuestions: newDrafts,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
