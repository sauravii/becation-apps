import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import '../../models/class_model.dart';
import '../../services/class_service.dart';
import '../auth/login_page.dart';

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
                    child: Stack(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFFE9DFF0),
                          child: Icon(Icons.person, size: 60, color: Color(0xFF6F5AAA)),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Color(0xFF6F5AAA),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'logout') {
                        _logout(context);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Theme.of(context).colorScheme.error, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
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
                StreamBuilder<List<ClassModel>>(
                  stream: user != null 
                      ? ClassService.studentClassesStream(user.uid)
                      : Stream.value([]),
                  builder: (context, snapshot) {
                    final joinedClassesCount = snapshot.data?.length ?? 0;
                    
                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.3,
                      children: [
                        _buildStatCard(
                          icon: Icons.local_fire_department,
                          value: '0',
                          label: 'Day streak',
                        ),
                        _buildStatCard(
                          icon: Icons.star_rounded,
                          value: '6967',
                          label: 'Total XP',
                        ),
                        _buildStatCard(
                          icon: Icons.people_alt,
                          value: joinedClassesCount.toString(),
                          label: 'Class Joined',
                        ),
                        _buildStatCard(
                          icon: Icons.assignment,
                          value: '23',
                          label: 'Materials completed',
                        ),
                      ],
                    );
                  },
                ),
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
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return const CircleAvatar(
                      backgroundColor: Color(0xFFE9DFF0),
                      child: Icon(
                        Icons.add,
                        color: Color(0xFF6F5AAA),
                        size: 30,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
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
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
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
