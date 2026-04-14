import 'package:flutter/material.dart';
import '../../components/cards/material_info_card.dart';
import '../../components/cards/attachment_section.dart';
import '../../components/cards/attachment_item.dart';

class StudentMaterialDetail extends StatefulWidget {
  final String materialTitle;
  final String materialTimestamp;
  final String topicTitle;
  final Color topicColor;

  const StudentMaterialDetail({
    super.key,
    required this.materialTitle,
    required this.materialTimestamp,
    required this.topicTitle,
    required this.topicColor,
  });

  @override
  State<StudentMaterialDetail> createState() => _StudentMaterialDetailState();
}

class _StudentMaterialDetailState extends State<StudentMaterialDetail> {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Material Info Card
          MaterialInfoCard(
            materialTitle: widget.materialTitle,
            materialTimestamp: widget.materialTimestamp,
            description:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
          ),
          const SizedBox(height: 30),

          // Attachments Section
          AttachmentSection(
            attachments: [
              AttachmentItem(
                title: 'PDF Document',
                subtitle: '2.3 MB',
                icon: Icons.picture_as_pdf,
                iconColor: widget.topicColor,
              ),
              AttachmentItem(
                title: 'Presentation',
                subtitle: '5.1 MB',
                icon: Icons.slideshow,
                iconColor: widget.topicColor,
              ),
              AttachmentItem(
                title: 'Reference Link',
                subtitle: 'Web Link',
                icon: Icons.link,
                iconColor: widget.topicColor,
              ),
            ],
            topicColor: widget.topicColor,
          ),
        ],
      ),
    );
  }
}
