import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _items = [
    (
      'assets/images/onboard1.jpg',
      'Post tasks easily',
      'Describe what you need done and receive bids from qualified professionals.',
    ),
    (
      'assets/images/onboard2_new.jpg',
      'Hire trusted professionals',
      'Connect with skilled experts ready to get your job done efficiently.',
    ),
    (
      'assets/images/onboard3_new.jpg',
      'Secure payments',
      'Your funds stay protected until the task is completed to your satisfaction.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _items.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _items.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        _items[index].$1,
                        height: 280,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 36),
                      Text(
                        _items[index].$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF001F3F),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _items[index].$3,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(
                    _page == _items.length - 1 ? 'Get started' : 'Continue',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
