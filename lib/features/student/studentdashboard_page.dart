import 'package:becation_apps/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/class_model.dart';
import '../../services/class_service.dart';
import 'student_classes_detail.dart';
import '../../components/cards/stat_card.dart';
import '../../components/cards/dashboard_class_card.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key, this.onTabRequested});

  final ValueChanged<int>? onTabRequested;

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String? _displayName;
  late final Stream<List<ClassModel>> _classesStream;

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;
    _displayName = _getStudentNameFromUser(currentUser);

    _classesStream = currentUser != null
        ? ClassService.studentClassesStream(currentUser.uid)
        : const Stream.empty();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;

    Widget buildBody(String displayName, List<ClassModel> classes) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildGreeting(displayName, classes.length),
            const SizedBox(height: 20),
            _buildStatsSection(classes),
            const SizedBox(height: 24),
            _buildCalendar(today),
            const SizedBox(height: 24),
            _buildActiveClassesHeader(),
            const SizedBox(height: 12),
            _buildActiveClassesList(classes),
          ],
        ),
      );
    }

    if (user == null) {
      return buildBody(_displayName ?? 'Student', []);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: UserService.userStream(user.uid),
      builder: (context, userSnapshot) {
        final data = userSnapshot.data?.data();
        final firestoreName = (data?['displayName'] as String?)?.trim();

        if (firestoreName != null && firestoreName.isNotEmpty) {
          _displayName = firestoreName;
        } else if (_displayName == null) {
          _displayName = _getStudentNameFromUser(user);
        }

        return StreamBuilder<List<ClassModel>>(
          stream: _classesStream,
          builder: (context, classesSnapshot) {
            final classes = classesSnapshot.data ?? [];
            return buildBody(_displayName ?? 'Student', classes);
          },
        );
      },
    );
  }

  String _getStudentNameFromUser(User? user) {
    if (user == null) return 'Student';

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    return 'Student';
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

  Widget _buildGreeting(String displayName, int classCount) {
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
          'You have $classCount classes enrolled.',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatsSection(List<ClassModel> classes) {
    return Row(
      children: [
        StatCard(
          title: classes.length.toString(),
          subtitle: 'Total Classes',
          icon: Icons.menu_book_rounded,
          filled: true,
        ),
        const SizedBox(width: 12),
        StatCard(
          title: '-',
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

  Widget _buildActiveClassesHeader() {
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

  Widget _buildActiveClassesList(List<ClassModel> classes) {
    if (classes.isEmpty) {
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
              'Join a class to get started.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: classes
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DashboardClassCard(
                title: item.title,
                subject: item.subject,
                description: item.description,
                color: item.color,
                students: item.studentCount,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentClassesDetail(
                        classId: item.id,
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
}
