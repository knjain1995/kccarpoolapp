import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';

/// AuthService - Handles authentication-related functions across the app
class AuthService {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions(); // Use FirebaseFunctions

  /// Logs out the current user and redirects to the login screen
  Future<void> logout(BuildContext context) async {
    await _firebaseFunctions.logout(); // Call FirebaseFunctions logout
    Navigator.of(context).pushReplacementNamed('/login'); // Navigate back to login
  }

  /// Signs in user with email and password via FirebaseFunctions
  Future<String?> signIn(String email, String password) async {
    return await _firebaseFunctions.signIn(email, password);
  }

  /// Registers a new user with full details via FirebaseFunctions
  Future<String?> signUp(String fullName, String email, String phoneNumber, String password) async {
    return await _firebaseFunctions.signUp(fullName, email, phoneNumber, password);
  }


  /// Sends a password reset email to the user via FirebaseFunctions
  Future<String?> sendPasswordResetEmail(String email) async {
    return await _firebaseFunctions.sendPasswordResetEmail(email);
  }
}