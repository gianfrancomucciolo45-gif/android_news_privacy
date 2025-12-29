import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const AnimatedSplashScreen({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        widget.onAnimationComplete();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2962FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cerchio animato con icona
            Stack(
              alignment: Alignment.center,
              children: [
                // Cerchio sfondo (animazione Lottie)
                Lottie.asset(
                  'assets/animations/splash_screen.json',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                  repeat: false,
                  controller: _controller,
                ),
                // Icona dell'app al centro
                ScaleTransition(
                  scale: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
                      ),
                    ),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Titolo dell'app
            FadeTransition(
              opacity: _controller,
              child: const Text(
                'Android News',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Sottotitolo
            FadeTransition(
              opacity: _controller,
              child: const Text(
                'Le ultime notizie sempre con te',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
