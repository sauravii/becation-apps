import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/topic_model.dart';
import '../../services/topic_service.dart';
import '../../services/material_service.dart';
import '../../services/class_service.dart';

/// Bottom sheet untuk memilih create Topic atau Material.
void showAddOptionsSheet(
  BuildContext context, {
  required String classId,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Create',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1B20),
              ),
            ),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.only(left: 10, right: 10),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6F5AAA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.topic, color: Color(0xFF6F5AAA)),
            ),
            title: const Text(
              'Topic',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Create a new topic'),
            onTap: () {
              Navigator.pop(sheetContext);
              showAddTopicDialog(context, classId: classId);
            },
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6F5AAA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description, color: Color(0xFF6F5AAA)),
            ),
            title: const Text(
              'Material',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Add material to a topic'),
            onTap: () {
              Navigator.pop(sheetContext);
              showAddMaterialDialog(context, classId: classId);
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    ),
  );
}

/// Dialog untuk membuat topic baru.
void showAddTopicDialog(
  BuildContext context, {
  required String classId,
}) {
  final titleController = TextEditingController();
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Add Topic'),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: 'e.g. Chapter 1: Introduction',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6F5AAA)),
            ),
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
                      final count =
                          await TopicService.getTopicCount(classId);
                      await TopicService.createTopic(
                        classId: classId,
                        title: title,
                        order: count,
                      );

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Topic created!'),
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
                : const Text('Create'),
          ),
        ],
      ),
    ),
  );
}

/// Dialog untuk menambah material ke topic.
void showAddMaterialDialog(
  BuildContext context, {
  required String classId,
}) {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  String? selectedTopicId;
  String? selectedTopicTitle;
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Material',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1B20),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close, color: Color(0xFF49454F)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Material Title',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1B20),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter material title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF79747E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF6F5AAA)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1B20),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter material description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF79747E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF6F5AAA)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Topic',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1B20),
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<TopicModel>>(
                  stream: TopicService.topicsStream(classId),
                  builder: (context, snapshot) {
                    final topics = snapshot.data ?? [];

                    if (topics.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF79747E)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No topics yet. Create a topic first.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: selectedTopicId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF79747E)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF6F5AAA)),
                        ),
                      ),
                      hint: const Text('Select Topic'),
                      items: topics
                          .map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(
                                  t.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedTopicId = value;
                          selectedTopicTitle =
                              topics.firstWhere((t) => t.id == value).title;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF79747E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF49454F),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                if (title.isEmpty || selectedTopicId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Title and topic are required'),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() => isLoading = true);

                                try {
                                  await MaterialService.createMaterial(
                                    classId: classId,
                                    topicId: selectedTopicId!,
                                    topicTitle: selectedTopicTitle ?? '',
                                    title: title,
                                    description:
                                        descriptionController.text.trim(),
                                  );

                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Material added!'),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F5AAA),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                            : const Text(
                                'Add Material',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Dialog edit nama topic.
void showEditTopicDialog(
  BuildContext context, {
  required String classId,
  required TopicModel topic,
}) {
  final controller = TextEditingController(text: topic.title);
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Edit Topic'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Topic Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6F5AAA)),
            ),
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
                    final newTitle = controller.text.trim();
                    if (newTitle.isEmpty || newTitle == topic.title) {
                      Navigator.pop(dialogContext);
                      return;
                    }

                    setDialogState(() => isLoading = true);

                    try {
                      await TopicService.updateTopicTitle(
                        classId,
                        topic.id,
                        newTitle,
                      );
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

/// Dialog hapus topic dengan countdown 5 detik.
/// Menghapus topic beserta semua material di dalamnya.
void showDeleteTopicDialog(
  BuildContext context, {
  required String classId,
  required TopicModel topic,
  required int materialCount,
}) {
  int countdown = 5;
  Timer? timer;
  bool isDeleting = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
          if (countdown > 0) {
            setDialogState(() => countdown--);
          } else {
            t.cancel();
          }
        });

        final materialText = materialCount > 0
            ? '$materialCount material(s) inside will also be permanently deleted.'
            : 'This topic has no materials.';

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Delete Topic'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1C1B20),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'You are about to delete '),
                    TextSpan(
                      text: '"${topic.title}"',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: '. This action cannot be undone.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                materialText,
                style: TextStyle(
                  fontSize: 14,
                  color: materialCount > 0 ? Colors.red : Colors.grey,
                  fontWeight:
                      materialCount > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting
                  ? null
                  : () {
                      timer?.cancel();
                      Navigator.pop(dialogContext);
                    },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: (countdown > 0 || isDeleting)
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);

                      try {
                        await TopicService.deleteTopicWithMaterials(
                          classId,
                          topic.id,
                        );

                        timer?.cancel();
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Topic deleted'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isDeleting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: countdown > 0 ? Colors.grey : Colors.red,
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      countdown > 0 ? 'Delete ($countdown)' : 'Delete',
                    ),
            ),
          ],
        );
      },
    ),
  ).then((_) => timer?.cancel());
}

/// Dialog konfirmasi remove student yang tercentang.
void showRemoveStudentsDialog(
  BuildContext context, {
  required String classId,
  required List<String> selectedUids,
  required List<String> selectedNames,
  required VoidCallback onSuccess,
}) {
  if (selectedUids.isEmpty) return;

  final names = selectedNames.join(', ');

  showDialog(
    context: context,
    builder: (dialogContext) {
      bool isRemoving = false;

      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Remove Students'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remove ${selectedUids.length} student(s) from this class?',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              Text(
                names,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1B20),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isRemoving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isRemoving
                  ? null
                  : () async {
                      setDialogState(() => isRemoving = true);

                      try {
                        await ClassService.removeStudents(
                          classId,
                          selectedUids,
                        );

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        onSuccess();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${selectedUids.length} student(s) removed'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isRemoving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to remove: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: isRemoving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Remove'),
            ),
          ],
        ),
      );
    },
  );
}
