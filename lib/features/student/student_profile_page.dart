import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/gamification/badges_grid.dart';
import '../../components/skeleton_circle_avatar.dart';
import '../../models/class_model.dart';
import '../../services/auth_service.dart';
import '../../services/badges_service.dart';
import '../../services/class_service.dart';
import '../../services/user_service.dart';
import '../auth/login_page.dart';
import '../profile/profile_edit_page.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key, this.onTabRequested});

  final ValueChanged<int>? onTabRequested;

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.signOut();

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final fallbackName =
        user?.displayName ?? user?.email?.split('@').first ?? 'Username';

    String joinedDate = 'December 2025';
    if (user?.metadata.creationTime != null) {
      joinedDate = DateFormat('MMMM yyyy').format(user!.metadata.creationTime!);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Purple Background
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF6F5AAA),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 60, bottom: 40),
                  child: Center(
                    child: StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: user != null
                          ? UserService.userStream(user.uid)
                          : null,
                      builder: (context, snap) {
                        final waitingStream =
                            snap.connectionState == ConnectionState.waiting;
                        final photoUrl =
                            (snap.data?.data()?['photoUrl'] as String?) ??
                                '';
                        final hasPhoto = photoUrl.isNotEmpty;

                        if (waitingStream) {
                          return const SkeletonCircleAvatar(radius: 50);
                        }
                        if (!hasPhoto) {
                          return const CircleAvatar(
                            radius: 50,
                            backgroundColor: Color(0xFFE9DFF0),
                            child: Icon(Icons.person,
                                size: 60, color: Color(0xFF6F5AAA)),
                          );
                        }
                        return ClipOval(
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return const SkeletonCircleAvatar(radius: 50);
                              },
                              errorBuilder: (_, __, ___) => const CircleAvatar(
                                radius: 50,
                                backgroundColor: Color(0xFFE9DFF0),
                                child: Icon(Icons.person,
                                    size: 60, color: Color(0xFF6F5AAA)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileEditPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username (reactive — listen Firestore supaya refresh setelah
                // edit name tanpa harus pindah tab).
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: user != null
                      ? UserService.userStream(user.uid)
                      : null,
                  builder: (context, snap) {
                    final fsName =
                        (snap.data?.data()?['displayName'] as String?)?.trim();
                    final name = (fsName == null || fsName.isEmpty)
                        ? fallbackName
                        : fsName;
                    return Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined $joinedDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Statistics
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _StudentStatsGrid(uid: user?.uid),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Badges
                const Text(
                  'Badges',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _EarnedBadgesGrid(uid: user?.uid),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B2C2C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

/// Stats grid student — wire ke:
/// - userStream → point + streak.current
/// - studentClassesStream → joined classes count
/// - materialsCompletedCount → materi completed
class _StudentStatsGrid extends StatefulWidget {
  final String? uid;
  const _StudentStatsGrid({required this.uid});

  @override
  State<_StudentStatsGrid> createState() => _StudentStatsGridState();
}

class _StudentStatsGridState extends State<_StudentStatsGrid> {
  // Static cache per uid — skip flicker pas widget re-mount (tab switch dll).
  // Invalidate kalau uid berubah (logout-login akun lain).
  static String? _cacheUid;
  static Map<String, dynamic>? _cachedUserDoc;
  static List<ClassModel>? _cachedClasses;
  static int? _cachedMaterialsCount;

  late Future<int> _materialsCompletedFuture;

  void _resetCacheIfDifferentUid(String? uid) {
    if (_cacheUid != uid) {
      _cacheUid = uid;
      _cachedUserDoc = null;
      _cachedClasses = null;
      _cachedMaterialsCount = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _materialsCompletedFuture = widget.uid != null
        ? UserService.materialsCompletedCount(widget.uid!)
        : Future.value(0);
  }

  @override
  Widget build(BuildContext context) {
    _resetCacheIfDifferentUid(widget.uid);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          widget.uid != null ? UserService.userStream(widget.uid!) : null,
      builder: (context, userSnap) {
        final fetched = userSnap.data?.data();
        if (fetched != null) _cachedUserDoc = fetched;
        final userData = fetched ?? _cachedUserDoc;
        final point = (userData?['point'] as num?)?.toInt() ?? 0;
        final streakDay =
            ((userData?['streak'] as Map?)?['current'] as num?)?.toInt() ??
                0;

        return StreamBuilder<List<ClassModel>>(
          stream: widget.uid != null
              ? ClassService.studentClassesStream(widget.uid!)
              : Stream.value(const []),
          initialData: _cachedClasses,
          builder: (context, classSnap) {
            final fetchedClasses = classSnap.data;
            if (fetchedClasses != null) _cachedClasses = fetchedClasses;
            final joinedClassesCount =
                (fetchedClasses ?? _cachedClasses ?? const []).length;

            return FutureBuilder<int>(
              future: _materialsCompletedFuture,
              initialData: _cachedMaterialsCount,
              builder: (context, matSnap) {
                final fetchedMat = matSnap.data;
                if (fetchedMat != null) _cachedMaterialsCount = fetchedMat;
                final matCount =
                    fetchedMat ?? _cachedMaterialsCount ?? 0;

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.3,
                  children: [
                    _statCard(
                      icon: Icons.local_fire_department,
                      value: streakDay.toString(),
                      label: 'Day streak',
                    ),
                    _statCard(
                      icon: Icons.star_rounded,
                      value: point.toString(),
                      label: 'Total Points',
                    ),
                    _statCard(
                      icon: Icons.people_alt,
                      value: joinedClassesCount.toString(),
                      label: 'Class Joined',
                    ),
                    _statCard(
                      icon: Icons.assignment,
                      value: matCount.toString(),
                      label: 'Materials completed',
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6F5AAA)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6F5AAA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Render SEMUA badges. Earned di-render normal, locked di-grayscale (handled
/// di BadgeCard). Secret locked di-mask di backend (name='?????', ? icon).
/// Default preview 6 badge (2 row). Tombol "More" expand jadi full list.
/// Sort: non-secret dulu (preserve backend order), secret di paling akhir.
class _EarnedBadgesGrid extends StatefulWidget {
  final String? uid;
  const _EarnedBadgesGrid({required this.uid});

  @override
  State<_EarnedBadgesGrid> createState() => _EarnedBadgesGridState();
}

class _EarnedBadgesGridState extends State<_EarnedBadgesGrid> {
  static const int _previewCount = 6;
  late Future<List<BadgeItem>> _future;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _future = widget.uid != null
        ? BadgesService.getBadges(widget.uid!)
        : Future.value(const []);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BadgeItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFF6F5AAA),
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load badges: ${snap.error}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        }
        final all = snap.data ?? const <BadgeItem>[];
        if (all.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No badges available yet.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          );
        }
        final sorted = <BadgeItem>[
          ...all.where((b) => !b.isSecret),
          ...all.where((b) => b.isSecret),
        ];
        final visible = _expanded
            ? sorted
            : sorted.take(_previewCount).toList();
        final canShowMore = !_expanded && sorted.length > _previewCount;

        return Column(
          children: [
            BadgesGrid(badges: visible, columns: 3, iconSize: 64),
            if (canShowMore)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _expanded = true),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                  child: const Text(
                    'More',
                    style: TextStyle(
                      color: Color(0xFF9886C5),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF9886C5),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
