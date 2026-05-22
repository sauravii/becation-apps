import 'package:flutter/material.dart';

import 'studentdashboard_page.dart';
import 'student_classes_page.dart';
import 'student_profile_page.dart';
import 'student_bottom_nav.dart';

class StudentRootPage extends StatefulWidget {
  const StudentRootPage({super.key});

  @override
  State<StudentRootPage> createState() => _StudentRootPageState();
}

class _StudentRootPageState extends State<StudentRootPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _onNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    _pageController.jumpToPage(index);
  }

  void _onRequestTab(int index) {
    _onNavTap(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StudentDashboard(onTabRequested: _onRequestTab),
                  StudentClassesPage(onTabRequested: _onRequestTab),
                  StudentProfilePage(onTabRequested: _onRequestTab),
                ],
              ),
            ),
            StudentBottomNavBar(
              activeIndex: _currentIndex,
              onItemSelected: _onNavTap,
            ),
          ],
        ),
      ),
    );
  }
}
