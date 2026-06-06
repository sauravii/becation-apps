import 'dart:ui' as ui;
import 'dart:math';
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
  final ScrollController? controller;
  final double headerHeight; // To avoid collision with main header
  final double offsetGap;    // Gap between main header and sticky header

  const LearningMap({
    super.key,
    required this.topics,
    this.controller,
    this.headerHeight = 0.0,
    this.offsetGap = 8.0,
  });

  @override
  State<LearningMap> createState() => _LearningMapState();
}

class _LearningMapState extends State<LearningMap> {
  ui.Image? _backgroundImage;
  bool _isLoading = true;
  final GlobalKey _stackKey = GlobalKey();
  List<GlobalKey> _nodeKeys = [];
  List<GlobalKey> _topicKeys = [];
  List<Offset> _nodePositions = [];

  // Sticky Header State
  String? _stickyTopicId;
  double _stickyHeaderOffset = 0.0;
  ScrollController? _internalController;
  
  // Cached layout metrics for zero-lag synchronous scrolling
  double? _cachedViewportTop;
  double? _cachedStackScrollY;
  List<double> _topicLocalYs = [];
  List<double> _topicHeights = [];

  ScrollController get _effectiveController =>
      widget.controller ?? (_internalController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _loadBackground();
    _buildNodeKeys();
    _effectiveController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    // Synchronous call guarantees zero flickering
    _updateStickyHeader();
  }

  void _updateStickyHeader() {
    if (_topicKeys.isEmpty || !mounted || _cachedViewportTop == null || _cachedStackScrollY == null) return;
    if (_topicLocalYs.length != widget.topics.length) return;

    final double scrollOffset = _effectiveController.hasClients ? _effectiveController.offset : 0.0;
    
    // Predict EXACT screen position of the Stack for THIS frame mathematically.
    // This perfectly compensates for fast scrolling without any 1-frame layout lag!
    final double exactStackScreenTop = _cachedViewportTop! + _cachedStackScrollY! - scrollOffset;
    final double stickyBoundaryTop = _cachedViewportTop! + widget.headerHeight + widget.offsetGap;

    String? newStickyId;
    double newOffset = 0.0;

    // The reversed ListView has topic[0] at bottom, topic[N-1] at top.
    for (int i = widget.topics.length - 1; i >= 0; i--) {
      final double exactHeaderScreenTop = exactStackScreenTop + _topicLocalYs[i];
      final double exactHeaderScreenBottom = exactHeaderScreenTop + _topicHeights[i];

      // Header has completely scrolled past the boundary
      if (exactHeaderScreenBottom < stickyBoundaryTop) {
        newStickyId = widget.topics[i].id;
      }
    }

    if (newStickyId != null) {
      // Offset from the top of the Stack to the boundary line
      newOffset = stickyBoundaryTop - exactStackScreenTop;

      // Push-up effect
      final currentIndex = widget.topics.indexWhere((t) => t.id == newStickyId);
      if (currentIndex > 0) {
        final double nextScreenTop = exactStackScreenTop + _topicLocalYs[currentIndex - 1];
        final double currentStickyHeight = _topicHeights[currentIndex];
        
        // Distance from next header to our boundary
        final double distanceToBoundary = nextScreenTop - stickyBoundaryTop;
        
        if (distanceToBoundary < currentStickyHeight) {
          newOffset += (distanceToBoundary - currentStickyHeight);
        }
      }
    }

    if (_stickyTopicId != newStickyId || _stickyHeaderOffset != newOffset) {
      setState(() {
        _stickyTopicId = newStickyId;
        _stickyHeaderOffset = newOffset;
      });
    }
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _backgroundImage?.dispose(); // Bersihkan resource image
    if (widget.controller == null) {
      _internalController?.dispose();
    } else {
      widget.controller!.removeListener(_onScroll);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LearningMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topics != widget.topics) {
      _buildNodeKeys();
      _cachedViewportTop = null; // Re-measure after layout change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _computePositions();
        _updateStickyHeader();
      });
    }

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onScroll);
      widget.controller?.addListener(_onScroll);
      if (widget.controller == null) {
        _internalController ??= ScrollController();
        _internalController!.addListener(_onScroll);
      } else {
        _internalController?.removeListener(_onScroll);
        _internalController?.dispose();
        _internalController = null;
      }
    }
  }

  void _buildNodeKeys() {
    int totalNodes = 0;
    for (final topic in widget.topics) {
      totalNodes += topic.nodes.length;
    }
    _nodeKeys = List.generate(totalNodes, (_) => GlobalKey());
    _topicKeys = List.generate(widget.topics.length, (_) => GlobalKey());
    _nodePositions = [];
    WidgetsBinding.instance.addPostFrameCallback((_) => _computePositions());
  }

  void _computePositions() {
    final stackBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return;

    // 1. Measure viewport and scroll state ONCE
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    if (scrollable != null) {
      final RenderBox? scrollBox = scrollable.context.findRenderObject() as RenderBox?;
      if (scrollBox != null && scrollBox.hasSize) {
        _cachedViewportTop = scrollBox.localToGlobal(Offset.zero).dy;
      }
    }
    
    final double scrollOffset = _effectiveController.hasClients ? _effectiveController.offset : 0.0;
    final double stackGlobalY = stackBox.localToGlobal(Offset.zero).dy;
    
    // Y-position of the stack within the scroll view's content bounds
    _cachedStackScrollY = stackGlobalY - (_cachedViewportTop ?? 0.0) + scrollOffset;

    final positions = <Offset>[];
    
    // 2. Collect node icon positions
    for (final key in _nodeKeys) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final nodeSize = box.size;
      final center = Offset(nodeSize.width / 2, nodeSize.height / 2);
      final global = box.localToGlobal(center);
      positions.add(stackBox.globalToLocal(global));
    }

    _topicLocalYs = [];
    _topicHeights = [];
    
    // 3. Collect topic header positions
    for (final key in _topicKeys) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) {
        _topicLocalYs.add(0.0);
        _topicHeights.add(0.0);
        continue;
      }
      final nodeSize = box.size;
      
      // Cache local bounds for zero-lag scroll math
      final globalTopLeft = box.localToGlobal(Offset.zero);
      _topicLocalYs.add(stackBox.globalToLocal(globalTopLeft).dy);
      _topicHeights.add(nodeSize.height);

      // Path drawing coordinates
      final center = Offset(nodeSize.width / 2, nodeSize.height / 2);
      final globalCenter = box.localToGlobal(center);
      positions.add(stackBox.globalToLocal(globalCenter));
    }

    final expectedCount = _nodeKeys.length + _topicKeys.length;
    if (mounted && positions.length == expectedCount) {
      setState(() => _nodePositions = positions);
    }
    
    // Trigger initial sticky header computation
    if (mounted) _updateStickyHeader();
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
        key: _stackKey,
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
              child: CustomPaint(painter: PathPainter(nodePositions: _nodePositions)),
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
                  // 1. Topic Header (Move to Top)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
                    child: Center(
                      child: Container(
                        key: topicIndex < _topicKeys.length
                            ? _topicKeys[topicIndex]
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24, // Reduced from 32
                          vertical: 10,   // Reduced from 14
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF4A148C).withValues(alpha: 0.6), // Deep Royal Purple
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: const Color(0xFFF3E5F5).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          topic.title.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Nodes (Underneath Header)
                  Column(
                    children: topic.nodes
                        .asMap()
                        .entries
                        .map((entry) {
                          final int localIndex = entry.key;
                          final int absoluteIndex =
                              startGlobalIndex + localIndex;
                          final LearningNode node = entry.value;

                          // Smooth alternating S-curve: each node on the opposite side
                          final double currentX =
                              cos(absoluteIndex * pi) * 0.42;

                          final screenWidth = MediaQuery.of(context).size.width;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 80, top: 30),
                            child: Center(
                              child: Transform.translate(
                                offset: Offset(currentX * (screenWidth / 2), 0),
                                child: GestureDetector(
                                  onTap: node.onTap,
                                  child: _buildNodeIcon(
                                    node,
                                    nodeKey: absoluteIndex < _nodeKeys.length
                                        ? _nodeKeys[absoluteIndex]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        })
                        .toList()
                        .reversed
                        .toList(),
                  ),
                ],
              );
            },
          ),
          // Custom Sticky Header
          if (_stickyTopicId != null)
            Positioned(
              top: _stickyHeaderOffset,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF4A148C).withValues(alpha: 0.8),
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: const Color(0xFFF3E5F5).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.topics
                        .firstWhere((t) => t.id == _stickyTopicId)
                        .title
                        .toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNodeIcon(LearningNode node, {GlobalKey? nodeKey}) {
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
                  key: nodeKey,
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
          // Pill Container bergaya "Royal Plum Mist" (Semi-transparent)
          Positioned(
            top: 68,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF300030).withValues(alpha: 0.6), // Dark Plum Obsidian
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                node.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white, // Pure white for readability
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
  final List<Offset> nodePositions;

  PathPainter({required this.nodePositions});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.isEmpty) return;

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

    // Sort by Y descending (bottom-most node first) to draw path bottom→top
    final sorted = List<Offset>.from(nodePositions)
      ..sort((a, b) => b.dy.compareTo(a.dy));

    final points = <Offset>[];
    // Extend path below the bottom-most node
    points.add(Offset(sorted.first.dx, size.height + 100));
    points.addAll(sorted);
    // Extend path above the top-most node
    points.add(Offset(sorted.last.dx, -100));

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
    return oldDelegate.nodePositions != nodePositions;
  }
}


