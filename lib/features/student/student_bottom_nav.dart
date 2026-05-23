import 'package:flutter/material.dart';

class StudentBottomNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onItemSelected;

  const StudentBottomNavBar({
    super.key,
    required this.activeIndex,
    required this.onItemSelected,
  });

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
          _StudentNavItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            active: activeIndex == 0,
            onTap: () => onItemSelected(0),
          ),
          _StudentNavItem(
            icon: Icons.class_rounded,
            label: 'Classes',
            active: activeIndex == 1,
            onTap: () => onItemSelected(1),
          ),
          _StudentNavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            active: activeIndex == 2,
            onTap: () => onItemSelected(2),
          ),
        ],
      ),
    );
  }
}

class _StudentNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _StudentNavItem({
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
