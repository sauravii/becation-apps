import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LearningNode {
  final String id;
  final String title;
  final String type; // 'quiz' or 'material'
  final Color color;
  final Color shadowColor;
  final String icon;
  final VoidCallback onTap;

  LearningNode({
    required this.id,
    required this.title,
    required this.type,
    required this.color,
    required this.shadowColor,
    required this.icon,
    required this.onTap,
  });
}

class LearningTopic {
  final String id;
  final String title;
  final List<LearningNode> nodes;

  LearningTopic({required this.id, required this.title, required this.nodes});
}

class LearningMap extends StatefulWidget {
  final List<LearningTopic> topics;

  const LearningMap({super.key, required this.topics});

  @override
  State<LearningMap> createState() => _LearningMapState();
}

class _LearningMapState extends State<LearningMap> {
  ui.Image? _backgroundImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackground();
  }

  Future<void> _loadBackground() async {
    try {
      final data = await rootBundle.load('assets/icons/map_grass.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _backgroundImage = frame.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading background: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.topics.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No learning path available yet.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    int globalNodeIndex = 0;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(minHeight: screenHeight),
      child: Stack(
        children: [
          // SEAMLESS MIRRORED BACKGROUND
          if (_backgroundImage != null)
            Positioned.fill(
              child: CustomPaint(
                painter: MirroredBackgroundPainter(image: _backgroundImage!),
              ),
            )
          else if (_isLoading)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            // Fallback to solid color if image fails
            Positioned.fill(child: Container(color: const Color(0xFF7CB342))),

          // Background Overlay for better readability
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.05)),
          ),

          ListView.builder(
            reverse: true,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.topics.length,
            itemBuilder: (context, topicIndex) {
              final topic = widget.topics[topicIndex];

              // FIXED: Calculate startGlobalIndex properly based on previous topics
              int startGlobalIndex = 0;
              for (int i = 0; i < topicIndex; i++) {
                startGlobalIndex += widget.topics[i].nodes.length;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nodes
                  Column(
                    children: topic.nodes
                        .asMap()
                        .entries
                        .map((entry) {
                          final int localIndex = entry.key;
                          final int absoluteIndex =
                              startGlobalIndex + localIndex;
                          final LearningNode node = entry.value;

                          // Custom pattern logic (Reset every 8 nodes)
                          double currentX = 0.0;
                          final patternPos = absoluteIndex % 8;

                          switch (patternPos) {
                            case 0:
                              currentX = 0.0;
                              break; // 1: Tengah (0)
                            case 1:
                              currentX = 0.35;
                              break; // 2: Kanan (+0.35)
                            case 2:
                              currentX = 0.65;
                              break; // 3: Kanan Pol (+0.7)
                            case 3:
                              currentX = 0.35;
                              break; // 4: Kanan Balik (+0.35)
                            case 4:
                              currentX = 0.0;
                              break; // 5: Tengah (0)
                            case 5:
                              currentX = -0.35;
                              break; // 6: Kiri (-0.35)
                            case 6:
                              currentX = -0.65;
                              break; // 7: Kiri Pol (-0.7)
                            case 7:
                              currentX = -0.35;
                              break; // 8: Kiri Balik (-0.35)
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 50, top: 20),
                            child: Align(
                              alignment: Alignment(currentX, 0),
                              child: GestureDetector(
                                onTap: node.onTap,
                                child: _buildNodeIcon(node),
                              ),
                            ),
                          );
                        })
                        .toList()
                        .reversed
                        .toList(), // FIXED: Reverse to start from bottom
                  ),

                  // Topic Header with Glassmorphism Effect
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  topic.title.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1.2,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black26,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNodeIcon(LearningNode node) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Shadow under the coin
            Transform.translate(
              offset: const Offset(0, 4),
              child: Container(
                width: 50,
                height: 15,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),

            // The Coin Image
            SizedBox(
              width: 60,
              height: 60,
              child: Center(
                child: Image.asset(
                  node.icon,
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MirroredBackgroundPainter extends CustomPainter {
  final ui.Image image;

  MirroredBackgroundPainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final double imgWidth = image.width.toDouble();
    final double imgHeight = image.height.toDouble();

    // Calculate how much to scale the image to fit the width
    final double scale = size.width / imgWidth;
    final double scaledHeight = imgHeight * scale;

    int tileCount = (size.height / scaledHeight).ceil();

    for (int i = 0; i < tileCount; i++) {
      final double yPos = i * scaledHeight;
      final bool isOdd = i % 2 != 0;

      canvas.save();

      if (isOdd) {
        // MIRROR EFFECT: Move to bottom of tile, then scale -1 on Y axis
        canvas.translate(0, yPos + scaledHeight);
        canvas.scale(1, -1);
        // Draw at origin (which is now the inverted bottom)
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, imgWidth, imgHeight),
          Rect.fromLTWH(0, 0, size.width, scaledHeight),
          Paint(),
        );
      } else {
        // NORMAL DRAW
        canvas.translate(0, yPos);
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, imgWidth, imgHeight),
          Rect.fromLTWH(0, 0, size.width, scaledHeight),
          Paint(),
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant MirroredBackgroundPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
