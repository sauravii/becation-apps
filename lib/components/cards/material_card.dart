import 'package:flutter/material.dart';

class MaterialItem {
  final String id;
  final String title;
  final String timestamp;
  final IconData icon;
  final VoidCallback? onTap;

  MaterialItem({
    required this.id,
    required this.title,
    required this.timestamp,
    this.icon = Icons.description_outlined,
    this.onTap,
  });
}

class MaterialCard extends StatelessWidget {
  final MaterialItem material;
  final String topicTitle;
  final Color topicColor;

  const MaterialCard({
    super.key,
    required this.material,
    required this.topicTitle,
    required this.topicColor,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: material.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFE7DFF8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(
              bottom: BorderSide(color: const Color(0xFF63568F), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF615B71),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(material.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C1B20),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      material.timestamp,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
