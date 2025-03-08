import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/auth_service.dart'; // Import AuthService

/// LoginScreen provides user authentication functionality using Firebase Auth via AuthService.
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService(); // Using AuthService for authentication
  final TextEditingController _emailController = TextEditingController(text: 'knjain1995@gmail.com'); // Default test email (Remove before production)
  final TextEditingController _passwordController = TextEditingController(text: 'Test@123'); // Default test password (Remove before production)
  final TextEditingController _confirmPasswordController = TextEditingController(); // Used only in signup mode
  bool isSignupMode = false; // Toggles between Login and Signup
  String errorMessage = ""; // Holds error messages to display to the user

  /// Function to handle user login using AuthService.
  Future<void> _authUser() async {
    String? error = await _authService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (error == null) {
      Navigator.of(context).pushReplacementNamed('/home'); // Navigate to Home on success
    } else {
      setState(() {
        errorMessage = error;
      });
    }
  }

  /// Function to handle user signup using AuthService.
  Future<void> _signupUser() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        errorMessage = 'Passwords do not match!';
      });
      return;
    }
    String? error = await _authService.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (error == null) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// Display Login or Sign Up title based on mode
              Text(
                isSignupMode ? "Sign Up" : "Login",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              
              /// Email Input Field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 10),
              
              /// Password Input Field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              
              /// Confirm Password Field (Only for Signup Mode)
              if (isSignupMode) ...[
                SizedBox(height: 10),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                ),
              ],
              SizedBox(height: 10),
              
              /// Error Message Display (if any)
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 20),
              
              /// Login or Sign Up Button
              ElevatedButton(
                onPressed: isSignupMode ? _signupUser : _authUser,
                child: Text(isSignupMode ? "Sign Up" : "Login"),
              ),
              
              /// Forgot Password Button (Navigates to Forgot Password Screen)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/forgot-password');
                },
                child: Text("Forgot Password?"),
              ),
              
              /// Toggle between Login and Signup Modes
              TextButton(
                onPressed: () {
                  setState(() {
                    isSignupMode = !isSignupMode;
                  });
                },
                child: Text(isSignupMode
                    ? "Already have an account? Login"
                    : "Don't have an account? Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}