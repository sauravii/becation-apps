import 'package:flutter/material.dart';

class PendingQuestion {
  final String type;
  final String question;
  final List<String> options;
  final int correctIndex;

  const PendingQuestion({
    required this.type,
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class TeacherCreateQuestionScreen extends StatefulWidget {
  final PendingQuestion? initial;

  const TeacherCreateQuestionScreen({super.key, this.initial});

  @override
  State<TeacherCreateQuestionScreen> createState() =>
      _TeacherCreateQuestionScreenState();
}

class _TeacherCreateQuestionScreenState
    extends State<TeacherCreateQuestionScreen> {
  static const _purple = Color(0xFF6F5AAA);
  static const _bg = Color(0xFFF7F2FA);
  static const _label = Color(0xFF49454E);
  static const _hint = Color(0xFF9A9499);
  static const _ink = Color(0xFF1C1B20);

  static const _types = ['Multiple Choice'];

  String _type = 'Multiple Choice';
  final _questionController = TextEditingController();
  late List<TextEditingController> _optionControllers;
  int _correctIndex = -1;

  @override
  void initState() {
    super.initState();

    final initial = widget.initial;
    if (initial != null) {
      _type = initial.type;
      _questionController.text = initial.question;
      _optionControllers = initial.options
          .map((s) => TextEditingController(text: s))
          .toList();
      _correctIndex = initial.correctIndex;
    } else {
      _optionControllers = [TextEditingController(), TextEditingController()];
    }

    _questionController.addListener(() => setState(() {}));
    for (final c in _optionControllers) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSave {
    if (_questionController.text.trim().isEmpty) return false;
    if (_optionControllers.length < 2) return false;
    if (_optionControllers.any((c) => c.text.trim().isEmpty)) return false;
    if (_correctIndex < 0 || _correctIndex >= _optionControllers.length) {
      return false;
    }
    return true;
  }

  void _addOption() {
    setState(() {
      final controller = TextEditingController();
      controller.addListener(() => setState(() {}));
      _optionControllers.add(controller);
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers.removeAt(index).dispose();
      if (_correctIndex == index) {
        _correctIndex = -1;
      } else if (_correctIndex > index) {
        _correctIndex--;
      }
    });
  }

  void _toggleCorrect(int index) {
    setState(() {
      _correctIndex = (_correctIndex == index) ? -1 : index;
    });
  }

  void _save() {
    if (!_canSave) return;
    final result = PendingQuestion(
      type: _type,
      question: _questionController.text.trim(),
      options: _optionControllers.map((c) => c.text.trim()).toList(),
      correctIndex: _correctIndex,
    );
    Navigator.of(context).pop(result);
  }

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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeCard(),
                    const SizedBox(height: 16),
                    _buildQuestionCard(),
                    const SizedBox(height: 16),
                    _buildLabel('Options', required: true),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap "Mark as answer" on the correct option.',
                      style: TextStyle(fontSize: 12, color: _label),
                    ),
                    const SizedBox(height: 12),
                    ..._optionControllers.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildOptionCard(entry.key),
                      ),
                    ),
                    _buildAddOptionButton(),
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
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: _ink),
          ),
          const Expanded(
            child: Text(
              'Create Question',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: _canSave ? _save : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: _canSave ? _purple : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  color: _canSave ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _label,
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

  Widget _buildTypeCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Question type', required: true),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _type,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: _label),
              style: const TextStyle(fontSize: 15, color: _ink),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Question', required: true),
          const SizedBox(height: 2),
          TextField(
            controller: _questionController,
            maxLines: null,
            minLines: 2,
            style: const TextStyle(fontSize: 15, color: _ink),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'e.g. What is the capital of France?',
              hintStyle: TextStyle(color: _hint),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
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
        ],
      ),
    );
  }

  Widget _buildOptionCard(int index) {
    final isCorrect = _correctIndex == index;
    final canDelete = _optionControllers.length > 2;
    final number = (index + 1).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect ? Colors.green.shade400 : const Color(0xFFEAE3F2),
          width: isCorrect ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? Colors.green.shade100
                      : const Color(0xFFEDE7F4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isCorrect ? Colors.green.shade800 : _label,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _optionControllers[index],
                  style: const TextStyle(fontSize: 15, color: _ink),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Option ${index + 1}',
                    hintStyle: const TextStyle(color: _hint),
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF79747E)),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF79747E)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: _purple, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMarkAsAnswerButton(index, isCorrect),
              const Spacer(),
              IconButton(
                onPressed: canDelete ? () => _removeOption(index) : null,
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: canDelete ? Colors.red.shade400 : Colors.grey.shade300,
                ),
                tooltip: canDelete ? 'Delete option' : 'Minimum 2 options',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarkAsAnswerButton(int index, bool isCorrect) {
    return GestureDetector(
      onTap: () => _toggleCorrect(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isCorrect ? Colors.green.shade500 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCorrect ? Colors.green.shade500 : _purple,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: isCorrect ? Colors.white : _purple,
            ),
            const SizedBox(width: 6),
            Text(
              isCorrect ? 'Marked as answer' : 'Mark as answer',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCorrect ? Colors.white : _purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOptionButton() {
    return InkWell(
      onTap: _addOption,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEAE3F2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 18, color: _ink),
            SizedBox(width: 8),
            Text(
              'Add another option',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
