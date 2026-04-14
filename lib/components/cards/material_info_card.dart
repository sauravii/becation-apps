import 'package:flutter/material.dart';

class MaterialInfoCard extends StatelessWidget {
  final String materialTitle;
  final String materialTimestamp;
  final String? description;

  const MaterialInfoCard({
    super.key,
    required this.materialTitle,
    required this.materialTimestamp,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
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
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
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
    );
  }
}
