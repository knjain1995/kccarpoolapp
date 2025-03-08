import 'package:firebase_auth/firebase_auth.dart';

/// FirebaseFunctions - Centralized class for Firebase Authentication calls
class FirebaseFunctions {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance

  /// Logs in user with email and password
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } catch (e) {
      return 'Login failed. Please check your credentials.'; // Return error message
    }
  }

  /// Registers a new user with email and password
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } catch (e) {
      return 'Signup failed. Try a different email.'; // Return error message
    }
  }

  /// Sends a password reset email to the user
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } catch (e) {
      return 'Error sending password reset email. Check your email address.'; // Return error message
    }
  }

  /// Logs out the current user
  Future<void> logout() async {
    await _auth.signOut(); // Sign out from Firebase
  }
}
