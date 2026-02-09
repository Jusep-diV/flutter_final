import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/vehicles/home_screen.dart';
import 'screens/settings/settings_screen.dart';

class AppRoutes {
  // Names
  static const String login = '/login'; 
  static const String register = '/register';
  static const String home = '/home';
  static const String settings = '/settings';
  

  // Map
  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    settings: (context) => const SettingsScreen(),
  };
}
