import 'package:flutter/material.dart';
import '../../models/topic_model.dart';
import '../../services/topic_service.dart';

class SelectedTopic {
  final String? id;
  final String? title;

  const SelectedTopic({this.id, this.title});
}

class TeacherSelectTopicScreen extends StatefulWidget {
  final String classId;
  final SelectedTopic? initial;

  const TeacherSelectTopicScreen({
    super.key,
    required this.classId,
    this.initial,
  });

  @override
  State<TeacherSelectTopicScreen> createState() =>
      _TeacherSelectTopicScreenState();
}

class _TeacherSelectTopicScreenState extends State<TeacherSelectTopicScreen> {
  String? _initialId;
  String? _selectedId;
  String? _selectedTitle;

  @override
  void initState() {
    super.initState();
    _initialId = widget.initial?.id;
    _selectedId = widget.initial?.id;
    _selectedTitle = widget.initial?.title;
  }

  bool get _canDone => _selectedId != null && _selectedId != _initialId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<List<TopicModel>>(
                stream: TopicService.topicsStream(widget.classId),
                builder: (context, snapshot) {
                  final topics = snapshot.data ?? [];
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildCreateNewTopicRow(),
                      const Divider(height: 1),
                      ...topics.map(
                        (t) => _buildRadioRow(
                          label: t.title,
                          selected: _selectedId == t.id,
                          onTap: () {
                            setState(() {
                              _selectedId = t.id;
                              _selectedTitle = t.title;
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
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
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1B20)),
          ),
          const Expanded(
            child: Text(
              'Select topic',
              style: TextStyle(
                color: Color(0xFF1C1B20),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildDoneButton(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildDoneButton() {
    final enabled = _canDone;
    return GestureDetector(
      onTap: enabled
          ? () {
              Navigator.of(context).pop(
                SelectedTopic(id: _selectedId, title: _selectedTitle),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF6F5AAA) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Done',
          style: TextStyle(
            color: enabled ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateNewTopicRow() {
    return InkWell(
      onTap: _showCreateTopicDialog,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.add, color: Color(0xFF6F5AAA)),
            SizedBox(width: 16),
            Text(
              'Create new topic',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6F5AAA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioRow({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFF6F5AAA) : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1C1B20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTopicDialog() {
    final controller = TextEditingController();
    String? errorText;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Create topic',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Topics group classworks under one category',
                  style: TextStyle(fontSize: 13, color: Color(0xFF49454E)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Topic name',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF49454E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF79747E)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF6F5AAA), width: 2),
                    ),
                    errorText: errorText,
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    isLoading ? null : () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF6F5AAA)),
                ),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final value = controller.text.trim();
                        if (value.isEmpty) {
                          setDialogState(() {
                            errorText = 'Topic name cannot be blank';
                          });
                          return;
                        }

                        setDialogState(() => isLoading = true);

                        try {
                          final count =
                              await TopicService.getTopicCount(widget.classId);
                          final newId = await TopicService.createTopic(
                            classId: widget.classId,
                            title: value,
                            order: count,
                          );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          if (mounted) {
                            setState(() {
                              _selectedId = newId;
                              _selectedTitle = value;
                            });
                          }
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6F5AAA),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}
