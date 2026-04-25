import 'package:flutter/material.dart';

class MaterialInfoCard extends StatelessWidget {
  final String materialTitle;
  final String materialTimestamp;
  final String? description;
  // Jika true, tampilkan icon edit (pensil) di pojok kanan atas container.
  final bool isEditing;
  // Callback saat icon edit ditekan — untuk membuka dialog edit title/description.
  final VoidCallback? onEdit;

  const MaterialInfoCard({
    super.key,
    required this.materialTitle,
    required this.materialTimestamp,
    this.description,
    this.isEditing = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE7DFF8),
            borderRadius: BorderRadius.circular(12),
            border: const Border(
              bottom: BorderSide(color: Color(0xFF63568F), width: 1),
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
                          materialTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1B20),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          materialTimestamp,
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (description != null)
                Text(
                  description!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1C1B20),
                    height: 1.5,
                  ),
                ),
            ],
          ),
        ),
        // Icon edit (pensil) muncul di center-right saat edit mode aktif.
        if (isEditing)
          Positioned(
            top: 0,
            bottom: 0,
            right: 10,
            child: Center(
              child: GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F5AAA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
