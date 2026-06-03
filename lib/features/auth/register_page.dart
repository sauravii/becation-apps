import 'package:becation_apps/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:becation_apps/services/auth_service.dart';
import 'package:becation_apps/services/user_service.dart';
import '../../components/forms/auth_text_field.dart';
import '../../components/buttons/auth_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool agreeTerms = false;
  bool isEmailLoading = false;

  String? nameError;
  String? emailError;
  String? passwordError;
  String? termsError;
  String? generalError;

  void validateRegister() async {
    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
      termsError = null;
      generalError = null;

      if (fullNameController.text.trim().isEmpty) {
        nameError = "Full name is required.";
      }

      if (emailController.text.trim().isEmpty) {
        emailError = "Email is required.";
      } else if (!emailController.text.contains("@")) {
        emailError = "Please enter a valid email address.";
      }

      if (passwordController.text.isEmpty) {
        passwordError = "Password is required.";
      } else if (passwordController.text.length < 6) {
        passwordError = "Password must be at least 6 characters long.";
      }

      if (!agreeTerms) {
        termsError = "You must agree to the terms.";
      }
    });

    if (nameError == null &&
        emailError == null &&
        passwordError == null &&
        termsError == null) {
      await _registerWithEmail();
    }
  }

  Future<void> _registerWithEmail() async {
    setState(() => isEmailLoading = true);

    try {
      final user = await AuthService.createAccount(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (user != null) {
        await UserService.ensureUserDocument(
          user,
          displayName: fullNameController.text.trim(),
        );

        await AuthService.signOut();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginPage(
                successMessage:
                    "Registration successful! Please log in to continue.",
              ),
            ),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'weak-password':
            generalError = 'The password provided is too weak.';
            break;
          case 'email-already-in-use':
            generalError = 'An account already exists for this email.';
            break;
          case 'invalid-email':
            generalError = 'Invalid email address.';
            break;
          case 'operation-not-allowed':
            generalError = 'Email/password accounts are not enabled.';
            break;
          case 'too-many-requests':
            generalError = 'Too many requests. Try again later.';
            break;
          default:
            generalError = 'Registration failed: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        generalError = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() => isEmailLoading = false);
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

                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.arrow_back_sharp, size: 24.sp),
                        ),

                        SizedBox(height: 10.h),

                        Center(
                          child: Column(
                            children: [
                              Text(
                                "Create an Account",
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                "Let's get you started!",
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
                          controller: fullNameController,
                          labelText: "Full Name",
                          icon: Icons.person,
                          errorText: nameError,
                        ),

                        AuthTextField(
                          controller: emailController,
                          labelText: "Email Address",
                          icon: Icons.email,
                          errorText: emailError,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        AuthTextField(
                          controller: passwordController,
                          labelText: "Password",
                          icon: Icons.lock,
                          errorText: passwordError,
                          obscureText: obscurePassword,
                          onToggleObscure: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),

                        SizedBox(height: 10.h),

                        Row(
                          children: [
                            Checkbox(
                              value: agreeTerms,
                              activeColor: const Color(0xFF875DFC),
                              onChanged: (value) {
                                setState(() {
                                  agreeTerms = value!;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                "I agree to the terms & conditions",
                                style: TextStyle(fontSize: 13.sp),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(
                          height: 18.h,
                          child: Text(
                            termsError ?? "",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),

                        SizedBox(height: 10.h),

                        if (generalError != null)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.w),
                            margin: EdgeInsets.only(bottom: 20.h),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              generalError!,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        AuthButton(
                          text: "Sign Up",
                          onPressed: validateRegister,
                          isLoading: isEmailLoading,
                        ),

                        const Spacer(),

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
