import 'package:flutter/material.dart';

import '../services/user_service.dart';
import 'skeleton_circle_avatar.dart';

/// Avatar reusable untuk class member tile. Fetch photoUrl dari `users/{uid}`.
/// Pakai cache sbg initial value (skip skeleton kalau pernah load), dan selalu
/// fetch fresh di background supaya update photo dari user lain auto-masuk.
class MemberAvatar extends StatefulWidget {
  final String uid;
  final bool isTeacher;
  final double radius;

  const MemberAvatar({
    super.key,
    required this.uid,
    required this.isTeacher,
    this.radius = 20,
  });

  @override
  State<MemberAvatar> createState() => _MemberAvatarState();
}

class _MemberAvatarState extends State<MemberAvatar> {
  late Future<Map<String, dynamic>?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = UserService.getUserDocFresh(widget.uid);
  }

  @override
  void didUpdateWidget(covariant MemberAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _userFuture = UserService.getUserDocFresh(widget.uid);
    }
  }

  Widget _fallbackPlaceholder() {
    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        color: widget.isTeacher
            ? const Color(0xFF6F5AAA)
            : const Color(0xFFE9DFF0),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        widget.isTeacher ? Icons.school : Icons.person,
        color:
            widget.isTeacher ? Colors.white : const Color(0xFF6F5AAA),
        size: widget.radius,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userFuture,
      // initialData = cache. Kalau cache hit, snap.hasData = true dari frame
      // pertama → skeleton di-skip. Begitu future done, snap rebuild dgn
      // fresh data — kalau sama, no visible change; kalau beda (user update),
      // UI auto-update tanpa cold restart.
      initialData: UserService.cachedUserDoc(widget.uid),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done && !snap.hasData) {
          return SkeletonCircleAvatar(radius: widget.radius);
        }
        final url = (snap.data?['photoUrl'] as String?) ?? '';
        return NetworkCircleAvatar(
          url: url,
          radius: widget.radius,
          fallback: _fallbackPlaceholder(),
        );
      },
    );
  }
}

/// Display name reusable — fetch displayName terbaru dari `users/{uid}`,
/// bukan dari snapshot member doc (yang stale ketika user update profil).
/// Show [fallback] selama future masih waiting / kosong / error.
class MemberDisplayName extends StatefulWidget {
  final String uid;
  final String fallback;
  final TextStyle? style;

  const MemberDisplayName({
    super.key,
    required this.uid,
    required this.fallback,
    this.style,
  });

  @override
  State<MemberDisplayName> createState() => _MemberDisplayNameState();
}

class _MemberDisplayNameState extends State<MemberDisplayName> {
  late Future<Map<String, dynamic>?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = UserService.getUserDocFresh(widget.uid);
  }

  @override
  void didUpdateWidget(covariant MemberDisplayName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _userFuture = UserService.getUserDocFresh(widget.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userFuture,
      initialData: UserService.cachedUserDoc(widget.uid),
      builder: (context, snap) {
        // Kalau cache miss DAN future belum selesai → empty Text (preserve
        // height, no stale fallback).
        if (snap.connectionState != ConnectionState.done && !snap.hasData) {
          return Text('', style: widget.style);
        }
        final fresh = (snap.data?['displayName'] as String?)?.trim() ?? '';
        final name = fresh.isNotEmpty
            ? fresh
            : (widget.fallback.isNotEmpty ? widget.fallback : 'No name');
        return Text(name, style: widget.style);
      },
    );
  }
}
