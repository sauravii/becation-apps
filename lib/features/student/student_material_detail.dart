import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/material_model.dart';
import '../../models/attachment_model.dart';
import '../../services/gamification_feedback.dart';
import '../../services/material_progress_service.dart';
import '../../services/material_service.dart';
import '../../services/attachment_service.dart';
import '../../components/cards/material_info_card.dart';
import '../../components/cards/attachment_section.dart';
import '../../components/cards/attachment_item.dart';

class StudentMaterialDetail extends StatefulWidget {
  final String classId;
  final String materialId;
  final String materialTitle;
  final String materialTimestamp;
  final String topicTitle;
  final Color topicColor;

  const StudentMaterialDetail({
    super.key,
    required this.classId,
    required this.materialId,
    required this.materialTitle,
    required this.materialTimestamp,
    required this.topicTitle,
    required this.topicColor,
  });

  @override
  State<StudentMaterialDetail> createState() => _StudentMaterialDetailState();
}

class _StudentMaterialDetailState extends State<StudentMaterialDetail> {
  MaterialModel? _material;
  bool _isLoading = true;
  late final Stream<List<AttachmentModel>> _attachmentsStream;

  @override
  void initState() {
    super.initState();
    _loadMaterial();
    _attachmentsStream = AttachmentService.attachmentsStream(
        widget.classId, widget.materialId);
  }

  Future<void> _loadMaterial() async {
    final material = await MaterialService.getMaterialApi(
        widget.classId, widget.materialId);
    if (mounted) {
      setState(() {
        _material = material;
        _isLoading = false;
      });
    }
  }

  // Fire-and-forget track attachment access ke backend. Backend bakal:
  //  - arrayUnion(attachmentId) ke material_completion
  //  - kalau semua attachment udah di-click → mark complete + award point
  // Show snackbar pas justCompleted + popup untuk setiap badge baru.
  void _trackAccess(String attachmentId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Capture badge state SEBELUM API call (untuk diff popup).
    final preBadges = uid.isEmpty
        ? const <String>{}
        : await GamificationFeedback.captureBefore(uid);

    try {
      final result = await MaterialProgressService.trackAttachmentAccess(
        classId: widget.classId,
        materialId: widget.materialId,
        attachmentId: attachmentId,
      );
      if (!mounted || !result.justCompleted) return;

      // Trigger gamification feedback — snackbar point + popup badge baru.
      // Sync API ini langsung return pointAwarded, jadi gak perlu polling
      // delay panjang — singkat aja.
      await GamificationFeedback.showDiffAfter(
        context: context,
        uid: uid,
        previousBadgeIds: preBadges,
        customSnackbarMessage:
            'Material completed! +${result.pointAwarded} points',
        waitFor: const Duration(milliseconds: 500),
      );
    } catch (e) {
      debugPrint('[material_progress] track failed: $e');
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
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
              widget.materialTitle,
              style: const TextStyle(
                color: Color(0xFF1C1B20),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final description = _material?.description ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MaterialInfoCard(
            materialTitle: widget.materialTitle,
            materialTimestamp: widget.materialTimestamp,
            description: description.isNotEmpty ? description : null,
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
                          onAccessed: () => _trackAccess(a.id),
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
}
