// Filename: routes.dart  Location: lib/core/
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/modules/auth/screens/forgot_password_screen.dart';
import 'package:kccarpoolapp/modules/auth/screens/login_screen.dart';
import 'package:kccarpoolapp/modules/auth/screens/verification_screen.dart';
import 'package:kccarpoolapp/modules/home/screens/home_screen.dart';
import 'package:kccarpoolapp/modules/onboarding/onboarding_screen.dart';
import 'package:kccarpoolapp/modules/profile/screens/manage_family.dart';
import 'package:kccarpoolapp/modules/profile/screens/profile_screen.dart'; // Added profile screen

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String forgotPassword = '/forgot-password';
  static const String verification = '/verification';
  static const String profile = '/profile';
  static const String manageFamily = '/manage-family';

  static Map<String, WidgetBuilder> routes = {
    onboarding: (context) => OnboardingScreen(),
    login: (context) => LoginScreen(),
    home: (context) => HomeScreen(),
    forgotPassword: (context) => ForgotPasswordScreen(),
    verification: (context) => VerificationScreen(),
    profile: (context) => ProfileScreen(),
    manageFamily: (context) => ManageFamilyScreen(),
  };
}