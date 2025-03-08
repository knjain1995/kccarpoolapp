import 'package:flutter/material.dart';
import 'package:kccarpoolapp/modules/onboarding/onboarding_screen.dart';
// import 'package:kccarpoolapp/screens/login/login.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/onboarding': (context) => OnboardingScreen(),
    // '/login': (context) => LoginScreen(),
  };
}
