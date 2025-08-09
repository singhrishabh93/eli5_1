import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'routes.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELI5 App',
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
