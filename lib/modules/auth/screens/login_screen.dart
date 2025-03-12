// Filename: login_screen.dart  Location: lib/modules/auth/screens/
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/core/routes.dart';
import 'package:kccarpoolapp/services/auth_service.dart'; // Import AuthService
import 'package:flutter/services.dart'; // For phone number input formatting

/// LoginScreen provides user authentication functionality using Firebase Auth via AuthService.
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService(); // Using AuthService for authentication
  final TextEditingController _nameController = TextEditingController(text: 'Kartik Narendra Jain'); // Full Name
  final TextEditingController _emailController = TextEditingController(text: 'knjain1995@gmail.com'); // Default test email (Remove before production)
  final TextEditingController _phoneController = TextEditingController(text: '9810665538'); // Phone Number
  final TextEditingController _passwordController = TextEditingController(text: 'Test@123'); // Default test password (Remove before production)
  final TextEditingController _confirmPasswordController = TextEditingController(text: 'Test@123'); // Used only in signup mode
  bool isSignupMode = false; // Toggles between Login and Signup
  String errorMessage = ""; // Holds error messages to display to the user

  /// Function to handle user login using AuthService.
  Future<void> _authUser() async {
    String? error = await _authService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (error == null) {
      // Navigator.of(context).pushReplacementNamed('/home');
      Navigator.of(context).pushReplacementNamed(AppRoutes.home); // Navigate to Home on success
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
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      setState(() {
        errorMessage = 'All fields are mandatory except optional fields!';
      });
      return;
    }

    String? error = await _authService.signUp(
      _nameController.text.trim(), // Full Name
      _emailController.text.trim(), // Email
      _phoneController.text.trim(), // Phone Number
      _passwordController.text.trim(), // Password
    );

    if (error == null) {
      // Navigator.of(context).pushReplacementNamed('/verification'); 
      Navigator.of(context).pushReplacementNamed(AppRoutes.verification); // Navigate to Verification Screen
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
        child: SingleChildScrollView( // Allows scrolling on smaller screens
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Display Login or Sign Up title based on mode
                Text(
                  isSignupMode ? "Sign Up" : "Login",
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.08, // Adjusts size based on screen width
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                
                /// Full Name Input Field (Only for Signup Mode)
                if (isSignupMode) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Full Name'),
                  ),
                  SizedBox(height: 10),
                ],
                
                /// Email Input Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                SizedBox(height: 10),
                
                /// Phone Number Input Field (Only for Signup Mode)
                if (isSignupMode) ...[
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: 'Phone Number (+91)'),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  SizedBox(height: 10),
                ],
                
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
                    // Navigator.of(context).pushNamed('/forgot-password');
                    Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
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
      ),
    );
  }
}
