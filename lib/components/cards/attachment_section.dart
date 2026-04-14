import 'package:flutter/material.dart';
import 'attachment_item.dart';

class AttachmentSection extends StatelessWidget {
  final List<AttachmentItem> attachments;
  final Color topicColor;

  const AttachmentSection({
    super.key,
    required this.attachments,
    required this.topicColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attachments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1B20),
            ),
          ),
          const SizedBox(height: 15),
          ...attachments.map((attachment) => attachment).toList(),
        ],
      ),
    );
  }
}
