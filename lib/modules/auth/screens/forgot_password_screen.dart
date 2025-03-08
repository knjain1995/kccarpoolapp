import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/auth_service.dart'; // Import AuthService

/// ForgotPasswordScreen allows users to reset their password via email using AuthService.
class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService(); // Using AuthService for password reset
  final TextEditingController _emailController = TextEditingController(); // Controller for email input
  String message = ""; // Stores messages for feedback (success/error)

  /// Function to handle password reset request using AuthService.
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        message = 'Please enter your email.';
      });
      return;
    }
    String? error = await _authService.sendPasswordResetEmail(
      _emailController.text.trim(),
    );
    setState(() {
      message = error ?? 'Password reset email sent! Check your inbox.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Forgot Password")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Instruction text for the user
            Text("Enter your email to reset password", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            
            /// Email input field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 20),
            
            /// Reset Password Button
            ElevatedButton(
              onPressed: _resetPassword,
              child: Text("Reset Password"),
            ),
            
            /// Display messages for success/error feedback
            SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(color: Colors.red),
            ),
            
            /// Cancel button to navigate back to login
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Navigate back to login screen
              },
              child: Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}
