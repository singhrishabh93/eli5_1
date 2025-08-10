import 'package:eli5/firebase_options.dart';
import 'package:eli5/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load env before running app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // from firebase_options.dart
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.splash, // Start from splash
      routes: {
        Routes.splash: (context) => const SplashScreen(),
        Routes.login: (context) => const LoginScreen(),
        Routes.home: (context) => HomeScreen(),
        Routes.history: (context) => HistoryScreen(),
        Routes.favorites: (context) => FavoritesScreen(),
        Routes.settings: (context) => SettingsScreen(),
      },
    );
  }
}
