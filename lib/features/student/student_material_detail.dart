import 'package:flutter/material.dart';

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
          _buildMaterialInfoCard(),
          const SizedBox(height: 30),

          // Instructions Section
          _buildInstructionsSection(),
          const SizedBox(height: 30),

          // Attachments Section
          _buildAttachmentsSection(),
        ],
      ),
    );
  }

  Widget _buildMaterialInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE7DFF8),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF63568F), width: 1),
        ),
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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF615B71),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.materialTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1B20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.materialTimestamp,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF615B71),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Turn in',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Material Description
          const Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF1C1B20),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
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
            'Instructions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1B20),
            ),
          ),
          const SizedBox(height: 15),
          _buildInstructionItem('1. Read the material carefully'),
          _buildInstructionItem('2. Complete the assignment'),
          _buildInstructionItem('3. Submit before deadline'),
          _buildInstructionItem('4. Follow the guidelines'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: widget.topicColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1C1B20),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection() {
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
          _buildAttachmentItem('PDF Document', '2.3 MB', Icons.picture_as_pdf),
          _buildAttachmentItem('Presentation', '5.1 MB', Icons.slideshow),
          _buildAttachmentItem('Reference Link', 'Web Link', Icons.link),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                color: widget.topicColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: widget.topicColor, size: 20),
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
            IconButton(
              icon: const Icon(Icons.download, color: Color(0xFF6F5AAA)),
              onPressed: () {
                // Download functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}
