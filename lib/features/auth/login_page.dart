import 'package:becation_apps/features/auth/forgot_page.dart';
import 'package:flutter/material.dart';
import 'package:becation_apps/features/auth/register_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:becation_apps/services/user_service.dart';
import 'package:becation_apps/features/student/studentdashboard_page.dart';
import 'package:becation_apps/features/teacher/teacherdashboard_page.dart';
import '../../components/forms/auth_text_field.dart';
import '../../components/buttons/auth_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isEmailLoading = false;
  bool isGoogleLoading = false;

  String? emailError;
  String? passwordError;
  String? generalError;

  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void validateLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    setState(() {
      emailError = null;
      passwordError = null;
      generalError = null;

      if (email.isEmpty) {
        emailError = "Email is required.";
      } else if (!_isValidEmail(email)) {
        emailError = "Please enter a valid email address.";
      }

      if (password.isEmpty) {
        passwordError = "Password is required.";
      } else if (password.length < 6) {
        passwordError = "Password must be at least 6 characters long.";
      }
    });

    if (emailError == null && passwordError == null) {
      await _signInWithEmail();
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  Future<void> _navigateByRole(User user) async {
    final role = await UserService.getUserRole(user.uid);

    if (!mounted) return;

    Widget targetPage;

    switch (role) {
      case 'teacher':
        targetPage = const TeacherDashboard();
        break;
      case 'student':
      default:
        targetPage = const StudentDashboard();
        break;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => targetPage),
      (route) => false,
    );
  }

  Future<void> _signInWithEmail() async {
    setState(() => isEmailLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (credential.user != null) {
        await UserService.ensureUserDocument(credential.user!);
        await _navigateByRole(credential.user!);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'invalid-credential':
            generalError = 'Email or password is incorrect.';
            break;
          case 'user-not-found':
            generalError = 'No user found for this email.';
            break;
          case 'wrong-password':
            generalError = 'Wrong password provided.';
            break;
          case 'invalid-email':
            generalError = 'Invalid email address.';
            break;
          case 'user-disabled':
            generalError = 'This user account has been disabled.';
            break;
          case 'too-many-requests':
            generalError = 'Too many requests. Try again later.';
            break;
          default:
            generalError = 'Login failed: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        generalError = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => isEmailLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      isGoogleLoading = true;
      generalError = null;
    });

    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) {
          setState(() => isGoogleLoading = false);
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        await UserService.ensureUserDocument(userCredential.user!);
        await _navigateByRole(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        generalError = 'Google sign in failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        generalError = 'An unexpected error occurred during Google sign in.';
      });
    } finally {
      if (mounted) {
        setState(() => isGoogleLoading = false);
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
                        SizedBox(height: 90.h),

                        Center(
                          child: Column(
                            children: [
                              Text(
                                "Welcome back",
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                "Good to See You!",
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

                        SizedBox(height: 20.h),

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

                        SizedBox(height: 20.h),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotpassPage(),
                                ),
                              );
                            },
                            child: Text(
                              "Forgot Password",
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        ),

                        SizedBox(height: 20.h),

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
                          text: "Log In",
                          onPressed: validateLogin,
                          isLoading: isEmailLoading,
                        ),

                        SizedBox(height: 30.h),

                        Center(
                          child: Text(
                            "or",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        SizedBox(height: 30.h),

                        Center(
                          child: InkWell(
                            onTap: isGoogleLoading ? null : _signInWithGoogle,
                            borderRadius: BorderRadius.circular(50.r),
                            child: Container(
                              width: 52.w,
                              height: 52.w,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF875DFC,
                                ).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: isGoogleLoading
                                  ? Center(
                                      child: SizedBox(
                                        height: 20.h,
                                        width: 20.h,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Color(0xFF875DFC)),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Image.network(
                                        "https://cdn-icons-png.flaticon.com/512/281/281764.png",
                                        width: 26.w,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(fontSize: 14.sp),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Sign Up",
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
