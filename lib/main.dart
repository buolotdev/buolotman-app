import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';

import 'app_state.dart';
import 'onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(AppState(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AppState>()) {
      Get.put(AppState(), permanent: true);
    }
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F), // Background: var(--primary)
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            
            // Centered Logo
            Center(
              child: Image.asset(
                'assets/images/boulotman-logo.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
                // Fallback just in case the image isn't placed yet
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image,
                    color: Colors.white54,
                    size: 100,
                  );
                },
              ),
            ),
            
            const Spacer(),
            
            // Loading Animation at the bottom
            const Padding(
              padding: EdgeInsets.only(bottom: 40.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)), // Accent color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
