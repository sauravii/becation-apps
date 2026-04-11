import 'package:becation_apps/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'teacher_classes_page.dart';
import 'teacher_settings_page.dart';
import 'teacher_bottom_nav.dart';

class TeacherDashboard extends StatefulWidget {
  final ValueChanged<int>? onTabRequested;

  const TeacherDashboard({super.key, this.onTabRequested});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late DashboardData dashboard;
  String? _displayName;

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;
    final teacherName = _getTeacherNameFromUser(currentUser);

    _displayName = teacherName;

    dashboard = DashboardData(
      teacherName: teacherName,
      totalClasses: null,
      totalStudents: null,
      todayClasses: 2,
      todayStudents: 90,
      activeClasses: [
        ActiveClassData(
          subject: 'Mathematics',
          title: 'Grade 10 - Algebra Basics',
          description: 'Introduction to equations and variables',
          students: 32,
          color: const Color(0xFF6F5AAA),
        ),
        ActiveClassData(
          subject: 'Science',
          title: 'Biology - Cell Structure',
          description: 'Understanding animal and plant cells',
          students: 28,
          color: const Color(0xFF3A86FF),
        ),
        ActiveClassData(
          subject: 'English',
          title: 'Narrative Text',
          description: 'Reading and writing narrative paragraphs',
          students: 30,
          color: const Color(0xFFFF7B54),
        ),
      ],
    );
  }

  String _getTeacherNameFromUser(User? user) {
    if (user == null) return 'Teacher';

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return 'Teacher';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;

    Widget buildBody(String displayName) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildGreeting(displayName),
            const SizedBox(height: 20),
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildCalendar(today),
            const SizedBox(height: 24),
            _buildActiveClassesHeader(context),
            const SizedBox(height: 12),
            _buildActiveClassesList(),
          ],
        ),
      );
    }

    if (user == null) {
      return buildBody(_displayName ?? 'Teacher');
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: UserService.userStream(user.uid),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final firestoreName = (data?['displayName'] as String?)?.trim();

        if (firestoreName != null && firestoreName.isNotEmpty) {
          _displayName = firestoreName;
        } else if (_displayName == null) {
          _displayName = _getTeacherNameFromUser(user);
        }

        return buildBody(_displayName ?? 'Teacher');
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: const [
        CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFE9DFF0),
          child: Icon(Icons.person, color: Color(0xFF6F5AAA), size: 20),
        ),
        SizedBox(width: 10),
        Text(
          'Dashboard',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildGreeting(String displayName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $displayName!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'You have ${dashboard.todayClasses} classes and ${dashboard.todayStudents} students today.',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        _buildStatCard(
          title: dashboard.totalClasses?.toString() ?? '-',
          subtitle: 'Total Classes',
          icon: Icons.menu_book_rounded,
          filled: true,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          title: dashboard.totalStudents?.toString() ?? '-',
          subtitle: 'Total Students',
          icon: Icons.people_rounded,
          filled: false,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool filled,
  }) {
    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF6F5AAA) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF6F5AAA), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: filled ? Colors.white : const Color(0xFF6F5AAA),
              size: 22,
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: filled ? Colors.white : const Color(0xFF1F1F1F),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: filled ? Colors.white70 : Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(DateTime today) {
    final days = List<DateTime>.generate(
      5,
      (index) => today.subtract(Duration(days: 2 - index)),
    );

    String getDayName(int weekday) {
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return names[weekday - 1];
    }

    String getMonthName(int month) {
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return months[month - 1];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.chevron_left, color: Colors.grey),
              Text(
                '${getMonthName(today.month)} ${today.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((date) {
              final isToday =
                  date.day == today.day &&
                  date.month == today.month &&
                  date.year == today.year;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 72,
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF6F5AAA)
                        : const Color(0xFFF8F5FB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isToday
                          ? const Color(0xFF6F5AAA)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        getDayName(date.weekday),
                        style: TextStyle(
                          fontSize: 11,
                          color: isToday ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isToday ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveClassesHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Active Classes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        InkWell(
          onTap: () {
            widget.onTabRequested?.call(1);
          },
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              'See All',
              style: TextStyle(
                color: Color(0xFF6F5AAA),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveClassesList() {
    if (dashboard.activeClasses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: const [
            Icon(Icons.school_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'No active classes yet',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your active classes will appear here.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: dashboard.activeClasses
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildClassCard(item),
            ),
          )
          .toList(),
    );
  }

  Widget _buildClassCard(ActiveClassData item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 110,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    item.subject,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.color,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.groups_2_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.students} Students',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return TeacherBottomNavBar(
      activeIndex: 0,
      onItemSelected: (index) {
        widget.onTabRequested?.call(index);
      },
    );
  }
}

class DashboardData {
  final String teacherName;
  final int? totalClasses;
  final int? totalStudents;
  final int todayClasses;
  final int todayStudents;
  final List<ActiveClassData> activeClasses;

  DashboardData({
    required this.teacherName,
    required this.totalClasses,
    required this.totalStudents,
    required this.todayClasses,
    required this.todayStudents,
    required this.activeClasses,
  });
}

class ActiveClassData {
  final String subject;
  final String title;
  final String description;
  final int students;
  final Color color;

  ActiveClassData({
    required this.subject,
    required this.title,
    required this.description,
    required this.students,
    required this.color,
  });
}
