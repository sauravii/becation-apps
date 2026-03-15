import 'package:becation_apps/features/auth/login_page.dart';
import 'package:becation_apps/features/auth/verify_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ForgotpassPage extends StatefulWidget {
  const ForgotpassPage({super.key});

  @override
  State<ForgotpassPage> createState() => _ForgotpassPageState();
}

class _ForgotpassPageState extends State<ForgotpassPage> {
  final emailController = TextEditingController();

  String? emailError;

  Widget buildIcon(IconData icon) {
    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: const Color(0xFF875DFC).withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF875DFC), size: 22.sp),
      ),
    );
  }

  void validateEmail() {
    setState(() {
      emailError = null;

      if (emailController.text.trim().isEmpty) {
        emailError = "Email wajib diisi";
      } else if (!emailController.text.contains("@")) {
        emailError = "Email tidak sesuai";
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VerifyPage()),
        );
      }
    });
  }

  Widget buildError(String? error) {
    return SizedBox(
      height: 20.h,
      child: Padding(
        padding: EdgeInsets.only(left: 54.w),
        child: Text(
          error ?? "",
          style: TextStyle(
            color: Colors.red,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 30.h),

                        /// BACK BUTTON
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.arrow_back_sharp, size: 24.sp),
                        ),

                        SizedBox(height: 10.h),

                        /// HEADER
                        Center(
                          child: Column(
                            children: [
                              Text(
                                "Forgot Password",
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                "Let's help you with that!",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30.h),

                        /// EMAIL LABEL
                        Transform.translate(
                          offset: Offset(0, 15.h),
                          child: Padding(
                            padding: EdgeInsets.only(left: 54.w),
                            child: Text(
                              "Email Address",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 6.h),

                        /// EMAIL FIELD
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                buildIcon(Icons.email),
                                Expanded(
                                  child: TextField(
                                    controller: emailController,
                                    decoration: InputDecoration(
                                      border: const UnderlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 16.h,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            buildError(emailError),
                          ],
                        ),

                        SizedBox(height: 90.h),

                        /// SEND CODE BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: validateEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF875DFC),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                            ),
                            child: Text(
                              "Send Code",
                              style: TextStyle(fontSize: 16.sp),
                            ),
                          ),
                        ),

                        const Spacer(),

                        /// LOGIN SWITCH
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: TextStyle(fontSize: 14.sp),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Log In",
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 50.h),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}