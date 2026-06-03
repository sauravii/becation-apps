import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthIcon extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;

  const AuthIcon({
    super.key,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: (backgroundColor ?? const Color(0xFF875DFC)).withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon, 
          color: iconColor ?? const Color(0xFF875DFC), 
          size: 22.sp
        ),
      ),
    );
  }
}
