import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/question_model.dart';
import '../../services/quiz_service.dart';
import "teacher_ai_generate_screen.dart";
import "teacher_create_question_screen.dart";
import 'teacher_select_topic_screen.dart';

class TeacherCreateQuizScreen extends StatefulWidget {
  final String classId;

  const TeacherCreateQuizScreen({super.key, required this.classId});

  @override
  State<TeacherCreateQuizScreen> createState() =>
      _TeacherCreateQuizScreenState();
}

class _TeacherCreateQuizScreenState extends State<TeacherCreateQuizScreen> {
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
  final List<PendingQuestion> _questions = [];
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _canPublish =>
      _titleController.text.trim().isNotEmpty &&
      _topic != null &&
      _timeLimit != null &&
      _passingGrade != null &&
      _questions.isNotEmpty &&
      !_isPosting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(color: _bg),
      child: Row(
        children: [
          IconButton(
            onPressed: _isPosting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: _ink),
          ),
          const Expanded(
            child: Text(
              'Create Quiz',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildPublishButton(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildPublishButton() {
    return GestureDetector(
      onTap: _canPublish ? _publish : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: _canPublish ? _purple : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _isPosting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Publish',
                style: TextStyle(
                  color: _canPublish ? Colors.white : Colors.grey.shade600,
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
    if (_topic == null) {
      return InkWell(
        onTap: _isPosting ? null : _openSelectTopic,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: RichText(
            text: const TextSpan(
              text: 'Add topic',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _purple,
                decoration: TextDecoration.underline,
                decorationColor: _purple,
              ),
              children: [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: _isPosting ? null : _openSelectTopic,
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
                onTap: _isPosting ? null : () => setState(() => _topic = null),
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
    double valueWidth = 40,
  }) {
    final isSet = value != null;
    final displayValue = value ?? placeholder;
    final valueColor = isSet ? _ink : _hint;
    final suffixColor = isSet ? _label : _hint;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: valueWidth,
          child: Text(
            '$displayValue',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: isSet ? 20 : 18,
              fontWeight: isSet ? FontWeight.w700 : FontWeight.w600,
              color: valueColor,
            ),
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
      onTap: _isPosting ? null : _openTimeLimitDialog,
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
      onTap: _isPosting ? null : _openPassingGradeDialog,
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
                ? () => setState(() => _attemptLimit--)
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
            onTap: _attemptLimit < 99
                ? () => setState(() => _attemptLimit++)
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
            onChanged: _isPosting
                ? null
                : (v) => setState(() => _showAnswer = v),
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
    final hasQuestions = _questions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasQuestions) ...[
          Text(
            '${_questions.length} Question',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _questions.length,
            onReorder: _onReorderQuestions,
            proxyDecorator: (child, index, animation) =>
                Material(color: Colors.transparent, child: child),
            itemBuilder: (context, index) => Padding(
              key: ObjectKey(_questions[index]),
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildQuestionCard(index, _questions[index]),
            ),
          ),
          _outlineActionButton(
            icon: Icons.add,
            label: 'Create question',
            onTap: _isPosting ? null : _onCreateQuestion,
          ),
        ] else
          _outlineActionButton(
            icon: Icons.add,
            label: 'Create question',
            onTap: _isPosting ? null : _onCreateQuestion,
          ),
        const SizedBox(height: 16),
        _buildOrDivider(),
        const SizedBox(height: 16),
        _outlineActionButton(
          iconWidget: const Icon(Icons.auto_awesome, size: 18, color: _ink),
          label: 'Generate with AI',
          onTap: _isPosting ? null : _onGenerateWithAI,
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int index, PendingQuestion q) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
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
                      '${(index + 1).toString().padLeft(2, '0')}   ${q.type.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _label,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isPosting
                        ? null
                        : () => setState(() => _questions.removeAt(index)),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: _ink,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: _isPosting ? null : () => _onEditQuestion(index),
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
        ),
        Positioned(
          top: -10,
          left: 0,
          right: 0,
          child: Center(
            child: ReorderableDragStartListener(
              index: index,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFEAE3F2)),
                  ),
                  child: const Icon(Icons.drag_handle, size: 14, color: _label),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onReorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, item);
    });
  }

  Widget _outlineActionButton({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    VoidCallback? onTap,
    bool compact = false,
  }) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: compact ? null : double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16,
          vertical: compact ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEAE3F2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            iconWidget ??
                Icon(
                  icon,
                  size: 18,
                  color: disabled ? Colors.grey.shade400 : _ink,
                ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w500,
                color: disabled ? Colors.grey.shade400 : _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFCAC4CF), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFCAC4CF), thickness: 1)),
      ],
    );
  }

  // ===== Actions =====

  Future<void> _openSelectTopic() async {
    final result = await Navigator.of(context).push<SelectedTopic>(
      MaterialPageRoute(
        builder: (_) =>
            TeacherSelectTopicScreen(classId: widget.classId, initial: _topic),
      ),
    );
    if (result != null) {
      setState(() => _topic = result);
    }
  }

  Future<void> _openTimeLimitDialog() async {
    final result = await _showIntDialog(
      title: 'Choose time limit',
      label: 'Time limit',
      hint: '60',
    );
    if (result != null) {
      setState(() => _timeLimit = result);
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
    }
  }

  Future<int?> _showIntDialog({
    required String title,
    required String label,
    required String hint,
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

  Future<void> _onCreateQuestion() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await Navigator.of(context).push<PendingQuestion>(
      MaterialPageRoute(builder: (_) => const TeacherCreateQuestionScreen()),
    );
    if (!mounted) return;

    // Defeat Flutter's focus restoration after pop — without this, the
    // title TextField regains focus and auto-scrolls itself into view,
    // racing with our animateTo to the new question.
    FocusManager.instance.primaryFocus?.unfocus();

    if (result == null) return;
    setState(() => _questions.add(result));

    // Two frames: first lets the new card lay out (ReorderableListView
    // shrinkwrap), second computes the correct maxScrollExtent.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Re-assert unfocus in case anything tries to take focus back.
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
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await Navigator.of(context).push<PendingQuestion>(
      MaterialPageRoute(
        builder: (_) => TeacherCreateQuestionScreen(initial: _questions[index]),
      ),
    );
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();

    if (result != null) {
      setState(() => _questions[index] = result);
    }
  }

  Future<void> _onGenerateWithAI() async {
    final result = await Navigator.of(context).push<List<PendingQuestion>>(
      MaterialPageRoute(
        builder: (_) => const TeacherAiGenerateScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _questions.addAll(result);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${result.length} questions generated by AI!"),
          backgroundColor: Colors.green,
        ),
      );

      // Scroll ke bawah untuk melihat soal baru
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _publish() async {
    if (!_canPublish) return;

    final topic = _topic!;
    final timeLimit = _timeLimit!;
    final passingGrade = _passingGrade!;

    setState(() => _isPosting = true);

    try {
      final drafts = _questions
          .map(
            (q) => QuizDraftQuestion(
              type: _questionTypeKey(q.type),
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
            ),
          )
          .toList();

      await QuizService.createQuiz(
        classId: widget.classId,
        title: _titleController.text.trim(),
        topicId: topic.id ?? '',
        topicTitle: topic.title ?? '',
        timeLimit: timeLimit,
        passingGrade: passingGrade,
        attemptLimit: _attemptLimit,
        showAnswer: _showAnswer,
        questions: drafts,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz published!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _questionTypeKey(String displayType) {
    switch (displayType) {
      case 'Multiple Choice':
        return 'multiple_choice';
      default:
        return displayType.toLowerCase().replaceAll(' ', '_');
    }
  }
}
