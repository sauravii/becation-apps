import 'package:becation_apps/spashscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'features/auth/firebase_options.dart';

// Hai :3

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Becation Apps',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      builder: (context, child) {
        return Container(
          color: Colors.grey[100], // Background luar HP
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.contain, // Skalakan keseluruhan HP seperti gambar agar muat di layar
            child: Container(
              width: 402,
              height: 874,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: MediaQuery(
                // PAKSA MediaQuery agar selalu berukuran 402x874 apapun ukuran browsernya.
                data: MediaQuery.of(context).copyWith(
                  size: const Size(402, 874),
                ),
                child: ScreenUtilInit(
                  designSize: const Size(402, 874),
                  minTextAdapt: true,
                  splitScreenMode: true,
                  useInheritedMediaQuery: true,
                  builder: (context, widget) {
                    return GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: widget,
                    );
                  },
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}
