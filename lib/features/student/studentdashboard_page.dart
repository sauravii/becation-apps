import 'package:becation_apps/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'student_classes_page.dart';
import 'student_classes_detail.dart';
import 'student_settings_page.dart';
import '../../components/cards/stat_card.dart';
import '../../components/cards/dashboard_class_card.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late DashboardData dashboard;

  @override
  void initState() {
    super.initState();

    dashboard = DashboardData(
      teacherName: 'Student',
      totalClasses: null,
      totalQuizzes: null,
      todayClasses: 2,
      todayQuizzes: 3,
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

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;

    Widget buildBody(String displayName) {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
            ),
          ),
          _buildBottomNav(),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      body: SafeArea(
        child: user == null
            ? buildBody('Student')
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: UserService.userStream(user.uid),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final firestoreName = (data?['displayName'] as String?)
                      ?.trim();

                  final displayName =
                      (firestoreName != null && firestoreName.isNotEmpty)
                      ? firestoreName
                      : (user.displayName?.trim().isNotEmpty == true
                            ? user.displayName!.trim()
                            : (user.email ?? 'Student'));

                  return buildBody(displayName);
                },
              ),
      ),
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
          'You have ${dashboard.todayClasses} classes and ${dashboard.todayQuizzes} quizzes today.',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        StatCard(
          title: dashboard.totalClasses?.toString() ?? '-',
          subtitle: 'Total Classes',
          icon: Icons.menu_book_rounded,
          filled: true,
        ),
        const SizedBox(width: 12),
        StatCard(
          title: dashboard.totalQuizzes?.toString() ?? '-',
          subtitle: 'Total Quizzes',
          icon: Icons.assignment_rounded,
          filled: false,
        ),
      ],
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
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const StudentClassesPage()),
            );
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
              child: DashboardClassCard(
                title: item.title,
                subject: item.subject,
                description: item.description,
                color: item.color,
                students: item.students,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentClassesDetail(
                        classTitle: item.title,
                        classColor: item.color,
                      ),
                    ),
                  );
                },
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            active: true,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.class_rounded,
            label: 'Classes',
            active: false,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const StudentClassesPage()),
              );
            },
          ),
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            active: false,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const StudentSettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DashboardData {
  final String teacherName;
  final int? totalClasses;
  final int? totalQuizzes;
  final int todayClasses;
  final int todayQuizzes;
  final List<ActiveClassData> activeClasses;

  DashboardData({
    required this.teacherName,
    required this.totalClasses,
    required this.totalQuizzes,
    required this.todayClasses,
    required this.todayQuizzes,
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF6F5AAA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? activeColor : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? activeColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
