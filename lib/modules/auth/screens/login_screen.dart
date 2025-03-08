import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// LoginScreen provides user authentication functionality using Firebase Auth.
class LoginScreen extends StatelessWidget {
  /// Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Duration of animations on login screen
  Duration get loginTime => Duration(milliseconds: 2000);

  /// Function to authenticate user with Firebase.
  Future<String?> _authUser(LoginData data) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: data.name,
        password: data.password,
      );
      return null; // Success, return null (no error message)
    } catch (e) {
      return 'Login failed. Please check your credentials.';
    }
  }

  /// Function to handle user signup.
  Future<String?> _signupUser(SignupData data) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: data.name!,
        password: data.password!,
      );
      return null; // Signup successful
    } catch (e) {
      return 'Signup failed. Try a different email.';
    }
  }

  /// Function to handle password recovery.
  Future<String?> _recoverPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Password reset email sent
    } catch (e) {
      return 'Password recovery failed. Check your email.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'kccarpoolapp',
      theme: LoginTheme(
        primaryColor: Colors.blue,
        accentColor: Colors.white,
      ),
      onLogin: _authUser,
      onSignup: _signupUser,
      onRecoverPassword: _recoverPassword,
      onSubmitAnimationCompleted: () {
        // Navigate to the main app page after login
        Navigator.of(context).pushReplacementNamed('/home');
      },
    );
  }
}
