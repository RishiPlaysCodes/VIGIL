import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/vigil_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pocket_mode_screen.dart';
import 'screens/alert_history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/emergency_contacts_screen.dart';
import 'screens/lock_screen_safety.dart';
import 'screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E21),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const VigilApp());
}

class VigilApp extends StatelessWidget {
  const VigilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vigil',
      debugShowCheckedModeBanner: false,
      theme: VigilTheme.darkTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/pocket-mode': (context) => const PocketModeScreen(),
        '/alert-history': (context) => const AlertHistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/emergency-contacts': (context) => const EmergencyContactsScreen(),
        '/lock-screen': (context) => const LockScreenSafety(),
      },
    );
  }
}
