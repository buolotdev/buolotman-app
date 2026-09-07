import 'package:flutter/material.dart';
import 'dart:async';

import 'screens/onboarding_screen.dart';
import 'screens/technician_dashboard_screen.dart';
import 'screens/client_dashboard_screen.dart';
import 'screens/company_dashboard_screen.dart';
import 'core/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('backend_ip_override');
  } catch (e) {
    debugPrint('Failed to load backend IP override: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        _checkAutoLogin();
      }
    });
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');
    final String? role = prefs.getString('user_role');

    if (token != null && token.isNotEmpty && role != null && role.isNotEmpty) {
      try {
        // Validate the persisted session before routing. A deleted account can
        // leave an old JWT on the device, which must not reopen the dashboard.
        await ApiService().profile();
        // Do not let the legacy global-state sync decide the launch route.
        // Technicians must open the rebuilt technician dashboard directly.
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => role.toUpperCase() == 'TECHNICIAN'
                  ? const TechnicianDashboardScreen()
                  : role.toUpperCase() == 'CLIENT'
                      ? const ClientDashboardScreen()
                      : role.toUpperCase() == 'COMPANY'
                          ? const CompanyDashboardScreen()
                          : const OnboardingScreen(),
            ),
          );
          return;
        }
      } catch (e) {
        // Token might be invalid or expired. Clear session and fallback.
        await ApiService().clearSession();
      }
    }

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
