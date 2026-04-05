import 'package:becation_apps/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:becation_apps/services/user_service.dart';
import 'package:becation_apps/features/home/home_page.dart';

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
  bool isGoogleLoading = false;

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

    if (nameError == null && emailError == null && passwordError == null && termsError == null) {
      await _registerWithEmail();
    }
  }

  Future<void> _registerWithEmail() async {
    setState(() => isEmailLoading = true);
    
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (credential.user != null) {
        await UserService.ensureUserDocument(
          credential.user!,
          displayName: fullNameController.text.trim(),
        );
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
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

  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _signInWithGoogle() async {
    setState(() => isGoogleLoading = true);
    
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => isGoogleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await UserService.ensureUserDocument(userCredential.user!);
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
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
      setState(() => isGoogleLoading = false);
    }
  }

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

  Widget buildError(String? error) {
    return SizedBox(
      height: 20.h,
      child: Padding(
        padding: EdgeInsets.only(left: 54.w),
        child: Text(
          error ?? "",
          style: TextStyle(color: Colors.red, fontSize: 12.sp),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      body: SafeArea(
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
                      style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30.h),

              /// FULL NAME
              Transform.translate(
                offset: Offset(0, 15.h),
                child: Padding(
                  padding: EdgeInsets.only(left: 54.w),
                  child: Text(
                    "Full Name",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  buildIcon(Icons.person),
                  Expanded(
                    child: TextField(
                      controller: fullNameController,
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                    ),
                  ),
                ],
              ),

              buildError(nameError),

              /// EMAIL
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

              Row(
                children: [
                  buildIcon(Icons.email),
                  Expanded(
                    child: TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                    ),
                  ),
                ],
              ),

              buildError(emailError),

              /// PASSWORD
              Transform.translate(
                offset: Offset(0, 15.h),
                child: Padding(
                  padding: EdgeInsets.only(left: 54.w),
                  child: Text(
                    "Password",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  buildIcon(Icons.lock),
                  Expanded(
                    child: TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              buildError(passwordError),

              SizedBox(height: 10.h),

              /// TERMS
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
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ),

              SizedBox(height: 10.h),

              /// GENERAL ERROR MESSAGE
              if (generalError != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
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

              /// SIGN UP BUTTON
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: isEmailLoading ? null : validateRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF875DFC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: isEmailLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          "Sign Up",
                          style: TextStyle(fontSize: 16.sp, color: Colors.white),
                        ),
                ),
              ),

              const Spacer(),

              /// OR
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

              /// GOOGLE LOGIN
              Center(
                child: InkWell(
                  onTap: isGoogleLoading ? null : _signInWithGoogle,
                  borderRadius: BorderRadius.circular(50.r),
                  child: Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF875DFC).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: isGoogleLoading
                        ? Center(
                            child: SizedBox(
                              height: 20.h,
                              width: 20.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF875DFC)),
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
                      child: Text("Log In", style: TextStyle(fontSize: 14.sp)),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 50.h),
            ],
          ),
        ),
      ),
    );
  }
}
