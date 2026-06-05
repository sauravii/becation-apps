import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:becation_apps/services/auth_service.dart';
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
  String? generalMessage;
  bool isSuccess = false;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // Validasi email lalu kirim link reset password via Firebase Auth.
  Future<void> _sendResetLink() async {
    final email = emailController.text.trim();

    setState(() {
      emailError = null;
      generalMessage = null;
      isSuccess = false;

      if (email.isEmpty) {
        emailError = "Email is required.";
      } else if (!email.contains("@")) {
        emailError = "Please enter a valid email address.";
      }
    });

    if (emailError != null) return;

    setState(() => isLoading = true);

    try {
      await AuthService.sendPasswordReset(email);
      if (mounted) {
        setState(() {
          isSuccess = true;
          generalMessage =
              'Password reset link has been sent to your email. Please check your inbox or spam folder.';
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          isSuccess = false;
          switch (e.code) {
            case 'user-not-found':
              generalMessage = 'No account found for this email.';
              break;
            case 'invalid-email':
              generalMessage = 'Invalid email address.';
              break;
            case 'too-many-requests':
              generalMessage = 'Too many requests. Please try again later.';
              break;
            default:
              generalMessage = 'Failed to send reset link. Please try again.';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isSuccess = false;
          generalMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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
                                "Enter your email and we'll send you a reset link.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14.sp,
                                ),
                                textAlign: TextAlign.center,
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

                        SizedBox(height: 16.h),

                        /// SUCCESS / ERROR MESSAGE
                        if (generalMessage != null)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.w),
                            margin: EdgeInsets.only(bottom: 16.h),
                            decoration: BoxDecoration(
                              color: isSuccess
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: isSuccess
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              generalMessage!,
                              style: TextStyle(
                                color: isSuccess ? Colors.green : Colors.red,
                                fontSize: 14.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        SizedBox(height: 20.h),

                        AuthButton(
                          text: "Send Reset Link",
                          onPressed: _sendResetLink,
                          isLoading: isLoading,
                        ),

                        const Spacer(),

                        /// LOGIN SWITCH
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Remember your password? ",
                                style: TextStyle(fontSize: 14.sp),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
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
