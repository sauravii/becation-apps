import 'package:flutter/material.dart';

/// Skeleton placeholder bulat dgn animasi gradient sweep (shimmer effect).
/// Dipakai sebagai loading state untuk profile photo — saat Firestore stream
/// belum return atau NetworkImage masih download.
class SkeletonCircleAvatar extends StatefulWidget {
  final double radius;

  const SkeletonCircleAvatar({super.key, required this.radius});

  @override
  State<SkeletonCircleAvatar> createState() => _SkeletonCircleAvatarState();
}

class _SkeletonCircleAvatarState extends State<SkeletonCircleAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.radius * 2;
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value;
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment(-1.0 + t * 2.0, -0.3),
                  end: Alignment(0.0 + t * 2.0, 0.3),
                  colors: const [
                    Color(0xFFE0E0E0),
                    Color(0xFFF5F5F5),
                    Color(0xFFE0E0E0),
                  ],
                ).createShader(rect);
              },
              child: Container(color: const Color(0xFFE0E0E0)),
            );
          },
        ),
      ),
    );
  }
}
