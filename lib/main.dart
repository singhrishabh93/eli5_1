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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.login,
      routes: {
        Routes.login: (context) => const LoginScreen(),
        Routes.home: (context) => HomeScreen(),
        Routes.history: (context) => HistoryScreen(),
        Routes.favorites: (context) => FavoritesScreen(),
        Routes.settings: (context) => SettingsScreen(),
      },
    );
  }
}
