import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/attachment_service.dart';
import '../../services/material_service.dart';
import 'teacher_select_topic_screen.dart';

class _PendingAttachment {
  final String title;
  final String type; // 'link', 'file', 'image'
  final String? url;
  final File? file;
  final String? fileName;

  _PendingAttachment({
    required this.title,
    required this.type,
    this.url,
    this.file,
    this.fileName,
  });
}

class TeacherCreateMaterialScreen extends StatefulWidget {
  final String classId;

  const TeacherCreateMaterialScreen({super.key, required this.classId});

  @override
  State<TeacherCreateMaterialScreen> createState() =>
      _TeacherCreateMaterialScreenState();
}

class _TeacherCreateMaterialScreenState
    extends State<TeacherCreateMaterialScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_PendingAttachment> _attachments = [];
  SelectedTopic? _topic;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canPost =>
      _titleController.text.trim().isNotEmpty &&
      _topic != null &&
      !_isPosting;

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
                    _buildLabel('Material title', required: true),
                    const SizedBox(height: 4),
                    _buildUnderlineField(
                      controller: _titleController,
                      hint: 'e.g. Chapter 1: Introduction',
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Description'),
                    const SizedBox(height: 4),
                    _buildUnderlineField(
                      controller: _descriptionController,
                      hint: 'e.g. Slides and reading list for week 1',
                      maxLines: null,
                    ),
                    const SizedBox(height: 28),
                    _buildLabel('Attachment'),
                    const SizedBox(height: 4),
                    _buildAttachmentsSection(),
                    const SizedBox(height: 24),
                    _buildLabel('Topic', required: true),
                    const SizedBox(height: 8),
                    _buildTopicSection(),
                  ],
                ),
              ),
            ),
          ],
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
                _isPosting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1B20)),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Create material',
                style: TextStyle(
                  color: Color(0xFF1C1B20),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildPostButton(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildPostButton() {
    return GestureDetector(
      onTap: _canPost ? _submit : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _canPost ? const Color(0xFF6F5AAA) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
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
                'Post',
                style: TextStyle(
                  color: _canPost ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
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

  Widget _buildAttachmentsSection() {
    if (_attachments.isEmpty) {
      return _buildAddAttachmentRow(label: 'Add attachment');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._attachments.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          return _buildAttachmentTile(a, () {
            setState(() => _attachments.removeAt(i));
          });
        }),
        const SizedBox(height: 4),
        _buildAddAttachmentRow(label: '+ Add attachment'),
      ],
    );
  }

  Widget _buildAddAttachmentRow({required String label}) {
    return InkWell(
      onTap: _isPosting ? null : _showAddAttachmentDialog,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.attachment, color: Color(0xFF6F5AAA)),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6F5AAA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentTile(_PendingAttachment a, VoidCallback onRemove) {
    final iconData = a.type == 'link'
        ? Icons.link
        : a.type == 'image'
            ? Icons.image_outlined
            : Icons.insert_drive_file_outlined;
    final displayName = a.type == 'link' ? a.title : (a.fileName ?? a.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(iconData, size: 20, color: const Color(0xFF6F5AAA)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _isPosting ? null : onRemove,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 18, color: Color(0xFF49454E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicSection() {
    if (_topic == null) {
      return InkWell(
        onTap: _isPosting ? null : _openSelectTopic,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Add topic',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6F5AAA),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  color: Color(0xFF1C1B20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isPosting
                    ? null
                    : () => setState(() => _topic = null),
                child: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final topic = _topic;
    if (title.isEmpty || topic == null || topic.id == null) return;

    setState(() => _isPosting = true);

    try {
      final materialId = await MaterialService.createMaterial(
        classId: widget.classId,
        topicId: topic.id!,
        topicTitle: topic.title ?? '',
        title: title,
        description: _descriptionController.text.trim(),
      );

      for (final a in _attachments) {
        if (a.type == 'link') {
          await AttachmentService.addAttachment(
            classId: widget.classId,
            materialId: materialId,
            title: a.title,
            type: 'link',
            url: a.url ?? '',
            fileSize: 'Web Link',
          );
        } else {
          await AttachmentService.uploadFileAttachment(
            classId: widget.classId,
            materialId: materialId,
            title: a.title,
            type: a.type,
            file: a.file!,
            fileName: a.fileName!,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material posted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===== Add attachment dialog =====

  Future<bool> _requestStoragePermission() async {
    PermissionStatus status;
    if (Platform.isAndroid) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
    } else {
      status = await Permission.storage.request();
    }

    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Storage permission denied. Please enable it in app settings.',
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission is required to pick files.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }

  Future<File?> _pickFile({List<String>? allowedExtensions}) async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) return null;

    final result = await FilePicker.platform.pickFiles(
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: allowedExtensions,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<File?> _pickImage() async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) return null;

    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  void _showAddAttachmentDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    String selectedType = 'link';
    File? selectedFile;
    String? selectedFileName;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Attachment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'link', child: Text('Link')),
                    DropdownMenuItem(
                      value: 'file',
                      child: Text('File (docs, pptx, pdf)'),
                    ),
                    DropdownMenuItem(value: 'image', child: Text('Image')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() {
                        selectedType = v;
                        selectedFile = null;
                        selectedFileName = null;
                        urlController.clear();
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: selectedType == 'link'
                        ? 'e.g. Reference Link'
                        : 'e.g. Chapter 1 Slides',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedType == 'link')
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: 'URL',
                      hintText: 'https://...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          File? file;
                          if (selectedType == 'image') {
                            file = await _pickImage();
                          } else {
                            file = await _pickFile(
                              allowedExtensions: const [
                                'pdf',
                                'doc',
                                'docx',
                                'ppt',
                                'pptx',
                                'xls',
                                'xlsx',
                                'txt',
                              ],
                            );
                          }

                          if (file != null) {
                            setDialogState(() {
                              selectedFile = file;
                              selectedFileName =
                                  file!.path.split('/').last.split('\\').last;
                              if (titleController.text.trim().isEmpty) {
                                titleController.text = selectedFileName!
                                    .replaceAll(RegExp(r'\.[^.]+$'), '');
                              }
                            });
                          }
                        },
                        icon: Icon(
                          selectedType == 'image'
                              ? Icons.image
                              : Icons.attach_file,
                          size: 20,
                        ),
                        label: Text(
                          selectedType == 'image'
                              ? 'Choose Image'
                              : 'Choose File',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6F5AAA),
                          side: const BorderSide(color: Color(0xFF6F5AAA)),
                        ),
                      ),
                      if (selectedFileName != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F0F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selectedType == 'image'
                                    ? Icons.image
                                    : Icons.insert_drive_file,
                                size: 18,
                                color: const Color(0xFF6F5AAA),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedFileName!,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                if (selectedType == 'link') {
                  final url = urlController.text.trim();
                  if (url.isEmpty) return;
                  setState(() {
                    _attachments.add(
                      _PendingAttachment(
                        title: title,
                        type: 'link',
                        url: url,
                      ),
                    );
                  });
                } else {
                  if (selectedFile == null || selectedFileName == null) return;
                  setState(() {
                    _attachments.add(
                      _PendingAttachment(
                        title: title,
                        type: selectedType,
                        file: selectedFile,
                        fileName: selectedFileName,
                      ),
                    );
                  });
                }

                Navigator.pop(dialogContext);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6F5AAA),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
