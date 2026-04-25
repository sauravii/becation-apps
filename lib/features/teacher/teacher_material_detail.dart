import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/material_model.dart';
import '../../models/attachment_model.dart';
import '../../services/material_service.dart';
import '../../services/attachment_service.dart';
import '../../components/cards/material_info_card.dart';
import '../../components/cards/attachment_section.dart';
import '../../components/cards/attachment_item.dart';

class TeacherMaterialDetail extends StatefulWidget {
  final String classId;
  final String materialId;
  final String materialTitle;
  final String materialTimestamp;
  final String topicTitle;
  final Color topicColor;

  const TeacherMaterialDetail({
    super.key,
    required this.classId,
    required this.materialId,
    required this.materialTitle,
    required this.materialTimestamp,
    required this.topicTitle,
    required this.topicColor,
  });

  @override
  State<TeacherMaterialDetail> createState() => _TeacherMaterialDetailState();
}

class _TeacherMaterialDetailState extends State<TeacherMaterialDetail> {
  MaterialModel? _material;
  bool _isLoading = true;
  // Flag edit mode — saat aktif, munculkan icon edit di MaterialInfoCard
  // dan tombol hapus (X) di setiap attachment.
  bool _isEditing = false;
  late final Stream<List<AttachmentModel>> _attachmentsStream;

  // Judul dan deskripsi yang bisa berubah setelah di-edit.
  late String _currentTitle;
  late String _currentDescription;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.materialTitle;
    _currentDescription = '';
    _loadMaterial();
    _attachmentsStream = AttachmentService.attachmentsStream(
        widget.classId, widget.materialId);
  }

  Future<void> _loadMaterial() async {
    final material = await MaterialService.getMaterial(
        widget.classId, widget.materialId);
    if (mounted) {
      setState(() {
        _material = material;
        _currentDescription = material?.description ?? '';
        _isLoading = false;
      });
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'file':
      case 'pdf':
      case 'doc':
      case 'presentation':
        return Icons.insert_drive_file;
      case 'image':
        return Icons.image;
      case 'link':
      default:
        return Icons.link;
    }
  }

  // Tampilkan dialog edit untuk mengubah judul dan deskripsi material.
  void _showEditMaterialDialog() {
    final titleController = TextEditingController(text: _currentTitle);
    final descController = TextEditingController(text: _currentDescription);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      setDialogState(() => isLoading = true);

                      try {
                        await MaterialService.updateMaterial(
                          classId: widget.classId,
                          materialId: widget.materialId,
                          title: title,
                          description: descController.text.trim(),
                        );

                        if (mounted) {
                          setState(() {
                            _currentTitle = title;
                            _currentDescription = descController.text.trim();
                          });
                        }

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update: $e'),
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
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Tampilkan dialog konfirmasi hapus material.
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Material'),
        content: const Text(
          'Are you sure you want to delete this material? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await MaterialService.deleteMaterial(
                  widget.classId,
                  widget.materialId,
                );

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Material deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Update judul attachment di Firestore.
  Future<void> _editAttachmentTitle(AttachmentModel attachment, String newTitle) async {
    try {
      await AttachmentService.updateAttachmentTitle(
        widget.classId,
        widget.materialId,
        attachment.id,
        newTitle,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update title: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hapus satu attachment dengan konfirmasi.
  void _deleteAttachment(AttachmentModel attachment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Attachment'),
        content: Text('Delete "${attachment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await AttachmentService.deleteAttachment(
                  widget.classId,
                  widget.materialId,
                  attachment.id,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF7F2FA),
        body: SafeArea(
          child: Column(
            children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAttachmentDialog(context),
        backgroundColor: const Color(0xFF6F5AAA),
        child: const Icon(Icons.attach_file, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 20, top: 20, right: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1B20)),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.description_outlined,
            color: Color(0xFF1C1B20),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentTitle,
              style: const TextStyle(
                color: Color(0xFF1C1B20),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Saat edit mode: tampilkan tombol ceklis hijau untuk selesai editing.
          // Saat normal: tampilkan titik tiga dengan menu Edit & Delete.
          if (_isEditing)
            GestureDetector(
              onTap: () => setState(() => _isEditing = false),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1C1B20)),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    setState(() => _isEditing = true);
                    break;
                  case 'delete':
                    _showDeleteConfirmation();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: Color(0xFF1C1B20)),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MaterialInfoCard(
            materialTitle: _currentTitle,
            materialTimestamp: widget.materialTimestamp,
            description:
                _currentDescription.isNotEmpty ? _currentDescription : null,
            isEditing: _isEditing,
            onEdit: _showEditMaterialDialog,
          ),
          const SizedBox(height: 30),

          // Attachments dari Firestore
          StreamBuilder<List<AttachmentModel>>(
            stream: _attachmentsStream,
            builder: (context, snapshot) {
              final attachments = snapshot.data ?? [];

              return AttachmentSection(
                attachments: attachments
                    .map((a) => AttachmentItem(
                          title: a.title,
                          subtitle: a.formattedSubtitle,
                          icon: _getIconForType(a.type),
                          iconColor: widget.topicColor,
                          url: a.url,
                          type: a.type,
                          fileExtension: a.fileExtension,
                          onEditTitle: _isEditing
                              ? (newTitle) =>
                                  _editAttachmentTitle(a, newTitle)
                              : null,
                          onDelete:
                              _isEditing ? () => _deleteAttachment(a) : null,
                        ))
                    .toList(),
                topicColor: widget.topicColor,
              );
            },
          ),
        ],
      ),
    );
  }

  // Cek dan minta permission storage. Return true jika granted.
  Future<bool> _requestStoragePermission() async {
    PermissionStatus status;

    // Android 13+ pakai permission granular (photos, videos, dll).
    // Android 12 ke bawah pakai READ_EXTERNAL_STORAGE.
    if (Platform.isAndroid) {
      // Coba minta storage dulu, kalau permanently denied coba photos.
      status = await Permission.storage.request();
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
    } else {
      status = await Permission.storage.request();
    }

    if (status.isGranted || status.isLimited) {
      return true;
    }

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

  // Pilih file dari device menggunakan file_picker.
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

  // Pilih gambar dari device.
  Future<File?> _pickImage() async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) return null;

    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  void _showAddAttachmentDialog(BuildContext context) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    String selectedType = 'link';
    File? selectedFile;
    String? selectedFileName;
    bool isLoading = false;

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
                // Type selector
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'link',
                      child: Text('Link'),
                    ),
                    DropdownMenuItem(
                      value: 'file',
                      child: Text('File (docs, pptx, pdf)'),
                    ),
                    DropdownMenuItem(
                      value: 'image',
                      child: Text('Image'),
                    ),
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

                // Title
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

                // Link: URL field. File/Image: file picker button.
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
                              allowedExtensions: [
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
                              // Auto-fill title kalau masih kosong.
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
              onPressed:
                  isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      // Validasi: link butuh URL, file/image butuh file.
                      if (selectedType == 'link') {
                        if (urlController.text.trim().isEmpty) return;
                      } else {
                        if (selectedFile == null) return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        if (selectedType == 'link') {
                          await AttachmentService.addAttachment(
                            classId: widget.classId,
                            materialId: widget.materialId,
                            title: title,
                            type: 'link',
                            url: urlController.text.trim(),
                            fileSize: 'Web Link',
                          );
                        } else {
                          await AttachmentService.uploadFileAttachment(
                            classId: widget.classId,
                            materialId: widget.materialId,
                            title: title,
                            type: selectedType,
                            file: selectedFile!,
                            fileName: selectedFileName!,
                          );
                        }

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Attachment added!'),
                              backgroundColor: Colors.green,
                            ),
                          );
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
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
