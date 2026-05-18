import 'package:flutter/material.dart';
import '../theme/vigil_theme.dart';
import '../widgets/vigil_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.shield_rounded,
      'title': 'Pocket Protection',
      'description':
          'Vigil detects when your phone is suspiciously removed from your pocket or bag using smart sensors.',
      'color': VigilTheme.cyan,
    },
    {
      'icon': Icons.sensors_rounded,
      'title': 'Smart Detection',
      'description':
          'Combines proximity, light, and motion sensors to minimize false alarms from normal movement.',
      'color': VigilTheme.emerald,
    },
    {
      'icon': Icons.notifications_active_rounded,
      'title': 'Instant Alerts',
      'description':
          'Automatically alerts trusted contacts with your location and captures intruder evidence.',
      'color': VigilTheme.warningOrange,
    },
    {
      'icon': Icons.lock_rounded,
      'title': 'Permissions Needed',
      'description':
          'Vigil needs location, camera, sensor, and notification permissions to keep you safe.',
      'color': VigilTheme.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: VigilTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Skip',
                      style: TextStyle(color: VigilTheme.textGrey)),
                ),
              ),
              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (page['color'] as Color).withOpacity(0.15),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (page['color'] as Color).withOpacity(0.2),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                            child: Icon(
                              page['icon'],
                              size: 55,
                              color: page['color'],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            page['title'],
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: VigilTheme.textWhite,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            page['description'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: VigilTheme.textGrey.withOpacity(0.9),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Dots + Button
              Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == index
                                ? VigilTheme.cyan
                                : VigilTheme.divider,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    VigilButton(
                      text: _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          Navigator.pushReplacementNamed(context, '/login');
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      icon: _currentPage == _pages.length - 1
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
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
