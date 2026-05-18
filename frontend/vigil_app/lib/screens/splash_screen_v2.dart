import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';
import '../widgets/neo_glass_card.dart';

/// Premium V2 Splash Screen with animated holographic branding,
/// orbiting particle rings, and cinematic entrance animations.
class SplashScreenV2 extends StatefulWidget {
  const SplashScreenV2({super.key});

  @override
  State<SplashScreenV2> createState() => _SplashScreenV2State();
}

class _SplashScreenV2State extends State<SplashScreenV2>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _orbitController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _orbitController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _textController.forward();
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _orbitController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: VigilThemeV2.backgroundGradient),
        child: Stack(
          children: [
            // Background star particles
            ..._buildStars(),

            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo with orbiting rings
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoController, _orbitController]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: SizedBox(
                            width: 220,
                            height: 220,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer orbital ring
                                Transform.rotate(
                                  angle: _orbitController.value * 2 * pi,
                                  child: _buildOrbitRing(200, VigilThemeV2.neonCyan),
                                ),
                                // Inner reverse ring
                                Transform.rotate(
                                  angle: -_orbitController.value * 2 * pi * 1.5,
                                  child: _buildOrbitRing(160, VigilThemeV2.violetNeon),
                                ),
                                // Core shield
                                const NeonPulse(
                                  size: 110,
                                  color: VigilThemeV2.neonCyan,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),

                  // Holographic VIGIL text
                  FadeTransition(
                    opacity: _textOpacity,
                    child: const Column(
                      children: [
                        HoloText(
                          text: 'VIGIL',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 12,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'AI-POWERED SAFETY',
                          style: TextStyle(
                            fontSize: 11,
                            color: VigilThemeV2.textMuted,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom loader
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textOpacity,
                child: const Column(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VigilThemeV2.neonCyan,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Initializing AI Safety Engine...',
                      style: TextStyle(
                        fontSize: 11,
                        color: VigilThemeV2.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbitRing(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: size / 2 - 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStars() {
    final random = Random(42);
    return List.generate(40, (i) {
      final dx = random.nextDouble();
      final dy = random.nextDouble();
      final size = random.nextDouble() * 2 + 0.5;
      final opacity = random.nextDouble() * 0.6 + 0.2;
      return Positioned(
        left: dx * MediaQuery.of(context).size.width,
        top: dy * MediaQuery.of(context).size.height,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: VigilThemeV2.neonCyan.withOpacity(opacity),
          ),
        ),
      );
    });
  }
}
