import 'package:flutter/material.dart';

import '../../services/class_service.dart';

class TeacherCreateClassScreen extends StatefulWidget {
  const TeacherCreateClassScreen({super.key});

  @override
  State<TeacherCreateClassScreen> createState() =>
      _TeacherCreateClassScreenState();
}

class _TeacherCreateClassScreenState extends State<TeacherCreateClassScreen> {
  static const _colorOptions = [
    0xFF6F5AAA,
    0xFF3A86FF,
    0xFFFF7B54,
    0xFF2ECC71,
    0xFFE74C3C,
    0xFFF39C12,
  ];

  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedColor = _colorOptions.first;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _subjectController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _subjectController.text.trim().isNotEmpty &&
      _titleController.text.trim().isNotEmpty &&
      !_isCreating;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Subject', required: true),
                    const SizedBox(height: 4),
                    _buildUnderlineField(
                      controller: _subjectController,
                      hint: 'e.g. Mathematics',
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Class Title', required: true),
                    const SizedBox(height: 4),
                    _buildUnderlineField(
                      controller: _titleController,
                      hint: 'e.g. Grade 10 - Algebra Basics',
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Description'),
                    const SizedBox(height: 4),
                    _buildUnderlineField(
                      controller: _descriptionController,
                      hint: 'Brief description of the class',
                      maxLines: null,
                    ),
                    const SizedBox(height: 28),
                    _buildLabel('Color'),
                    const SizedBox(height: 12),
                    _buildColorPicker(),
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
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2FA),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed:
                _isCreating ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1B20)),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Create class',
                style: TextStyle(
                  color: Color(0xFF1C1B20),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildCreateButton(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: _canCreate ? _submit : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _canCreate ? const Color(0xFF6F5AAA) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _isCreating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Create',
                style: TextStyle(
                  color: _canCreate ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
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
          color: Color(0xFF49454E),
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

  Widget _buildUnderlineField({
    required TextEditingController controller,
    required String hint,
    int? maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9A9499)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF79747E)),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF79747E)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF6F5AAA), width: 2),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Row(
      children: _colorOptions.map((colorVal) {
        final isSelected = _selectedColor == colorVal;
        return GestureDetector(
          onTap: _isCreating
              ? null
              : () => setState(() => _selectedColor = colorVal),
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Color(colorVal),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black, width: 2.5)
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final subject = _subjectController.text.trim();
    if (title.isEmpty || subject.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      await ClassService.createClassApi(
        title: title,
        subject: subject,
        description: _descriptionController.text.trim(),
        colorValue: _selectedColor,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Class created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create class: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
