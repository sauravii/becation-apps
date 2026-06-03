import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/skeleton_circle_avatar.dart';
import '../../models/class_model.dart';
import '../../services/auth_service.dart';
import '../../services/class_service.dart';
import '../../services/user_service.dart';
import '../auth/login_page.dart';
import '../profile/profile_edit_page.dart';

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key, this.onTabRequested});

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
                _TeacherStatsGrid(uid: user?.uid),
                const SizedBox(height: 24),
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

/// Stats grid teacher — gamifikasi (streak/point/badges) tidak dipakai untuk
/// teacher, jadi cuma 2 cards: classes created + materials created.
class _TeacherStatsGrid extends StatefulWidget {
  final String? uid;
  const _TeacherStatsGrid({required this.uid});

  @override
  State<_TeacherStatsGrid> createState() => _TeacherStatsGridState();
}

class _TeacherStatsGridState extends State<_TeacherStatsGrid> {
  // Static cache per uid — skip flicker pas widget re-mount.
  static String? _cacheUid;
  static List<ClassModel>? _cachedClasses;
  static int? _cachedMaterialsCount;

  late Future<int> _materialsCountFuture;

  void _resetCacheIfDifferentUid(String? uid) {
    if (_cacheUid != uid) {
      _cacheUid = uid;
      _cachedClasses = null;
      _cachedMaterialsCount = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _materialsCountFuture = widget.uid != null
        ? ClassService.teacherMaterialsCount(widget.uid!)
        : Future.value(0);
  }

  @override
  Widget build(BuildContext context) {
    _resetCacheIfDifferentUid(widget.uid);
    return StreamBuilder<List<ClassModel>>(
      stream: widget.uid != null
          ? ClassService.teacherClassesStream(widget.uid!)
          : Stream.value(const []),
      initialData: _cachedClasses,
      builder: (context, classSnap) {
        final fetchedClasses = classSnap.data;
        if (fetchedClasses != null) _cachedClasses = fetchedClasses;
        final createdClassesCount =
            (fetchedClasses ?? _cachedClasses ?? const []).length;

        return FutureBuilder<int>(
          future: _materialsCountFuture,
          initialData: _cachedMaterialsCount,
          builder: (context, matSnap) {
            final fetchedMat = matSnap.data;
            if (fetchedMat != null) _cachedMaterialsCount = fetchedMat;
            final matCount = fetchedMat ?? _cachedMaterialsCount ?? 0;

            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.3,
              children: [
                _statCard(
                  icon: Icons.people_alt,
                  value: createdClassesCount.toString(),
                  label: 'Class Created',
                ),
                _statCard(
                  icon: Icons.assignment,
                  value: matCount.toString(),
                  label: 'Materials Created',
                ),
              ],
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
