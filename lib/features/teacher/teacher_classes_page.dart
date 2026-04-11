import 'package:flutter/material.dart';

import 'teacherdashboard_page.dart';
import 'teacher_settings_page.dart';
import 'teacher_classes_detail.dart';

class TeacherClassesPage extends StatelessWidget {
  const TeacherClassesPage({super.key});

  List<ActiveClassData> _buildDummyActiveClasses() {
    return [
      ActiveClassData(
        subject: "Mathematics",
        title: "Grade 10 - Algebra Basics",
        description: "Introduction to equations and variables",
        students: 32,
        color: const Color(0xFF6F5AAA),
      ),
      ActiveClassData(
        subject: "Science",
        title: "Biology - Cell Structure",
        description: "Understanding animal and plant cells",
        students: 28,
        color: const Color(0xFF3A86FF),
      ),
      ActiveClassData(
        subject: "English",
        title: "Narrative Text",
        description: "Reading and writing narrative paragraphs",
        students: 30,
        color: const Color(0xFFFF7B54),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeClasses = _buildDummyActiveClasses();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(title: 'Classes'),
                        const SizedBox(height: 24),
                        if (activeClasses.isEmpty)
                          _EmptyState()
                        else
                          Column(
                            children: activeClasses
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ClassCard(item: item),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                _BottomNav(activeIndex: 1),
              ],
            ),
            Positioned(
              right: 20,
              bottom: bottomInset + 100,
              child: FloatingActionButton(
                heroTag: 'teacher_classes_add',
                backgroundColor: const Color(0xFF6F5AAA),
                foregroundColor: Colors.white,
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;

  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFE9DFF0),
          child: Icon(Icons.person, color: Color(0xFF6F5AAA), size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            "No active classes yet",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Your active classes will appear here.",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ActiveClassData item;

  const _ClassCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TeacherClassesDetail(
                classTitle: item.title,
                classColor: item.color,
              ),
            ),
          );
        },
        child: Container(
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
                          "${item.students} Students",
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
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int activeIndex;

  const _BottomNav({required this.activeIndex});

  void _go(BuildContext context, int index) {
    if (index == activeIndex) return;

    final page = switch (index) {
      0 => const TeacherDashboard(),
      1 => const TeacherClassesPage(),
      _ => const TeacherSettingsPage(),
    };

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
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
            active: activeIndex == 0,
            onTap: () => _go(context, 0),
          ),
          _NavItem(
            icon: Icons.class_rounded,
            label: 'Classes',
            active: activeIndex == 1,
            onTap: () => _go(context, 1),
          ),
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            active: activeIndex == 2,
            onTap: () => _go(context, 2),
          ),
        ],
      ),
    );
  }
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
