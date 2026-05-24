import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewers/image_viewer_page.dart';

class AttachmentItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String? url;
  // Tipe attachment: 'link', 'image', 'file'. Menentukan cara buka file.
  final String type;
  // Extension file (misal 'pdf', 'pptx'). Untuk menentukan viewer yang tepat.
  final String fileExtension;
  final VoidCallback? onTap;
  // Callback saat user pilih "Edit Title" dari menu — parameter: judul baru.
  final ValueChanged<String>? onEditTitle;
  // Callback saat user pilih "Delete" dari menu.
  final VoidCallback? onDelete;
  // Callback fire-and-forget pas attachment di-akses (sebelum URL terbuka).
  // Dipakai student view untuk track progress completion ke backend.
  final VoidCallback? onAccessed;

  const AttachmentItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.url,
    this.type = 'link',
    this.fileExtension = '',
    this.onTap,
    this.onEditTitle,
    this.onDelete,
    this.onAccessed,
  });

  bool get _isEditing => onDelete != null || onEditTitle != null;

  // Buka attachment berdasarkan tipe:
  // - image → full screen viewer di dalam app (pinch-to-zoom)
  // - file / link → buka di browser (browser handle download + buka file)
  void _openAttachment(BuildContext context) {
    if (url == null || url!.isEmpty) return;

    // Fire-and-forget track sebelum buka — backend handle idempotency.
    onAccessed?.call();

    if (type == 'image') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageViewerPage(imageUrl: url!, title: title),
        ),
      );
      return;
    }

    // File dan link → buka di browser/app external.
    _openUrl(context);
  }

  Future<void> _openUrl(BuildContext context) async {
    var rawUrl = url!.trim();
    if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
      rawUrl = 'https://$rawUrl';
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  // Tampilkan bottom sheet dengan opsi Edit Title, Delete, Cancel.
  void _showEditMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF1C1B20)),
              title: const Text('Edit Title'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showEditTitleDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetContext);
                onDelete?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog untuk edit judul attachment.
  void _showEditTitleDialog(BuildContext context) {
    final controller = TextEditingController(text: title);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != title) {
                onEditTitle?.call(newTitle);
              }
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6F5AAA),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: _isEditing
            ? () => _showEditMenu(context)
            : (onTap ?? () => _openAttachment(context)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C1B20),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Icon titik tiga muncul saat edit mode aktif.
              if (_isEditing)
                const Icon(
                  Icons.more_vert,
                  color: Colors.grey,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
