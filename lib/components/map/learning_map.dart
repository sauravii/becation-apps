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
      final data = await rootBundle.load("assets/icons/map_grass.png");
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      if (!mounted) {
        image.dispose(); // Cegah memory leak jika widget sudah tidak ada
        return;
      }

      setState(() {
        _backgroundImage = image;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading background: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _backgroundImage?.dispose(); // Bersihkan resource image
    super.dispose();
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

          // BEAUTIFUL 3D ROAD PATH
          Positioned.fill(
            child: ClipRect(
              child: CustomPaint(painter: PathPainter(topics: widget.topics)),
            ),
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

                          final screenWidth = MediaQuery.of(context).size.width;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 80, top: 30),
                            child: Center(
                              child: Transform.translate(
                                offset: Offset(currentX * (screenWidth / 2), 0),
                                child: GestureDetector(
                                  onTap: node.onTap,
                                  child: _buildNodeIcon(node),
                                ),
                              ),
                            ),
                          );
                        })
                        .toList()
                        .reversed
                        .toList(),
                  ),

                  // Topic Header (Pastel Orchid Cloud Banner)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white, // Pure white base
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFD1C4E9), // Light Lavender
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6F5AAA).withValues(alpha: 0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          topic.title.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF512DA8), // Royal Purple
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.2,
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
    return SizedBox(
      height: 98,
      width: 160, // Constrain width so long text will wrap instead of overflowing horizontally
      child: Stack(
        clipBehavior: Clip.none, // Allow text to safely expand downward if it wraps to 2 lines
        alignment: Alignment.topCenter,
        children: [
          // Icon stack mathematically locked to the top (prevents path drifting)
          Positioned(
            top: 0,
            child: Stack(
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
          ),
          // Pill Container bergaya "Pastel Orchid Cloud" (Solid Soft)
          Positioned(
            top: 68,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5), // Ultra Soft Lilac (Solid)
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE1BEE7), // Soft Orchid border
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6F5AAA).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                node.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6A1B9A), // Deep Orchid for readability
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
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

    // Single glowing magical path
    final pathPaint = Paint()
      ..color = const Color(0xFFFFF0DF).withValues(alpha: 0.8) // Glowing beam
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    // Border path untuk mempertegas "Jalan"
    final borderPaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.4) // Deep brown edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 38
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final List<Offset> points = [];
    int globalIndex = 0;
    double currentY = size.height;

    for (int i = 0; i < topics.length; i++) {
      final topic = topics[i];
      currentY -= 123.0; // Restored exactly to original Topic Header height

      for (int j = 0; j < topic.nodes.length; j++) {
        final int absoluteIndex = globalIndex + j;
        double xFactor = 0.0;
        final patternPos = absoluteIndex % 8;
        switch (patternPos) {
          case 0: xFactor = 0.0; break;
          case 1: xFactor = 0.35; break;
          case 2: xFactor = 0.55; break;
          case 3: xFactor = 0.35; break;
          case 4: xFactor = 0.0; break;
          case 5: xFactor = -0.35; break;
          case 6: xFactor = -0.55; break;
          case 7: xFactor = -0.35; break;
        }
        final double x = size.width / 2 + (xFactor * (size.width / 2));
        
        points.add(Offset(x, currentY - 148.0));
        currentY -= 208.0; // Restored perfectly to original node height
      }
      globalIndex += topic.nodes.length;
    }

    // Extend the path to the very bottom edge of the screen
    if (points.isNotEmpty) {
      points.insert(0, Offset(points.first.dx, size.height + 100));
      // Extend the path to the very top edge of the screen
      points.add(Offset(points.last.dx, -100));
    }

    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final double dy = (p1.dy - p0.dy).abs();

      path.cubicTo(
        p0.dx,
        p0.dy - (dy * 0.5),
        p1.dx,
        p1.dy + (dy * 0.5),
        p1.dx,
        p1.dy,
      );
    }

    canvas.drawPath(path, borderPaint); // Draw border/edge first
    canvas.drawPath(path, pathPaint); // Glowing beam
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    // Hanya repaint jika jumlah topik atau struktur node berubah
    return oldDelegate.topics.length != topics.length;
  }
}


