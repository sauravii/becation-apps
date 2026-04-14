import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'auth_icon.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final VoidCallback? onToggleObscure;
  final Color? iconColor;
  final Color? backgroundColor;

  const AuthTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.onToggleObscure,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Padding(
            padding: EdgeInsets.only(left: 54.w),
            child: Text(
              labelText!,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        
        if (labelText != null) SizedBox(height: 6.h),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AuthIcon(
              icon: icon,
              iconColor: iconColor,
              backgroundColor: backgroundColor,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: const UnderlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ),
            if (onToggleObscure != null)
              IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: onToggleObscure,
              ),
          ],
        ),
        
        SizedBox(
          height: 20.h,
          child: Padding(
            padding: EdgeInsets.only(left: 54.w),
            child: Text(
              errorText ?? "",
              style: TextStyle(
                color: Colors.red,
                fontSize: 12.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
