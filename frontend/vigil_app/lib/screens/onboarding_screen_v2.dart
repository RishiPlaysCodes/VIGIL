import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';
import '../widgets/neo_glass_card.dart';

class OnboardingScreenV2 extends StatefulWidget {
  const OnboardingScreenV2({super.key});

  @override
  State<OnboardingScreenV2> createState() => _OnboardingScreenV2State();
}

class _OnboardingScreenV2State extends State<OnboardingScreenV2> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.psychology_alt_rounded,
      title: 'AI-Driven Detection',
      description:
          'Multi-sensor fusion analyzes accelerometer, gyroscope, proximity, and light data to detect REAL theft — not just movement.',
      color: VigilThemeV2.neonCyan,
    ),
    _OnboardingPage(
      icon: Icons.face_retouching_natural_rounded,
      title: 'Face Auto-Verification',
      description:
          'Your face unlocks safety silently. If the AI sees you, the alert cancels automatically — no buttons needed.',
      color: VigilThemeV2.violetNeon,
    ),
    _OnboardingPage(
      icon: Icons.shield_moon_rounded,
      title: 'Multi-Layer Authentication',
      description:
          'Face + Fingerprint + Voice Password + PIN. An intruder cannot disable the alarm by just tapping a button.',
      color: VigilThemeV2.tealGlow,
    ),
    _OnboardingPage(
      icon: Icons.location_searching_rounded,
      title: 'Live Tracking',
      description:
          'Real addresses, Google Maps links, route history, and live updates shared with your trusted contacts during emergencies.',
      color: VigilThemeV2.amberAlert,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: VigilThemeV2.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Skip',
                      style: TextStyle(color: VigilThemeV2.textMuted)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NeonPulse(size: 120, color: page.color, animate: true,
                            child: Icon(page.icon, size: 56, color: VigilThemeV2.spaceBlack)),
                          const SizedBox(height: 48),
                          Text(page.title,
                            style: VigilThemeV2.headingLG.copyWith(color: page.color)),
                          const SizedBox(height: 16),
                          Text(page.description,
                            textAlign: TextAlign.center,
                            style: VigilThemeV2.bodyLG),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == i
                                ? VigilThemeV2.neonCyan
                                : VigilThemeV2.borderSubtle,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            Navigator.pushReplacementNamed(context, '/login');
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        child: Text(_currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
