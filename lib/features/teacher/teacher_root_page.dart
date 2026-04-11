import 'package:flutter/material.dart';

import 'teacherdashboard_page.dart';
import 'teacher_classes_page.dart';
import 'teacher_settings_page.dart';
import 'teacher_bottom_nav.dart';

class TeacherRootPage extends StatefulWidget {
  const TeacherRootPage({super.key});

  @override
  State<TeacherRootPage> createState() => _TeacherRootPageState();
}

class _TeacherRootPageState extends State<TeacherRootPage> {
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
                  TeacherDashboard(onTabRequested: _onRequestTab),
                  TeacherClassesPage(onTabRequested: _onRequestTab),
                  TeacherSettingsPage(onTabRequested: _onRequestTab),
                ],
              ),
            ),
            TeacherBottomNavBar(
              activeIndex: _currentIndex,
              onItemSelected: _onNavTap,
            ),
          ],
        ),
      ),
    );
  }
}
