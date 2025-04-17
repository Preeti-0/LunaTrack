import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khalti_flutter/khalti_flutter.dart';

import 'dashboard.dart';
import 'login.dart';
import 'symptom_logging.dart';
import 'doctor_profile_screen.dart';
import 'onboarding_questions.dart';
import 'doctor_detail_screen.dart';
import 'doctor_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  runApp(
    KhaltiScope(
      publicKey:
          'test_public_key_dc74a5b7b56b4c12bca4c6b198b5517b', // ✅ Test Key
      builder: (context, navKey) {
        return MyApp(navigatorKey: navKey, isLoggedIn: token != null);
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final bool isLoggedIn;

  const MyApp({Key? key, required this.navigatorKey, required this.isLoggedIn})
    : super(key: key);

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
      onGenerateRoute: (settings) {
        if (settings.name == '/book_appointment') {
          final doctor = settings.arguments as Doctor;
          return MaterialPageRoute(
            builder: (context) => DoctorDetailScreen(doctor: doctor),
          );
        }

        final routes = <String, WidgetBuilder>{
          '/': (context) => isLoggedIn ? DashboardScreen() : LoginScreen(),
          '/onboarding': (context) => OnboardingQuestionsScreen(),
          '/dashboard': (context) => DashboardScreen(),
          '/symptoms': (context) => SymptomLoggingScreen(),
          '/profile': (context) => const DoctorProfileScreen(),
        };

        final builder = routes[settings.name];
        if (builder != null) {
          return MaterialPageRoute(builder: builder);
        }

        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                body: Center(child: Text("Route not found: ${settings.name}")),
              ),
        );
      },
    );
  }
}
