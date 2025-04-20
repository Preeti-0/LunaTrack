import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khalti_flutter/khalti_flutter.dart';

import 'dashboard.dart';
import 'login.dart';
import 'symptom_logging.dart';

import 'onboarding_questions.dart';
import 'doctor_detail_screen.dart';
import 'doctor_model.dart';
import 'doctor_dashboard.dart';
import 'profile_screen.dart';
import 'reminder_screen.dart';
import 'doctor_reminder_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final startScreen = await getStartScreen();

  runApp(
    KhaltiScope(
      publicKey: '968fb24af9774b4390ce56052656be7f',
      builder: (context, navKey) {
        return MyApp(navigatorKey: navKey, initialScreen: startScreen);
      },
    ),
  );
}

// ✅ Choose initial screen based on login status and role
Future<Widget> getStartScreen() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token'); // ✅ Fix this key
  final role = prefs.getString('role');

  if (token != null && role != null) {
    if (role == 'doctor') {
      return const DoctorDashboardScreen();
    } else {
      return DashboardScreen();
    }
  }
  return LoginScreen();
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget initialScreen;

  const MyApp({
    super.key,
    required this.navigatorKey,
    required this.initialScreen,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'LunaTrack',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFFF0F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.pinkAccent,
          centerTitle: true,
        ),
      ),
      localizationsDelegates: const [KhaltiLocalizations.delegate],
      initialRoute: '/',
      routes: {
        '/': (context) => initialScreen,
        '/login': (context) => LoginScreen(),
        '/onboarding': (context) => OnboardingQuestionsScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/symptoms': (context) => SymptomLoggingScreen(),
        '/profile': (context) => ProfileScreen(),
        '/reminders': (context) => const ReminderScreen(),
        '/doctor-reminders': (context) => const DoctorReminderScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/book_appointment') {
          final doctor = settings.arguments as Doctor;
          return MaterialPageRoute(
            builder: (context) => DoctorDetailScreen(doctor: doctor),
          );
        }

        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                body: Center(child: Text("Route not found: \${settings.name}")),
              ),
        );
      },
    );
  }
}
