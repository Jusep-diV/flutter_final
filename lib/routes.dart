import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';

class AppRoutes {
  // Names
  static const String login = '/login'; 

  // Map
  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
  };
}
