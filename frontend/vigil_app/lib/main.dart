import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/vigil_theme_v2.dart';
import 'utils/navigation_service.dart';

// V2 Screens (premium futuristic UI)
import 'screens/splash_screen_v2.dart';
import 'screens/onboarding_screen_v2.dart';
import 'screens/login_screen_v2.dart';
import 'screens/signup_screen_v2.dart';
import 'screens/dashboard_screen_v2.dart';
import 'screens/pocket_mode_screen_v2.dart';
import 'screens/lock_screen_safety_v2.dart';
import 'screens/emergency_active_screen.dart';
import 'screens/settings_screen_v2.dart';
import 'screens/emergency_contacts_screen_v2.dart';
import 'screens/alert_history_screen_v2.dart';
import 'screens/guardian_selection_screen.dart';
import 'screens/face_enrollment_screen.dart';
import 'screens/voice_password_screen.dart';

// Services
import 'services/alert_coordinator_v2.dart';

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
      systemNavigationBarColor: VigilThemeV2.spaceBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize the AI safety coordinator early so it can wake the UI
  AlertCoordinatorV2().initialize();

  runApp(const VigilApp());
}

class VigilApp extends StatelessWidget {
  const VigilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vigil',
      debugShowCheckedModeBanner: false,
      theme: VigilThemeV2.darkTheme,
      navigatorKey: NavigationService.navigatorKey, // Global nav key
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreenV2(),
        '/onboarding': (context) => const OnboardingScreenV2(),
        '/login': (context) => const LoginScreenV2(),
        '/signup': (context) => const SignupScreenV2(),
        '/dashboard': (context) => const DashboardScreenV2(),
        '/pocket-mode': (context) => const PocketModeScreenV2(),
        '/lock-screen-safety': (context) => const LockScreenSafetyV2(),
        '/emergency-active': (context) => const EmergencyActiveScreen(),
        '/settings': (context) => const SettingsScreenV2(),
        '/emergency-contacts': (context) => const EmergencyContactsScreenV2(),
        '/alert-history': (context) => const AlertHistoryScreenV2(),
        '/guardian-selection': (context) => const GuardianSelectionScreen(),
        '/face-enrollment': (context) => const FaceEnrollmentScreen(),
        '/voice-password': (context) => const VoicePasswordScreen(),
      },
    );
  }
}
