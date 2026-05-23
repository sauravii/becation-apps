import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import '../../components/gamification/badges_grid.dart';
import '../../models/class_model.dart';
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
      await FirebaseAuth.instance.signOut();
      try {
        await GoogleSignIn().signOut();
      } catch (_) {
        // Ignore if not using Google sign-in.
      }

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? user?.email?.split('@').first ?? 'Username';
    
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
                        final photoUrl =
                            (snap.data?.data()?['photoUrl'] as String?) ??
                                '';
                        final hasPhoto = photoUrl.isNotEmpty;
                        return CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFE9DFF0),
                          backgroundImage:
                              hasPhoto ? NetworkImage(photoUrl) : null,
                          child: hasPhoto
                              ? null
                              : const Icon(Icons.person,
                                  size: 60, color: Color(0xFF6F5AAA)),
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
                // Username and Join Date
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
  late Future<int> _materialsCompletedFuture;

  @override
  void initState() {
    super.initState();
    _materialsCompletedFuture = widget.uid != null
        ? UserService.materialsCompletedCount(widget.uid!)
        : Future.value(0);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          widget.uid != null ? UserService.userStream(widget.uid!) : null,
      builder: (context, userSnap) {
        final userData = userSnap.data?.data();
        final point = (userData?['point'] as num?)?.toInt() ?? 0;
        final streakDay =
            ((userData?['streak'] as Map?)?['current'] as num?)?.toInt() ??
                0;

        return StreamBuilder<List<ClassModel>>(
          stream: widget.uid != null
              ? ClassService.studentClassesStream(widget.uid!)
              : Stream.value(const []),
          builder: (context, classSnap) {
            final joinedClassesCount = classSnap.data?.length ?? 0;

            return FutureBuilder<int>(
              future: _materialsCompletedFuture,
              builder: (context, matSnap) {
                final matCount = matSnap.data ?? 0;

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
              'Gagal load badges: ${snap.error}',
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
                'Belum ada badge tersedia.',
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
