import 'package:becation_apps/features/auth/login_page.dart';
import 'package:becation_apps/features/auth/verify_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/forms/auth_text_field.dart';
import '../../components/buttons/auth_button.dart';

class ForgotpassPage extends StatefulWidget {
  const ForgotpassPage({super.key});

  @override
  State<ForgotpassPage> createState() => _ForgotpassPageState();
}

class _ForgotpassPageState extends State<ForgotpassPage> {
  final emailController = TextEditingController();

  String? emailError;

  void validateEmail() {
    setState(() {
      emailError = null;

      if (emailController.text.trim().isEmpty) {
        emailError = "Email is required.";
      } else if (!emailController.text.contains("@")) {
        emailError = "Please enter a valid email address.";
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VerifyPage()),
        );
      }
    });
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

                        AuthTextField(
                          controller: emailController,
                          labelText: "Email Address",
                          icon: Icons.email,
                          errorText: emailError,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        SizedBox(height: 90.h),

                        AuthButton(text: "Send Code", onPressed: validateEmail),

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
