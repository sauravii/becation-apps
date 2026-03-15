import 'package:becation_apps/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  String? nameError;
  String? emailError;
  String? passwordError;
  String? termsError;

  void validateRegister() {
    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
      termsError = null;

      if (fullNameController.text.trim().isEmpty) {
        nameError = "Nama wajib diisi";
      }

      if (emailController.text.trim().isEmpty) {
        emailError = "Email wajib diisi";
      } else if (!emailController.text.contains("@")) {
        emailError = "Email tidak sesuai";
      }

      if (passwordController.text.isEmpty) {
        passwordError = "Password wajib diisi";
      } else if (passwordController.text.length < 6) {
        passwordError = "Password minimal 6 karakter";
      }

      if (!agreeTerms) {
        termsError = "Anda harus menyetujui terms";
      }
    });
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

              SizedBox(height: 30.h),

              /// SIGN UP BUTTON
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: validateRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF875DFC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 16.sp, color: Colors.white),
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
