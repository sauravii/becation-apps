import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Module-level cache user doc — dipakai bareng MemberAvatar + MemberDisplayName.
/// Cache hit → return SynchronousFuture supaya FutureBuilder skip waiting state
/// (no flicker pas re-render / repeat visit).
final Map<String, Map<String, dynamic>?> _userDocCache = {};

Future<Map<String, dynamic>?> _fetchUserDoc(String uid) {
  if (_userDocCache.containsKey(uid)) {
    return SynchronousFuture(_userDocCache[uid]);
  }
  return _fetchUserDocAsync(uid);
}

Future<Map<String, dynamic>?> _fetchUserDocAsync(String uid) async {
  try {
    final snap = await FirebaseFirestore.instance.doc('users/$uid').get();
    _userDocCache[uid] = snap.data();
    return _userDocCache[uid];
  } catch (_) {
    return null;
  }
}

/// Avatar reusable untuk class member tile. Fetch photoUrl dari `users/{uid}`
/// sekali per instance (memoized via initState). Kalau ada photo → render
/// NetworkImage; kalau gak ada → fallback ke placeholder Icon (school untuk
/// teacher, person untuk student).
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
    _userFuture = _fetchUserDoc(widget.uid);
  }

  @override
  void didUpdateWidget(covariant MemberAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _userFuture = _fetchUserDoc(widget.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userFuture,
      builder: (context, snap) {
        final url = (snap.data?['photoUrl'] as String?) ?? '';
        final hasPhoto = url.isNotEmpty;
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: widget.isTeacher
              ? const Color(0xFF6F5AAA)
              : const Color(0xFFE9DFF0),
          backgroundImage: hasPhoto ? NetworkImage(url) : null,
          child: hasPhoto
              ? null
              : Icon(
                  widget.isTeacher ? Icons.school : Icons.person,
                  color: widget.isTeacher
                      ? Colors.white
                      : const Color(0xFF6F5AAA),
                  size: widget.radius,
                ),
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
    _userFuture = _fetchUserDoc(widget.uid);
  }

  @override
  void didUpdateWidget(covariant MemberDisplayName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _userFuture = _fetchUserDoc(widget.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userFuture,
      builder: (context, snap) {
        // Jangan tampilkan fallback (member doc stale) selama loading —
        // bikin flicker dari nama lama → nama baru. Reserve baseline pakai
        // Text kosong supaya tinggi ListTile gak shift.
        if (snap.connectionState != ConnectionState.done) {
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
