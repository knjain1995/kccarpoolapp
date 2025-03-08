import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// LoginScreen provides user authentication functionality using Firebase Auth.
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool isSignupMode = false; // Toggles between Login and Signup
  String errorMessage = "";

  /// Function to authenticate user with Firebase.
  Future<void> _authUser() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() {
        errorMessage = 'Login failed. Please check your credentials.';
      });
    }
  }

  /// Function to handle user signup.
  Future<void> _signupUser() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        errorMessage = 'Passwords do not match!';
      });
      return;
    }
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() {
        errorMessage = 'Signup failed. Try a different email.';
      });
    }
  }

  /// Function to handle password recovery.
  Future<void> _recoverPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your email to reset password.';
      });
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      setState(() {
        errorMessage = 'Password reset email sent!';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Password recovery failed. Check your email.';
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
              Text(
                isSignupMode ? "Sign Up" : "Login",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              if (isSignupMode) ...[
                SizedBox(height: 10),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                ),
              ],
              SizedBox(height: 10),
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSignupMode ? _signupUser : _authUser,
                child: Text(isSignupMode ? "Sign Up" : "Login"),
              ),
              TextButton(
                onPressed: _recoverPassword,
                child: Text("Forgot Password?"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    isSignupMode = !isSignupMode; // Toggle between login and signup
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
