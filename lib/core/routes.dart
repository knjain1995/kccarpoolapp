import 'package:flutter/material.dart';
import 'package:kccarpoolapp/modules/auth/screens/login_screen.dart';
import 'package:kccarpoolapp/modules/home/screens/home_screen.dart';
import 'package:kccarpoolapp/modules/onboarding/onboarding_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/onboarding': (context) => OnboardingScreen(),
    '/login': (context) => LoginScreen(),
    '/home': (context) => HomeScreen(),
  };
}
