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

  final DateTime? createdAt;

  LearningNode({
    required this.id,
    required this.title,
    required this.type,
    required this.color,
    required this.shadowColor,
    required this.icon,
    required this.onTap,
    this.createdAt,
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

          // PATH PAINTER (Ultra-smooth "S" curve)
          Positioned.fill(
            child: CustomPaint(painter: PathPainter(topics: widget.topics)),
          ),

          ListView.builder(
            reverse: true,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.topics.length,
            itemBuilder: (context, topicIndex) {
              final topic = widget.topics[topicIndex];

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

                          double currentX = 0.0;
                          final patternPos = absoluteIndex % 8;

                          switch (patternPos) {
                            case 0:
                              currentX = 0.0;
                              break;
                            case 1:
                              currentX = 0.35;
                              break;
                            case 2:
                              currentX = 0.55;
                              break;
                            case 3:
                              currentX = 0.35;
                              break;
                            case 4:
                              currentX = 0.0;
                              break;
                            case 5:
                              currentX = -0.35;
                              break;
                            case 6:
                              currentX = -0.55;
                              break;
                            case 7:
                              currentX = -0.35;
                              break;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 80, top: 30),
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
                        .toList(),
                  ),

                  // Topic Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
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
    final double scale = size.width / imgWidth;
    final double scaledHeight = imgHeight * scale;
    int tileCount = (size.height / scaledHeight).ceil();
    for (int i = 0; i < tileCount; i++) {
      final double yPos = i * scaledHeight;
      final bool isOdd = i % 2 != 0;
      canvas.save();
      if (isOdd) {
        canvas.translate(0, yPos + scaledHeight);
        canvas.scale(1, -1);
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, imgWidth, imgHeight),
          Rect.fromLTWH(0, 0, size.width, scaledHeight),
          Paint(),
        );
      } else {
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
  bool shouldRepaint(covariant MirroredBackgroundPainter oldDelegate) =>
      oldDelegate.image != image;
}

class PathPainter extends CustomPainter {
  final List<LearningTopic> topics;

  PathPainter({required this.topics});

  @override
  void paint(Canvas canvas, Size size) {
    if (topics.isEmpty) return;

    final pathPaint = Paint()
      ..color = const Color(0xFFFFF0DF).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 35
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final List<Offset> points = [];
    int globalIndex = 0;
    double currentY = size.height;

    for (int i = 0; i < topics.length; i++) {
      final topic = topics[i];
      currentY -= (20 + 48 + 60);
      for (int j = 0; j < topic.nodes.length; j++) {
        final int absoluteIndex = globalIndex + j;
        double xFactor = 0.0;
        final patternPos = absoluteIndex % 8;
        switch (patternPos) {
          case 0:
            xFactor = 0.0;
            break;
          case 1:
            xFactor = 0.3;
            break;
          case 2:
            xFactor = 0.5;
            break;
          case 3:
            xFactor = 0.3;
            break;
          case 4:
            xFactor = 0.0;
            break;
          case 5:
            xFactor = -0.3;
            break;
          case 6:
            xFactor = -0.5;
            break;
          case 7:
            xFactor = -0.3;
            break;
        }
        final double x = size.width / 2 + (xFactor * (size.width / 2));
        points.add(Offset(x, currentY - 80 - 30));
        currentY -= (80 + 60 + 30);
      }
      globalIndex += topic.nodes.length;
    }

    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    // PERFECT SYMMETRICAL S-CURVE (Design Match)
    // To achieve the perfect curve from your design screenshot:
    // 1. Control points must be vertically mirrored.
    // 2. Control points MUST have the SAME X-coordinate as the nodes they belong to.
    // 3. The vertical distance of control points (0.5 dy) ensures a natural S-flow.
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      final double dy = (p1.dy - p0.dy).abs();

      // Balanced tension (0.5) for a smooth S-curve
      path.cubicTo(
        p0.dx,
        p0.dy - (dy * 0.08),
        p1.dx,
        p1.dy + (dy * 0.08),
        p1.dx,
        p1.dy,
      );
    }

    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) => true;
}
