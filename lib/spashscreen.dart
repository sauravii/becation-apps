import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:becation_apps/features/auth/login_page.dart';
import 'package:becation_apps/features/teacher/teacher_root_page.dart';
import 'package:becation_apps/services/auth_service.dart';
import 'package:becation_apps/services/points_service.dart';
import 'package:becation_apps/services/user_service.dart';
import 'package:becation_apps/features/student/student_root_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _checkAuthState();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final user = AuthService.currentUser;

    Widget targetPage;

    if (user == null) {
      targetPage = const LoginPage();
    } else {
      final isRegistered = await UserService.isUserRegistered(user.uid);
      if (!isRegistered) {
        await AuthService.signOut();
        targetPage = const LoginPage();
      } else {
        // Pastikan FirebaseAuth.displayName sudah sinkron dengan Firestore
        // supaya dashboard langsung pakai nama, bukan fallback 'Student'.
        await UserService.syncAuthDisplayNameFromFirestore(user);

        // Fire-and-forget daily streak ping. Backend idempotent untuk hari yang
        // sama jadi aman dipanggil tiap cold-start. Gak block navigation.
        PointsService.ping().catchError((e) {
          debugPrint('[splash] streak ping failed: $e');
          return PingResult(
            streakDay: 0,
            longestStreak: 0,
            isNewDay: false,
            pointAwarded: 0,
            milestoneReached: null,
            overachieverEarned: false,
          );
        });

        final role = await UserService.getUserRole(user.uid);

        switch (role) {
          case 'teacher':
            targetPage = TeacherRootPage();
            break;
          case 'student':
          default:
            targetPage = const StudentRootPage();
            break;
        }
      }
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, animation, __) => targetPage,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("lib/assets/front_ui.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("lib/assets/bee_logo.png", width: 220),
              const SizedBox(height: 20),
              const Text(
                "BECATION",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "BETTER EDUCATION",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
