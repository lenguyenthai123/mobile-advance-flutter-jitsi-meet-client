import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './services/preferences_service.dart';
import './services/database_service.dart';
import './providers/auth_provider.dart';
import './providers/meeting_provider.dart';
import './screens/splash_screen.dart';
import './screens/home_screen.dart';
import './screens/onboarding_screen.dart';
import './screens/create_meeting_screen.dart';
import './screens/join_meeting_screen.dart';
import './screens/meeting_history_screen.dart';
import './screens/profile_screen.dart';
import './screens/login_screen.dart';
import './screens/admin_panel_screen.dart';
import './theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await PreferencesService.init();
  await DatabaseService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
      ],
      child: MaterialApp(
        title: 'Near - Video Conferencing',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => const HomeScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/admin': (context) => const AdminPanelScreen(),
          '/create-meeting': (context) => const CreateMeetingScreen(),
          '/join-meeting': (context) => const JoinMeetingScreen(),
          '/meeting-history': (context) => const MeetingHistoryScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}

