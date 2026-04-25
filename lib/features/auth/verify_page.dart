// ==========================================================================
// FILE INI BELUM DIPAKAI — OTP verification untuk forgot password.
// Saat ini forgot password menggunakan link-based reset bawaan Firebase Auth.
// File ini disiapkan untuk sprint berikutnya jika ingin migrasi ke OTP-based
// reset password (butuh backend: Cloud Functions + email service).
// ==========================================================================

import 'dart:async';

import 'package:becation_apps/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final List<TextEditingController> otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  Timer? timer;
  int secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    for (var c in otpControllers) {
      c.dispose();
    }

    for (var f in focusNodes) {
      f.dispose();
    }

    timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    secondsRemaining = 60;

    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining == 0) {
        t.cancel();
      } else {
        setState(() {
          secondsRemaining--;
        });
      }
    });
  }

  void resendOtp() {
    if (secondsRemaining > 0) return;

    /// TODO: API resend OTP
    print("OTP resent");

    startTimer();
  }

  void verifyOtp() {
    String otp = otpControllers.map((c) => c.text).join();

    if (otp.length == 4) {
      print("OTP Verified: $otp");

      /// lanjut ke reset password
    }
  }

  void handleOtpChange(String value, int index) {
    /// paste support
    if (value.length > 1) {
      for (int i = 0; i < value.length && i < 4; i++) {
        otpControllers[i].text = value[i];
      }

      FocusScope.of(context).unfocus();
      verifyOtp();
      return;
    }

    /// next field
    if (value.isNotEmpty && index < 3) {
      focusNodes[index + 1].requestFocus();
    }

    /// auto verify
    String otp = otpControllers.map((c) => c.text).join();

    if (otp.length == 4) {
      verifyOtp();
    }
  }

  Widget buildOtpField(int index) {
    return SizedBox(
      width: 55.w,
      child: TextField(
        controller: otpControllers[index],
        focusNode: focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF875DFC), width: 2),
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        onChanged: (value) => handleOtpChange(value, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool canResend = secondsRemaining == 0;

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
                      "Verify Now",
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "Check your email for the verification code!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => buildOtpField(index)),
              ),

              SizedBox(height: 20.h),

              /// RESEND CODE (60)
              Center(
                child: GestureDetector(
                  onTap: canResend ? resendOtp : null,
                  child: Text(
                    "Resend Code ($secondsRemaining)",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: canResend ? const Color(0xFF875DFC) : Colors.grey,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 80.h),

              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF875DFC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: Text("Verify", style: TextStyle(fontSize: 16.sp)),
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
