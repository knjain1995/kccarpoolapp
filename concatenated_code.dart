// 📌 Filename: main.dart
// 📂 Location: .

// Filename: main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kccarpoolapp/core/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initializes Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.onboarding,
      routes: AppRoutes.routes,
      // home: Scaffold(
      //   body: Center(child: Text("Welcome to kccarpoolapp")),
      // ),
    );
  }
}

// --------------------------------------------------

// 📌 Filename: routes.dart
// 📂 Location: core

// Filename: routes.dart  Location: lib/core/
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/modules/auth/screens/forgot_password_screen.dart';
import 'package:kccarpoolapp/modules/auth/screens/login_screen.dart';
import 'package:kccarpoolapp/modules/auth/screens/verification_screen.dart';
import 'package:kccarpoolapp/modules/carpool/screens/create_carpool.dart';
import 'package:kccarpoolapp/modules/home/screens/home_screen.dart';
import 'package:kccarpoolapp/modules/onboarding/onboarding_screen.dart';
import 'package:kccarpoolapp/modules/profile/screens/manage_family.dart';
import 'package:kccarpoolapp/modules/profile/screens/manage_vehicles.dart';
import 'package:kccarpoolapp/modules/profile/screens/profile_screen.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String forgotPassword = '/forgot-password';
  static const String verification = '/verification';
  static const String profile = '/profile';
  static const String manageFamily = '/manage-family';
  static const String manageVehicles = 'manage-vehicles';
  static const String createCarpool = '/createCarpool';


  static Map<String, WidgetBuilder> routes = {
    onboarding: (context) => OnboardingScreen(),
    login: (context) => LoginScreen(),
    home: (context) => HomeScreen(),
    forgotPassword: (context) => ForgotPasswordScreen(),
    verification: (context) => VerificationScreen(),
    profile: (context) => ProfileScreen(),
    manageFamily: (context) => ManageFamilyScreen(),
    manageVehicles: (context) => ManageVehiclesScreen(),
    createCarpool: (context) => CreateCarpoolScreen(),
  };
}

// --------------------------------------------------

// 📌 Filename: forgot_password_screen.dart
// 📂 Location: modules\auth\screens

// Filename: forgot_password_screen.dart  Location: lib/modules/auth/screens/
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
      body: SingleChildScrollView( // Ensures content is scrollable on small screens
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// Instruction text for the user
              Text(
                "Enter your email to reset password",
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.05, // Responsive font size
                ),
                textAlign: TextAlign.center,
              ),
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
      ),
    );
  }
}


// --------------------------------------------------

// 📌 Filename: login_screen.dart
// 📂 Location: modules\auth\screens

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


// --------------------------------------------------

// 📌 Filename: verification_screen.dart
// 📂 Location: modules\auth\screens

// Filename: verification_screen.dart  Location: lib/modules/auth/screens/
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/core/routes.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';

class VerificationScreen extends StatefulWidget {
  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();

  final TextEditingController _emailOtpController = TextEditingController(text: '1234');
  final TextEditingController _phoneOtpController = TextEditingController(text: '1234');
  final TextEditingController _addressController = TextEditingController(text: 'Sample address, 123, Sec-2, Noida, Uttar Pradesh - 201309');

  String? _relationToChild;
  String? _photoFile;
  String? _govIdFile;
  String? _driverLicenseFile; // Optional

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verification")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter OTP (Placeholders for now)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            
            /// Email OTP Input
            TextField(
              controller: _emailOtpController,
              decoration: InputDecoration(labelText: "Email OTP"),
            ),
            SizedBox(height: 10),

            /// Phone OTP Input
            TextField(
              controller: _phoneOtpController,
              decoration: InputDecoration(labelText: "Phone OTP"),
            ),
            SizedBox(height: 20),

            /// Upload Profile Photo
            Text("Upload Profile Photo (Required)"),
            ElevatedButton(
              onPressed: () async {
                String? path = await _firebaseFunctions.saveFileLocally("profilePhoto");
                if (path != null) {
                  setState(() {
                    _photoFile = path;
                  });
                  print("Profile photo saved at: $path");
                }
              },
              child: Text(_photoFile == null ? "Upload Photo" : "Photo Saved Locally ✅"),
            ),
            SizedBox(height: 10),

            /// Upload Driver License (Optional)
            Text("Upload Driver License (Optional)"),
            ElevatedButton(
              onPressed: () async {
                String? path = await _firebaseFunctions.saveFileLocally("driverLicense");
                if (path != null) {
                  setState(() {
                    _driverLicenseFile = path;
                  });
                  print("License saved at: $path");
                }
              },
              child: Text(_driverLicenseFile == null ? "Upload License" : "License Uploaded ✅"),
            ),
            SizedBox(height: 10),
            
            /// Upload Government ID (Required)
            Text("Upload Government ID (Required)"),
            ElevatedButton(
              onPressed: () async {
                String? path = await _firebaseFunctions.saveFileLocally("govId");
                if (path != null) {
                  setState(() {
                    _govIdFile = path;
                  });
                  print("Govt ID saved at: $path");
                }
              },
              child: Text(_govIdFile == null ? "Upload ID" : "ID Uploaded ✅"),
            ),
            SizedBox(height: 10),

            /// Relation to Child Dropdown
            Text("Select Relation to Child"),
            DropdownButtonFormField<String>(
              value: _relationToChild,
              items: ["Father", "Mother", "Guardian"].map((relation) {
                return DropdownMenuItem(value: relation, child: Text(relation));
              }).toList(),
              onChanged: (value) {
                setState(() => _relationToChild = value);
              },
              decoration: InputDecoration(hintText: "Relation to Child"),
            ),
            SizedBox(height: 30),

            /// Submit Button
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (_photoFile != null && _govIdFile != null && _addressController.text.isNotEmpty) {
                    await _firebaseFunctions.saveVerificationData(
                      profilePhoto: _photoFile!,
                      govId: _govIdFile!,
                      driverLicense: _driverLicenseFile,
                      address: _addressController.text,
                      relationToChild: _relationToChild!,
                    );

                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please fill all required fields!"))
                    );
                  }
                },
                child: Text("Submit & Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------

// 📌 Filename: carpool_list_screen.dart
// 📂 Location: modules\carpool\screens



// --------------------------------------------------

// 📌 Filename: create_carpool.dart
// 📂 Location: modules\carpool\screens

// 📌 Filename: create_carpool.dart
// 📂 Location: lib/modules/carpool/screens/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';
import 'package:file_picker/file_picker.dart';

/// Screen for Creating a New Carpool
class CreateCarpoolScreen extends StatefulWidget {
  @override
  _CreateCarpoolScreenState createState() => _CreateCarpoolScreenState();
}

class _CreateCarpoolScreenState extends State<CreateCarpoolScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();

  // Controllers for input fields
  final TextEditingController _carpoolNameController = TextEditingController();
  final TextEditingController _routeStartController = TextEditingController();
  final TextEditingController _routeEndController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController(text: "4");

  // Date & Time Selection
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Vehicle & Driver Selection
  String? _selectedVehicle;
  String? _selectedOwner;
  String? _selectedDriver;
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _adults = []; // Account owner & adults in the family

  // Return Trip Options
  bool _hasReturnTrip = false;
  bool _stayOnLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user’s vehicles & family details
  }

  /// Fetches the user's vehicles & family members (for selecting driver & owner)
  Future<void> _fetchUserData() async {
    var userData = await _firebaseFunctions.getUserData();
    var familyMembers = await _firebaseFunctions.getFamilyMembers();
    var vehicleData = await _firebaseFunctions.getVehicles();

     // 🔄 If date/time is selected, check availability for each vehicle
    if (_selectedDate != null && _selectedTime != null) {
      for (var vehicle in vehicleData) {
        bool available = await _firebaseFunctions.isVehicleAvailable(
          vehicleId: vehicle['id'],
          carpoolDate: Timestamp.fromDate(_selectedDate!),
          carpoolTime: Timestamp.fromDate(DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          )),
        );
        vehicle['isAvailable'] = available; // 🔹 Tag vehicle as available/unavailable
      }
    } else {
      // If no time/date selected yet, assume all available
      for (var vehicle in vehicleData) {
        vehicle['isAvailable'] = true;
      }
    }

    setState(() {
      _selectedOwner = userData?["id"]; // Default owner should be account owner's ID

      // ✅ Ensure _adults contains both the account owner and adult family members
      _adults = familyMembers.where((member) => member["isAdult"] == true).toList();

      if (userData != null) {
        _adults.insert(0, {
          "id": userData["id"], // ✅ Use user ID instead of fullName
          "fullName": userData["fullName"],
          "email": userData["email"],
          "phoneNumber": userData["phoneNumber"],
          "isAdult": true, // ✅ Ensure account owner is treated as an adult
          "driverLicense": userData["driverLicense"] ?? "", // ✅ Handle driver license for selection
        });
      }

      _vehicles = vehicleData;

      print("Account Owner ID: ${userData?['id']}");
      print("Adults List: $_adults");
      print("Vehicles List: $_vehicles");
    });
  }

  /// Opens a date picker & updates the selected date
  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });

      // 🔄 Re-fetch vehicles to update their availability
      await _fetchUserData();
    }
  }

  /// Opens a time picker & updates the selected time
  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });

      // 🔄 Re-fetch vehicles to update their availability
      await _fetchUserData();
    }
  }

  /// Validates the input before saving to Firestore
  bool _validateCarpoolInputs() {
    if (_carpoolNameController.text.isEmpty ||
        _routeStartController.text.isEmpty ||
        _routeEndController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedVehicle == null ||
        _selectedDriver == null ||
        _selectedOwner == null) {
      return false;
    }
    return true;
  }

  /// Handles form submission for creating a carpool
  void _createCarpool() async {
    if (!_validateCarpoolInputs()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all required fields!")));
      return;
    }

    // ✅ Safety net check before creation (even if dropdown disables vehicle)
    bool stillAvailable = await _firebaseFunctions.isVehicleAvailable(
      vehicleId: _selectedVehicle!,
      carpoolDate: Timestamp.fromDate(_selectedDate!),
      carpoolTime: Timestamp.fromDate(DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      )),
    );

    if (!stillAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Selected vehicle is no longer available.")));
      return;
    }

    // Convert DateTime to Firestore Timestamp
    Timestamp carpoolDate = Timestamp.fromDate(_selectedDate!);
    Timestamp carpoolTime = Timestamp.fromDate(DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    ));

    try {
      _firebaseFunctions.createCarpool(
        carpoolName: _carpoolNameController.text.trim(),
        carpoolRouteStart: _routeStartController.text.trim(),
        carpoolRouteEnd: _routeEndController.text.trim(),
        carpoolDate: carpoolDate,
        carpoolTime: carpoolTime,
        carpoolVehicleId: _selectedVehicle!,
        carpoolOwnerId: _selectedOwner!,
        carpoolDriverId: _selectedDriver!,
        carpoolCapacity: int.parse(_capacityController.text),
        carpoolReturnTrip: _hasReturnTrip,
        carpoolReturnStayOnLocation: _hasReturnTrip ? _stayOnLocation : null,
      );

      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Carpool Created Successfully!")));

      // ✅ Navigate back to Home Screen
      Navigator.of(context).pop(); 
      } catch (e) {
        // ✅ Handle errors
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error creating carpool: $e")));
      }
  }

  
  /// Generic text field builder
  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(controller: controller, decoration: InputDecoration(labelText: label), keyboardType: keyboardType),
    );
  }

  /// Date-Time Picker UI
  Widget _buildDateTimePicker(String label, dynamic value, VoidCallback onTap) {
    return ListTile(
      title: Text(value != null ? value.toString() : label),
      trailing: Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }

  /// Dropdown builder
  Widget _buildDropdown(
  String label,
  String? selectedValue,
  List<Map<String, dynamic>> items,
  String idField,
  String displayField,
  Function(String?) onChangedCallback, {
  bool showAvailabilityIcon = false, // ✅ NEW optional flag
  }) {
    return DropdownButtonFormField(
      value: selectedValue,
      items: items.map((item) {
        bool isDisabled = item['isAvailable'] == false;

        return DropdownMenuItem(
          value: item[idField],
          enabled: !isDisabled, // 🔹 Disable item if unavailable
          child: Row(
            children: [
              if (showAvailabilityIcon && isDisabled)
                Icon(Icons.block, color: Colors.redAccent, size: 16),
              if (showAvailabilityIcon && isDisabled) SizedBox(width: 6),
              Text(
                item[displayField] + (showAvailabilityIcon && isDisabled ? " (Unavailable)" : ""),
                style: TextStyle(
                  color: isDisabled ? Colors.grey : null,
                  fontStyle: showAvailabilityIcon && isDisabled ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          onChangedCallback(value as String?);
        });
      },
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Carpool")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField("Carpool Name", _carpoolNameController),
            _buildTextField("Start Location", _routeStartController),
            _buildTextField("End Location", _routeEndController),

            _buildDateTimePicker("Select Date", _selectedDate, _pickDate),
            _buildDateTimePicker("Select Time", _selectedTime, _pickTime),

            // // Vehicle Selection
            // _buildDropdown("Select Vehicle", _selectedVehicle, _vehicles, "vehicleId", "vehicleMake"),

            // // Owner Selection
            // _buildDropdown("Carpool Owner", _selectedOwner, _adults, "id", "fullName"),

            // // Driver Selection
            // _buildDropdown("Driver", _selectedDriver, _adults, "id", "fullName")

            // Owner Dropdown
            _buildDropdown(
              "Carpool Owner",
              _selectedOwner,
              _adults,
              "id",
              "fullName",
              (value) => _selectedOwner = value, // 🔹 Updates _selectedOwner
            ),

            // Driver Dropdown
            _buildDropdown(
              "Driver",
              _selectedDriver,
              _adults,
              "id",
              "fullName",
              (value) => _selectedDriver = value, // 🔹 Updates _selectedDriver
            ),

            
            // Vehicle Dropdown
            _buildDropdown(
              "Select Vehicle",
              _selectedVehicle,
              _vehicles,
              "id",
              "vehicleMake",
              (value) => _selectedVehicle = value,
              showAvailabilityIcon: true, // ✅ Enable icon only for vehicles
            ),

            // Carpool Capacity
            _buildTextField("Capacity", _capacityController, keyboardType: TextInputType.number),

            // Return Trip Toggle
            SwitchListTile(
              title: Text("Include Return Trip"),
              value: _hasReturnTrip,
              onChanged: (value) => setState(() => _hasReturnTrip = value),
            ),

            if (_hasReturnTrip)
              SwitchListTile(
                title: Text("Driver Stays on Location"),
                value: _stayOnLocation,
                onChanged: (value) => setState(() => _stayOnLocation = value),
              ),

            SizedBox(height: 20),
            ElevatedButton(onPressed: _createCarpool, child: Text("Create Carpool")),
          ],
        ),
      ),
    );
  }
}


// --------------------------------------------------

// 📌 Filename: home_screen.dart
// 📂 Location: modules\home\screens

// Filename: home_screen.dart  Location: lib/modules/home/screens/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/core/routes.dart';
import 'package:kccarpoolapp/services/auth_service.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart'; // Import AuthService

/// HomeScreen - Main screen after user logs in.
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope( // Prevents back navigation
      onWillPop: () async => false, // Disable back button on Android
      child: Scaffold(
        appBar: AppBar(
          title: Text("Home"),
          automaticallyImplyLeading: false, // Removes back button
          actions: [
            /// Profile button to navigate to the profile screen
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.profile);
              },
              tooltip: "Profile",
            ),

            /// Logout button in the app bar
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                AuthService().logout(context);
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              },
              tooltip: "Logout",
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Create Carpool Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.createCarpool);
                },
                icon: Icon(Icons.add_circle_outline),
                label: Text("Create Carpool"),
              ),

              ElevatedButton(
  onPressed: () async {
    try {
      await FirebaseFunctions().createCarpool(
        carpoolName: "School Pickup",
        carpoolRouteStart: "Home",
        carpoolRouteEnd: "ABC School",
        carpoolDate: Timestamp.now(),
        carpoolTime: Timestamp.now(),
        carpoolVehicleId: "xyz987",
        carpoolOwnerId: "user123",
        carpoolDriverId: "user456",
        carpoolCapacity: 4,
        carpoolReturnTrip: false,
      );
      print("Carpool added successfully!");
    } catch (e) {
      print("Error: $e");
    }
  },
  child: Text("Test Create Carpool"),
),
            ],
          ),
        ),
      ),
    ); // ✅ Corrected closing brackets
  }
}



//  /// Logout button in the app bar
//             IconButton(
//               icon: Icon(Icons.logout),
//               onPressed: () => AuthService().logout(context), // Use AuthService
//               tooltip: "Logout",
//             ),

// --------------------------------------------------

// 📌 Filename: onboarding_screen.dart
// 📂 Location: modules\onboarding

// Filename: onboarding_screen.dart  Location: lib/modules/onboarding/
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/core/routes.dart';
import 'package:kccarpoolapp/modules/auth/screens/login_screen.dart'; // Import Login screen

/// OnboardingScreen is the first screen shown to users when they open the app.
/// It introduces the app's features in a multi-page view format with swipe gestures.
class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// PageController manages page navigation for onboarding screens.
  final PageController _pageController = PageController();
  int currentIndex = 0; // Tracks the current onboarding page index.

  /// List containing the title and description of each onboarding page.
  final List<Map<String, String>> onboardingData = [
    {"title": "Trusted Carpooling", "description": "Learn how our secure carpooling system works."},
    {"title": "Verified Users", "description": "We ensure safety by verifying every participant."},
    {"title": "Easy Scheduling", "description": "Set up and join carpools with just a few taps."},
    {"title": "Get Started!", "description": "Sign up now to start your trusted carpool journey."},
  ];

  /// Moves to the next onboarding screen or finishes onboarding.
  void nextPage() {
    if (currentIndex < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 500), // Smooth transition duration.
        curve: Curves.easeInOut, // Animation style.
      );
    } else {
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(builder: (context) => LoginScreen()), // Navigate to Login screen
      // );
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          /// Main content: PageView to allow swiping between onboarding screens.
          Expanded(
            flex: 4, // Takes up most of the screen height.
            child: PageView.builder(
              controller: _pageController,
              itemCount: onboardingData.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index; // Update progress indicator.
                });
              },
              itemBuilder: (context, index) => OnboardingPage(
                title: onboardingData[index]["title"]!,
                description: onboardingData[index]["description"]!,
              ),
            ),
          ),
          
          /// Row displaying progress dots to indicate current onboarding step.
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              onboardingData.length,
              (index) => buildDot(index),
            ),
          ),
          SizedBox(height: 20),
          
          /// Navigation button to proceed to the next onboarding screen.
          ElevatedButton(
            onPressed: nextPage,
            child: Text(currentIndex < onboardingData.length - 1 ? "Next" : "Get Started"),
          ),
          
          if (currentIndex == onboardingData.length - 1) ...[
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement navigation to learn more screen.
                print("Navigate to Learn More screen (to be implemented)");
              },
              child: Text("Learn More"),
            ),
          ],
          
          SizedBox(height: 20),
          
          /// Login button, allowing users to skip onboarding and go to login screen.
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text("Already have an account? Login"),
          ),
          
          SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Builds the animated progress indicator dots below onboarding pages.
  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: currentIndex == index ? 16 : 8,
      decoration: BoxDecoration(
        color: currentIndex == index ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// OnboardingPage represents each screen in the onboarding flow.
class OnboardingPage extends StatelessWidget {
  final String title, description;

  const OnboardingPage({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// The top section of each onboarding screen, displaying the title.
          Text(
            title,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.08, // Responsive font size
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 20),
          
          /// The lower section containing text description.
          Text(
            description,
            style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.05, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


// --------------------------------------------------

// 📌 Filename: manage_family.dart
// 📂 Location: modules\profile\screens

// Filename: manage_family.dart  Location: lib/modules/profile/screens/
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for handling Firestore Timestamp


/// Manages adding family members (Adults & Children) for the account owner
class ManageFamilyScreen extends StatefulWidget {
  @override
  _ManageFamilyScreenState createState() => _ManageFamilyScreenState();
}

class _ManageFamilyScreenState extends State<ManageFamilyScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();

  String? _ownerAddress; // Stores the logged-in user's address
  String? _memberId; // ✅ Used to track if we are editing a family member

  // Controllers for input fields
  final TextEditingController _nameController = TextEditingController(text: 'Seema Jain');
  final TextEditingController _emailController = TextEditingController(text: 'seemajain@gmail.com');
  final TextEditingController _phoneController = TextEditingController(text: '9540105173');
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  // final TextEditingController _schoolIdController = TextEditingController();
  final TextEditingController _schoolIdNoController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();


  // Selection states
  bool _isAdult = true; // Toggle between Adult & Child
  String? _gender; // Gender selection for children
  String? _relationToChild; // Relation to the child (Only for Adults)
  String? _profilePhoto;
  String? _govId;
  String? _schoolId;
  String? _driverLicense;
  DateTime? _selectedDateOfBirth; // Holds the selected date of birth

  @override
  void initState() {
    super.initState();
    _fetchOwnerAddress(); // Fetches the logged-in user's address

    // Retrieve passed family member data
    Future.delayed(Duration.zero, () {
        final Map<String, dynamic>? memberData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        if (memberData != null) {
            setState(() {
                _memberId = memberData["id"]; // ✅ Store ID for updates
                _nameController.text = memberData["fullName"] ?? "";
                _emailController.text = memberData["email"] ?? "";
                _phoneController.text = memberData["phoneNumber"] ?? "";
                _addressController.text = memberData["address"] ?? "";  // Fix for empty address
                _profilePhoto = memberData["profilePhoto"];
                _govId = memberData["govId"];
                _driverLicense = memberData["driverLicense"];
                _relationToChild = memberData["relationToChild"];
                _isAdult = memberData["isAdult"] ?? true;

                // ✅ Ensure child-specific fields are populated correctly
                if (!_isAdult) {
                  _selectedDateOfBirth = memberData["dateOfBirth"] != null
                      ? (memberData["dateOfBirth"] as Timestamp).toDate()
                      : null;
                  _dateOfBirthController.text = _selectedDateOfBirth != null
                      ? _selectedDateOfBirth!.toLocal().toString().split(' ')[0]
                      : "";
                  _schoolNameController.text = memberData["schoolName"] ?? "";
                  _schoolIdNoController.text = memberData["schoolIdNo"] ?? "";
                  _gradeController.text = memberData["grade"] ?? "";
                  _gender = memberData["gender"];
                  _schoolId = memberData["schoolId"];
                }                
            });
        }
    });
  }

  /// Toggles between Adult & Child view
  void _toggleType(bool isAdult) {
    setState(() {
      _isAdult = isAdult;
    });
  }

  /// Opens a file picker and saves the selected file locally
  Future<void> _pickFile(String fileType) async {
    String? savedPath = await _firebaseFunctions.saveFileLocally(fileType);
    if (savedPath != null) {
      setState(() {
        if (fileType == "profilePhoto") _profilePhoto = savedPath;
        if (fileType == "govId") _govId = savedPath;
        if (fileType == "driverLicense") _driverLicense = savedPath;
        if (fileType == "schoolId") _schoolId = savedPath;
      });
    }
  }

  /// Saves family member to Firestore
  Future<void> _saveFamilyMember() async {
    if (_nameController.text.isEmpty || _profilePhoto == null || _govId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all required fields!")));
      return;
    }

    // Additional validation for Children
    if (!_isAdult && _selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select a valid Date of Birth!")));
      return;
    }
    
    if (_memberId != null) {
      await _firebaseFunctions.updateFamilyMember(
        memberId: _memberId!,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        isAdult: _isAdult,
        dateOfBirth: _isAdult ? null : _selectedDateOfBirth,
        profilePhoto: _profilePhoto!,
        govId: _govId!,
        schoolId: _isAdult ? null : _schoolId ?? "",
        schoolName: _isAdult ? null : _schoolNameController.text.trim(),
        schoolIdNo: _isAdult ? null : _schoolIdNoController.text.trim(),
        grade: _isAdult ? null : _gradeController.text.trim(),
        driverLicense: _isAdult ? _driverLicense ?? "" : null,
        address: _addressController.text.trim(),
        gender: _isAdult ? null : (_gender ?? ""),
        relationToChild: _isAdult ? _relationToChild! : null,
      );
    } else {
        await _firebaseFunctions.addFamilyMember(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        isAdult: _isAdult,
        dateOfBirth: _isAdult ? null : _selectedDateOfBirth, // 🔹 Store as timestamp in Firestore
        // dateOfBirth: _isAdult ? null : _dateOfBirthController.text.trim(),
        profilePhoto: _profilePhoto!,
        govId: _govId!,
        schoolId: _isAdult ? null : _schoolId ?? "",
        schoolName: _isAdult ? null : _schoolNameController.text.trim(),
        schoolIdNo: _isAdult ? null : _schoolIdNoController.text.trim(),
        grade: _isAdult ? null : _gradeController.text.trim(),
        driverLicense: _isAdult ? _driverLicense ?? "" : null,
        address: _addressController.text.trim(),
        gender: _isAdult ? null : (_gender ?? ""),
        // relationToChild: _isAdult ? _relationToChild! : null, // 🔹 Removed for Children
        relationToChild: _isAdult ? _relationToChild! : null, // 🔹 Removed for Children
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Family Member Saved!")));
    // _clearFields();
    Navigator.pop(context); // ✅ Go back to Profile screen after saving
  }

  /// Fetch the account owner's address when the screen loads
  Future<void> _fetchOwnerAddress() async {
    var userData = await _firebaseFunctions.getUserData();
    if (userData != null) {
      print("Owner Address Fetched: ${userData["address"]}"); // Debug print
      setState(() {
        _ownerAddress = userData["address"];
      });
    } else {
      print("No address found for owner!"); // Debugging output
    }
  }

  /// Clears form fields after successful save
  void _clearFields() {
    setState(() {
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _dateOfBirthController.clear();
      _selectedDateOfBirth = null;
      _schoolNameController.clear();
      // _schoolIdController.clear();
      _schoolIdNoController.clear();
      _gradeController.clear();
      _addressController.clear();
      _profilePhoto = null;
      _govId = null;
      _schoolId = null;
      _driverLicense = null;
      _gender = null;
      _relationToChild = null;
    });
  }

  /// Opens a date picker and updates the date of birth field
  Future<void> _pickDateOfBirth() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(2000), // Limit selection to reasonable years
      lastDate: DateTime.now(), // Cannot select future dates
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDateOfBirth = pickedDate;
        _dateOfBirthController.text = "${pickedDate.toLocal()}".split(' ')[0]; // Format as YYYY-MM-DD
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Family")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            /// Toggle Button for Adult / Child
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text("Adult"),
                  selected: _isAdult,
                  onSelected: (selected) => _toggleType(true),
                ),
                SizedBox(width: 10),
                ChoiceChip(
                  label: Text("Child"),
                  selected: !_isAdult,
                  onSelected: (selected) => _toggleType(false),
                ),
              ],
            ),
            SizedBox(height: 20),

            /// Common Fields for Both Adult & Child
            _buildTextField("Full Name", _nameController),
            _buildTextField("Email (Optional)", _emailController),
            _buildTextField("Phone Number (Optional)", _phoneController),

            /// Fields only for Child
            if (!_isAdult) ...[
              _buildDatePickerField("Date of Birth", _dateOfBirthController, _pickDateOfBirth),
              // _buildTextField("Date of Birth", _dateOfBirthController),
              _buildTextField("School Name", _schoolNameController),
              _buildTextField("School ID No.", _schoolIdNoController),
              _buildTextField("Grade", _gradeController),

              /// Gender Selection
              DropdownButtonFormField<String>(
                value: _gender,
                items: ["Male", "Female", "Other"].map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) => setState(() => _gender = value),
                decoration: InputDecoration(labelText: "Gender"),
              ),
              SizedBox(height: 10),
            ],

            /// Profile Photo Upload
            _buildFileUploadSection("Profile Photo", _profilePhoto, "profilePhoto"),
            /// Government ID Upload
            _buildFileUploadSection("Government ID", _govId, "govId"),

            /// Driver's License Upload (Only for Adults)
            if (_isAdult) _buildFileUploadSection("Driver License (Optional)", _driverLicense, "driverLicense"),

            /// School ID Upload (Only for Children)
            if (!_isAdult) _buildFileUploadSection("School ID", _schoolId, "schoolId"),

            /// Address Input
            /// UI: Add a button to autofill the address field
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: "Address",
                suffixIcon: _ownerAddress != null
                    ? IconButton(
                        icon: Icon(Icons.home),
                        onPressed: () {
                          setState(() {
                            _addressController.text = _ownerAddress!;
                          });
                        },
                        tooltip: "Use Account Owner's Address",
                      )
                    : null,
              ),
            ),

            /// Relation to Child
            if (_isAdult)
              DropdownButtonFormField<String>(
                value: _relationToChild,
                items: ["Father", "Mother", "Guardian"].map((relation) {
                  return DropdownMenuItem(value: relation, child: Text(relation));
                }).toList(),
                onChanged: (value) => setState(() => _relationToChild = value),
                decoration: InputDecoration(labelText: "Relation to Child"),
              ),
            SizedBox(height: 20),

            /// Save Button
            ElevatedButton(onPressed: _saveFamilyMember, child: Text("Save Family Member")),
          ],
        ),
      ),
    );
  }

  /// Builds a text field
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  /// Builds a file upload button
  Widget _buildFileUploadSection(String label, String? filePath, String fileType) {
    return ListTile(
      title: Text(label),
      subtitle: filePath != null ? Text("Uploaded") : Text("Not uploaded"),
      trailing: ElevatedButton(
        onPressed: () => _pickFile(fileType),
        child: Text(filePath != null ? "Replace" : "Upload"),
      ),
    );
  }

    /// Builds a date picker field
  Widget _buildDatePickerField(String label, TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(labelText: label, suffixIcon: Icon(Icons.calendar_today)),
        onTap: onTap,
      ),
    );
  }
}

// --------------------------------------------------

// 📌 Filename: manage_vehicles.dart
// 📂 Location: modules\profile\screens

// Filename: manage_vehicles.dart  Location: lib/modules/profile/screens/
import 'dart:io'; // Required for handling local file storage
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart'; // Firebase interaction class
import 'package:file_picker/file_picker.dart'; // Used for selecting local files

/// Screen for adding and editing vehicles
class ManageVehiclesScreen extends StatefulWidget {
  final Map<String, dynamic>? vehicleData; // Optional vehicle data for editing

  ManageVehiclesScreen({this.vehicleData});

  @override
  _ManageVehiclesScreenState createState() => _ManageVehiclesScreenState();
}

class _ManageVehiclesScreenState extends State<ManageVehiclesScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions(); // Firebase interaction instance

  // Controllers for text fields
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _registrationNumberController = TextEditingController();
  final TextEditingController _seatingCapacityController = TextEditingController();

  // Image paths for vehicle & registration document
  String? _vehicleImage;
  String? _registrationDocument;
  String? _licensePlateImage; // ✅ License plate image path
  String? _vehicleId; // Used when editing

  bool _isEditing = false; // Tracks if the form is for editing

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      
      if (args is Map<String, dynamic> && args.containsKey("id")) { // ✅ Ensure arguments exist
        print("🚀 Received vehicleData: $args"); // Debugging Output
        
        setState(() {
          _vehicleId = args["id"]; // ✅ Store vehicle ID
          _isEditing = true; // ✅ Enable editing mode
          _makeController.text = args["vehicleMake"] ?? "";
          _modelController.text = args["vehicleModel"] ?? "";
          _yearController.text = args["vehicleYear"]?.toString() ?? "";
          _colorController.text = args["vehicleColor"] ?? "";
          _licenseNumberController.text = args["vehicleLicenseNumber"] ?? "";
          _registrationNumberController.text = args["vehicleRegistrationNumber"] ?? "";
          _seatingCapacityController.text = args["seatingCapacity"]?.toString() ?? "";
          _vehicleImage = args["vehicleImage"];
          _registrationDocument = args["registrationDocument"];
          _licensePlateImage = args['licensePlateImage'];
        });
      } else {
        print("🚨 vehicleData is NULL or missing 'id' field! Editing disabled."); // Debug
      }
    });
  }

  /// If editing, load vehicle data into form fields
  void _initializeForm() {
    if (widget.vehicleData != null && widget.vehicleData!.containsKey("id")) {
      print("Setting _isEditing to true, vehicleId: ${widget.vehicleData!["id"]}");
      setState(() {
        _isEditing = true;
        _vehicleId = widget.vehicleData!["id"]; // ✅ Ensure _vehicleId is assigned
        _makeController.text = widget.vehicleData!["vehicleMake"];
        _modelController.text = widget.vehicleData!["vehicleModel"];
        _yearController.text = widget.vehicleData!["vehicleYear"].toString();
        _colorController.text = widget.vehicleData!["vehicleColor"];
        _licenseNumberController.text = widget.vehicleData!["vehicleLicenseNumber"];
        _registrationNumberController.text = widget.vehicleData!["vehicleRegistrationNumber"];
        _seatingCapacityController.text = widget.vehicleData!["seatingCapacity"].toString();
        _vehicleImage = widget.vehicleData!["vehicleImage"];
        _registrationDocument = widget.vehicleData!["registrationDocument"];
        _licensePlateImage = widget.vehicleData!["licensePlateImage"];
      });
    }
  }

  /// Opens file picker and saves selected file locally
  Future<void> _pickFile(String fileType) async {
    String? savedPath = await _firebaseFunctions.saveFileLocally(fileType);
    if (savedPath != null) {
      setState(() {
        if (fileType == "vehicleImage") _vehicleImage = savedPath;
        if (fileType == "registrationDocument") _registrationDocument = savedPath;
         if (fileType == "licensePlateImage") _licensePlateImage = savedPath; // ✅ New field
      });
    }
  }

  /// Saves or updates vehicle data in Firestore
  Future<void> _saveVehicle() async {
    // Validate required fields
    if (_makeController.text.isEmpty ||
        _modelController.text.isEmpty ||
        _yearController.text.isEmpty ||
        _licenseNumberController.text.isEmpty ||
        _registrationNumberController.text.isEmpty ||
        _seatingCapacityController.text.isEmpty ||
        _vehicleImage == null ||
        _registrationDocument == null ||
        _licensePlateImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all required fields!")));
      return;
    }

    // Convert fields to correct types
    int year = int.tryParse(_yearController.text.trim()) ?? 0;
    int seatingCapacity = int.tryParse(_seatingCapacityController.text.trim()) ?? 0;

    Map<String, dynamic> vehicleData = {
      "vehicleMake": _makeController.text.trim(),
      "vehicleModel": _modelController.text.trim(),
      "vehicleYear": year,
      "vehicleColor": _colorController.text.trim(),
      "vehicleLicenseNumber": _licenseNumberController.text.trim(),
      "vehicleRegistrationNumber": _registrationNumberController.text.trim(),
      "seatingCapacity": seatingCapacity,
      "vehicleImage": _vehicleImage!,
      "registrationDocument": _registrationDocument!,
      "licensePlateImage": _licensePlateImage!, // ✅ Add this line
    };

    if (_isEditing) {
      // ✅ Ensure we pass the existing vehicleId for an update
      await _firebaseFunctions.updateVehicle(
        vehicleId: _vehicleId!,
        vehicleData: vehicleData,
      );
    } else {
      // ✅ Add new vehicle
      await _firebaseFunctions.addVehicle(vehicleData);
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? "Vehicle Updated!" : "Vehicle Added!")));
    Navigator.pop(context); // Return to profile screen
  }

  /// Deletes vehicle after confirmation
  Future<void> _deleteVehicle() async {
    bool confirmDelete = await _showDeleteConfirmationDialog();
    if (confirmDelete && _vehicleId != null) {
      await _firebaseFunctions.deleteVehicle(_vehicleId!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vehicle Deleted!")));
      Navigator.pop(context);
    }
  }

  /// Confirmation dialog for deletion
  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Delete Vehicle"),
            content: Text("Are you sure you want to remove this vehicle?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete", style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }

  /// Builds a text field
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: label.contains("Year") || label.contains("Capacity") ? TextInputType.number : TextInputType.text,
      ),
    );
  }

  /// Builds a file upload button
  Widget _buildFileUploadSection(String label, String? filePath, String fileType) {
    return ListTile(
      title: Text(label),
      subtitle: filePath != null ? Text("Uploaded") : Text("Not uploaded"),
      trailing: ElevatedButton(
        onPressed: () => _pickFile(fileType),
        child: Text(filePath != null ? "Replace" : "Upload"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Vehicle" : "Add Vehicle"),
        actions: _isEditing
            ? [
                IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: _deleteVehicle),
              ]
            : [],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField("Vehicle Make", _makeController),
            _buildTextField("Vehicle Model", _modelController),
            _buildTextField("Vehicle Year", _yearController),
            _buildTextField("Vehicle Color", _colorController),
            _buildTextField("License Number", _licenseNumberController),
            _buildTextField("Registration Number", _registrationNumberController),
            _buildTextField("Seating Capacity", _seatingCapacityController),

            SizedBox(height: 20),

            /// Vehicle Image Upload
            _buildFileUploadSection("Vehicle Image", _vehicleImage, "vehicleImage"),

            /// Registration Document Upload
            _buildFileUploadSection("Registration Document", _registrationDocument, "registrationDocument"),

            // License Plate Image Upload (Mandatory)
            _buildFileUploadSection("License Plate Image", _licensePlateImage, "licensePlateImage"),
            SizedBox(height: 20),

            /// Save Button
            ElevatedButton(onPressed: _saveVehicle, child: Text(_isEditing ? "Update Vehicle" : "Save Vehicle")),
          ],
        ),
      ),
    );
  }
}


// --------------------------------------------------

// 📌 Filename: profile_screen.dart
// 📂 Location: modules\profile\screens

// Filename: profile_screen.dart  Location: lib/modules/profile/screens/
import 'dart:io'; // Required for handling local file storage
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/core/routes.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart'; // Firebase interaction class
import 'package:kccarpoolapp/services/auth_service.dart'; // Authentication service
import 'package:file_picker/file_picker.dart'; // Used for selecting local files

/// The Profile Screen allows users to view and update their details.
/// Users can change their profile picture, update their address, and manage uploaded documents.
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions(); // Firebase interaction instance
  final AuthService _authService = AuthService(); // Authentication service instance

  List<Map<String, dynamic>> _adults = []; // Stores list of adult family members
  List<Map<String, dynamic>> _children = []; // Stores list of child family members
  List<Map<String, dynamic>> _vehicles = []; // Stores list of vehicles
  bool _isLoading = true; // Tracks loading state

  // Controllers for text fields, allowing users to edit their details
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // User profile-related fields
  String? _profilePhoto; // Stores local path of profile photo
  String? _govId; // Stores local path of government ID
  String? _driverLicense; // Stores local path of driver’s license (optional)
  String? _relationToChild; // Stores relation to child (Father, Mother, Guardian)

  bool _isEditing = false; // Controls whether user is in "Edit Mode"

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Fetch user data when the screen loads
    _loadFamilyMembers(); // Fetch family members on screen load
    _loadVehicles(); // Fetch user's vehicles
  }

  /// Fetches the user's profile data from Firestore
  Future<void> _loadUserProfile() async {
    var userData = await _firebaseFunctions.getUserData();
    if (userData != null) {
      setState(() {
        _nameController.text = userData["fullName"] ?? "";
        _emailController.text = userData["email"] ?? "";
        _phoneController.text = userData["phoneNumber"] ?? "";
        _addressController.text = userData["address"] ?? "";
        _profilePhoto = userData["profilePhoto"];
        _govId = userData["govId"];
        _driverLicense = userData["driverLicense"];
        _relationToChild = userData["relationToChild"];
      });
    }
  }

  /// Opens a file picker and saves the selected file locally
  Future<void> _pickFile(String fileType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, // Allows selection of specific file types
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], // Supported file types
    );

    if (result != null) {
      // Save the file locally
      String? savedPath = await _firebaseFunctions.saveFileLocally(fileType);
      if (savedPath != null) {
        setState(() {
          if (fileType == "profilePhoto") _profilePhoto = savedPath;
          if (fileType == "govId") _govId = savedPath;
          if (fileType == "driverLicense") _driverLicense = savedPath;
        });
      }
    }
  }

  /// Saves the updated user profile data to Firestore
  Future<void> _saveProfile() async {
    await _firebaseFunctions.updateUserProfile(
      fullName: _nameController.text,
      phoneNumber: _phoneController.text,
      address: _addressController.text,
      profilePhoto: _profilePhoto!,
      govId: _govId!,
      driverLicense: _driverLicense ?? "",
      relationToChild: _relationToChild!,
    );

    setState(() => _isEditing = false); // Exit edit mode
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile updated!")));
  }

  /// Fetches family members from Firestore and separates them into Adults and Children
  Future<void> _loadFamilyMembers() async {
    List<Map<String, dynamic>> familyData = await _firebaseFunctions.getFamilyMembers();

    setState(() {
      _adults = familyData.where((member) => member['isAdult'] == true).toList();
      _children = familyData.where((member) => member['isAdult'] == false).toList();
      _isLoading = false;
    });
  }

  /// Deletes a family member after confirmation
  void _deleteFamilyMember(String memberId) async {
    bool confirmDelete = await _showDeleteConfirmationDialog();
    if (confirmDelete) {
      await _firebaseFunctions.deleteFamilyMember(memberId);
      _loadFamilyMembers(); // Refresh list after deletion
    }
  }

  /// Shows a confirmation dialog before deleting a family member
  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Delete Family Member"),
            content: Text("Are you sure you want to remove this family member?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete", style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }

  /// Navigates to Manage Family screen for editing a family member
  void _editFamilyMember(Map<String, dynamic> memberData) {
    Navigator.pushNamed(context, AppRoutes.manageFamily, arguments: memberData);
  }

    /// Fetches the user's vehicles from Firestore
  Future<void> _loadVehicles() async {
    List<Map<String, dynamic>> vehicleData = await _firebaseFunctions.getVehicles();

    setState(() {
      _vehicles = vehicleData;
      _isLoading = false;
    });
  }

    /// Deletes a vehicle after confirmation
  void _deleteVehicle(String vehicleId) async {
    bool confirmDelete = await _showDeleteVehicleConfirmationDialog();
    if (confirmDelete) {
      await _firebaseFunctions.deleteVehicle(vehicleId);
      _loadVehicles(); // Refresh list after deletion
    }
  }

    /// Shows a confirmation dialog before deleting a vehicle
  Future<bool> _showDeleteVehicleConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Delete Vehicle"),
            content: Text("Are you sure you want to remove this vehicle?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete", style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }

  /// Navigates to Manage Vehicles screen for adding/editing a vehicle
  void _manageVehicle({Map<String, dynamic>? vehicleData}) {
  if (vehicleData != null && vehicleData.containsKey("id")) { // ✅ Ensure `id` exists when editing
    print("🚀 Navigating to ManageVehiclesScreen with: $vehicleData"); // Debug
  } else {
    print("🚀 Navigating to ManageVehiclesScreen for adding a new vehicle."); // Debug
  }

    Navigator.pushNamed(
      context,
      AppRoutes.manageVehicles,
      arguments: vehicleData, // ✅ Pass data if editing, otherwise null for adding
    ).then((_) => _loadVehicles()); // ✅ Reload vehicle list after returning
  }
  

  /// Logs the user out and navigates back to the login screen
  Future<void> _logout() async {
    await _authService.logout(context); // Properly handles logout and navigation
  }  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          // Logout Button
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            /// Profile Picture Section
            GestureDetector(
              onTap: () => _pickFile("profilePhoto"),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profilePhoto != null ? FileImage(File(_profilePhoto!)) : null,
                child: _profilePhoto == null ? Icon(Icons.person, size: 50) : null,
              ),
            ),
            SizedBox(height: 20),

            /// Editable Text Fields
            _buildTextField("Full Name", _nameController, _isEditing),
            _buildTextField("Email", _emailController, false),
            _buildTextField("Phone Number", _phoneController, _isEditing),
            _buildTextField("Address", _addressController, _isEditing),

            /// File Upload Sections
            _buildFileUploadSection("Government ID", _govId, "govId"),
            _buildFileUploadSection("Driver License (Optional)", _driverLicense, "driverLicense"),

            /// Relation to Child Dropdown (Only editable in Edit Mode)
            if (_isEditing)
              DropdownButtonFormField<String>(
                value: _relationToChild,
                items: ["Father", "Mother", "Guardian"].map((relation) {
                  return DropdownMenuItem(value: relation, child: Text(relation));
                }).toList(),
                onChanged: (value) {
                  setState(() => _relationToChild = value);
                },
                decoration: InputDecoration(labelText: "Relation to Child"),
              ),
            SizedBox(height: 20),

            /// Save / Edit Profile Button
            _isEditing
                ? ElevatedButton(onPressed: _saveProfile, child: Text("Save"))
                : ElevatedButton(onPressed: () => setState(() => _isEditing = true), child: Text("Edit Profile")),
          
            // ✅ Manage Family Button
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.manageFamily); // ✅ Navigate to Manage Family
              },
              icon: Icon(Icons.family_restroom),
              label: Text("Manage Family"),
            ),

            SizedBox(height: 20),

            // Family Members Section
            Text("Your Family Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            // Adults Section
            if (_adults.isNotEmpty) ...[
              Text("Adults", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              _buildFamilyList(_adults),
              SizedBox(height: 10),
            ],

            // Children Section
            if (_children.isNotEmpty) ...[
              Text("Children", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              _buildFamilyList(_children),
            ],

            SizedBox(height: 20),

            /// Manage Vehicles Button
            ElevatedButton.icon(
              onPressed: () => _manageVehicle(),
              icon: Icon(Icons.directions_car),
              label: Text("Manage Vehicles"),
            ),

            SizedBox(height: 20),

            /// Vehicles List Section
            if (_vehicles.isNotEmpty) ...[
              Text("Your Vehicles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildVehicleList(),
            ],            
          ],
        ),
      ),
    );
  }

  /// Builds a text field with optional editing capability
  Widget _buildTextField(String label, TextEditingController controller, bool isEditable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: isEditable,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  /// Builds a section for file uploads
  Widget _buildFileUploadSection(String label, String? filePath, String fileType) {
    return ListTile(
      title: Text(label),
      subtitle: filePath != null ? Text("Uploaded") : Text("Not uploaded"),
      trailing: ElevatedButton(
        onPressed: () => _pickFile(fileType),
        child: Text(filePath != null ? "Replace" : "Upload"),
      ),
    );
  }

  /// Builds a scrollable list of family members
  Widget _buildFamilyList(List<Map<String, dynamic>> familyMembers) {
    return Column(
      children: familyMembers.map((member) {
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: member['profilePhoto'] != null ? FileImage(File(member['profilePhoto'])) : null,
              child: member['profilePhoto'] == null ? Icon(Icons.person) : null,
            ),
            title: Text(member['fullName']),
            subtitle: Text(member['isAdult']
                ? member['relationToChild'] // Show relation for adults
                : "Age: ${_calculateAge(member['dateOfBirth'])}"), // Show age for children
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.edit), onPressed: () => _editFamilyMember(member)), // Edit Button
                IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteFamilyMember(member['id'])), // Delete Button
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Helper function to calculate age from Firestore Timestamp
  int _calculateAge(Timestamp dobTimestamp) {
    DateTime birthDate = dobTimestamp.toDate(); // Convert Firestore Timestamp to DateTime
    DateTime today = DateTime.now();

    int age = today.year - birthDate.year;
    
    // Adjust age if birthday hasn't occurred yet this year
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /// Builds a scrollable list of vehicles
  Widget _buildVehicleList() {
    return Column(
      children: _vehicles.map((vehicle) {
        print("Building vehicle list: $vehicle"); // 🔍 Debugging Output
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            leading: vehicle['vehicleImage'] != null
                ? Image.file(File(vehicle['vehicleImage']), width: 50, height: 50, fit: BoxFit.cover)
                : Icon(Icons.directions_car, size: 50),
            title: Text("${vehicle['vehicleMake']} ${vehicle['vehicleModel']}"),
            subtitle: Text("License No: ${vehicle['vehicleLicenseNumber']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // IconButton(icon: Icon(Icons.edit), onPressed: () => _manageVehicle(vehicleData: vehicle)), // Edit Button
              
                IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  if (vehicle.containsKey("id")) {
                    _manageVehicle(vehicleData: vehicle);
                  } else {
                    print("Error: Vehicle data missing 'id' field!"); // 🔍 Debug
                  }
                },
              ),


                IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteVehicle(vehicle['id'])), // Delete Button
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// --------------------------------------------------

// 📌 Filename: auth_service.dart
// 📂 Location: services

// Filename: auth_service.dart  Location: lib/services/
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/core/routes.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';

/// AuthService - Handles authentication-related functions across the app
class AuthService {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions(); // Use FirebaseFunctions

  /// Logs out the current user and redirects to the login screen
  Future<void> logout(BuildContext context) async {
    await _firebaseFunctions.logout(); // Call FirebaseFunctions logout
    Navigator.of(context).pushReplacementNamed(AppRoutes.login); // Ensure user is redirected to login
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




  // /// Logs out the current user and redirects to the login screen
  // Future<void> logout(BuildContext context) async {
  //   await _firebaseFunctions.logout(); // Call FirebaseFunctions logout
  //   Navigator.of(context).pushReplacementNamed('/login'); // Navigate back to login
  // }

// --------------------------------------------------

// 📌 Filename: firebase_functions.dart
// 📂 Location: services

// Filename: firebase_functions.dart  Location: lib/services/
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// FirebaseFunctions - Centralized class for Firebase Authentication and Firestore interactions
class FirebaseFunctions {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

  /// Fetches user ID of the currently logged-in user
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

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
  Future<String?> signUp(String fullName, String email, String phoneNumber, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // Save user data in Firestore immediately after signup
      await saveUserData(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
      );

      print("Signup and user data saved successfully.");
      return null; // Success
    } catch (e) {
      return 'Signup failed. Try a different email.';
    }
  }

  /// Fetch user profile data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      DocumentSnapshot userDoc = await _firestore.collection("users").doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userData["id"] = userId; // ✅ Explicitly add user ID
        return userData;
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return null;
  }
  // Future<Map<String, dynamic>?> getUserData() async {
  //   User? user = _auth.currentUser;
  //   if (user == null) return null; // No user logged in

  //   try {
  //     DocumentSnapshot userDoc = await _firestore.collection("users").doc(user.uid).get();

  //     if (userDoc.exists) {
  //       return userDoc.data() as Map<String, dynamic>; // Return user data
  //     } else {
  //       return null; // No data found
  //     }
  //   } catch (e) {
  //     print("Error fetching user data: $e");
  //     return null;
  //   }
  // }

  /// Updates user profile data in Firestore
  Future<void> updateUserProfile({
    required String fullName,
    required String phoneNumber,
    required String address,
    required String profilePhoto,
    required String govId,
    required String? driverLicense,
    required String relationToChild,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("No authenticated user found.");

    try {
      await _firestore.collection("users").doc(user.uid).set({
        "fullName": fullName,
        "phoneNumber": phoneNumber,
        "address": address.trim(),
        "profilePhoto": profilePhoto,
        "govId": govId,
        "driverLicense": driverLicense ?? "",
        "relationToChild": relationToChild,
      }, SetOptions(merge: true)); // ✅ Ensures previous data is not erased

      print("User profile updated successfully.");
    } catch (e) {
      print("Error updating user profile: $e");
      throw Exception("Failed to update user profile.");
    }
  }

  /// Save user signup data in Firestore
  Future<void> saveUserData({
    required String fullName,
    required String email,
    required String phoneNumber,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("No authenticated user found.");

    try {
      await _firestore.collection("users").doc(user.uid).set({
        "fullName": fullName,
        "email": email,
        "phoneNumber": phoneNumber,
        "emailVerified": false, // Initially false, updated after verification
        "phoneVerified": false, // Initially false, updated after verification
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("Signup data saved successfully.");
    } catch (e) {
      print("Error saving signup data: $e");
      throw Exception("Failed to save user data.");
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

  /// When OTP verification is successful, we update the Firestore document
  Future<void> markVerificationSuccess({
    required bool emailVerified,
    required bool phoneVerified,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("No authenticated user found.");

    try {
      await _firestore.collection("users").doc(user.uid).update({
        "emailVerified": emailVerified,
        "phoneVerified": phoneVerified,
      });

      print("User verification status updated.");
    } catch (e) {
      print("Error updating verification status: $e");
      throw Exception("Failed to update verification status.");
    }
  }

  /// Save files locally to system
  Future<String?> saveFileLocally(String fileType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      try {
        Directory? appDocDir = await getExternalStorageDirectory();
        if (appDocDir == null) {
          print("Failed to get external storage directory.");
          return null;
        }

        String localPath = '${appDocDir.path}/$fileType';
        Directory(localPath).createSync(recursive: true);

        File file = File(result.files.single.path!);
        String newFilePath = '$localPath/${result.files.single.name}';
        await file.copy(newFilePath);

        print("File saved publicly at: $newFilePath");
        return newFilePath;
      } catch (e) {
        print("Error saving file locally: $e");
        return null;
      }
    } else {
      print("No file selected");
      return null;
    }
  }  


  /// Saves user verification data in Firestore
  Future<void> saveVerificationData({
    required String profilePhoto,
    required String govId,
    required String? driverLicense,
    required String address,
    required String relationToChild,
  }) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    Map<String, dynamic> verificationData = {
      "profilePhoto": profilePhoto,
      "driverLicense": driverLicense ?? "",
      "govId": govId,
      "address": address.trim(),
      "relationToChild": relationToChild,
      "emailVerified": true, // Placeholder for now
      "phoneVerified": true, // Placeholder for now
    };

    try {
      await FirebaseFirestore.instance.collection("users").doc(userId).set(
        verificationData,
        SetOptions(merge: true), // ✅ Ensures previous data is not erased
      );
      print("Verification data saved successfully!");
    } catch (e) {
      print("Error saving verification data: $e");
    }
  }


  /// Adds a new family member (adult or child) under the logged-in user
  Future<void> addFamilyMember({
    required String fullName,
    required String? email,
    required String? phoneNumber,
    required bool isAdult, // Differentiates between Adult & Child
    DateTime? dateOfBirth, // Only for children
    required String profilePhoto,
    required String govId,
    String? schoolId, // Only for children
    String? schoolName, // Only for children
    String? schoolIdNo, // Only for children
    String? grade, // Only for children
    String? driverLicense, // Only for adults (Optional)
    required String address,
    String? gender, // Only for children
    String? relationToChild,
  }) async {
    String? userId = getCurrentUserId();
    if (userId == null) throw Exception("No authenticated user found.");

    try {
      await _firestore.collection("users").doc(userId).collection("family").add({
        "fullName": fullName,
        "email": email ?? "",
        "phoneNumber": phoneNumber ?? "",
        "isAdult": isAdult,
        "dateOfBirth": isAdult ? null : Timestamp.fromDate(dateOfBirth!),
        // "dateOfBirth": isAdult ? null : Timestamp.fromDate(DateTime.parse(dateOfBirth!)),
        "profilePhoto": profilePhoto,
        "govId": govId,
        "driverLicense": isAdult ? driverLicense ?? "" : null,
        "schoolId": isAdult ? null : schoolId ?? "",
        "schoolName": isAdult ? null : schoolName ?? "",
        "schoolIdNo": isAdult ? null : schoolIdNo ?? "",
        "grade": isAdult ? null : grade ?? "",
        "address": address,
        "gender": isAdult ? null : gender,
        "relationToChild": relationToChild,
        "timestamp": FieldValue.serverTimestamp(),
      });

      print("Family member added successfully.");
    } catch (e) {
      print("Error adding family member: $e");
      throw Exception("Failed to add family member.");
    }
  }

  /// Fetches all family members of the logged-in user from Firestore
  Future<List<Map<String, dynamic>>> getFamilyMembers() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    try {
      QuerySnapshot snapshot = await _firestore.collection("users").doc(user.uid).collection("family").get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Store document ID for editing/deleting
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching family members: $e");
      return [];
    }
  }

  /// Deletes a family member from Firestore
  Future<void> deleteFamilyMember(String memberId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection("users").doc(user.uid).collection("family").doc(memberId).delete();
      print("Family member deleted successfully.");
    } catch (e) {
      print("Error deleting family member: $e");
    }
  }

  /// Fetches family members and vehicles of the logged-in user
  Future<Map<String, dynamic>> fetchFamilyAndVehicles() async {
    String? userId = getCurrentUserId();
    if (userId == null) throw Exception("No authenticated user found.");

    List<Map<String, dynamic>> familyMembers = [];
    List<Map<String, dynamic>> vehicles = [];

    try {
      // Fetch family members
      QuerySnapshot familySnapshot =
          await _firestore.collection("users").doc(userId).collection("family").get();
      for (var doc in familySnapshot.docs) {
        familyMembers.add(doc.data() as Map<String, dynamic>);
      }

      // Fetch vehicles
      QuerySnapshot vehicleSnapshot =
          await _firestore.collection("users").doc(userId).collection("vehicles").get();
      for (var doc in vehicleSnapshot.docs) {
        vehicles.add(doc.data() as Map<String, dynamic>);
      }

      return {"family": familyMembers, "vehicles": vehicles};
    } catch (e) {
      print("Error fetching family & vehicles: $e");
      throw Exception("Failed to fetch data.");
    }
  }

  /// ✅ Updates an existing family member in Firestore
  Future<void> updateFamilyMember({
    required String memberId,
    required String fullName,
    required String? email,
    required String? phoneNumber,
    required bool isAdult,
    DateTime? dateOfBirth,
    required String profilePhoto,
    required String govId,
    String? schoolId,
    String? schoolName,
    String? schoolIdNo,
    String? grade,
    String? driverLicense,
    required String address,
    String? gender,
    String? relationToChild,
  }) async {
    String? userId = getCurrentUserId();
    if (userId == null) throw Exception("No authenticated user found.");

    try {
      await _firestore.collection("users").doc(userId).collection("family").doc(memberId).update({
        "fullName": fullName,
        "email": email ?? "",
        "phoneNumber": phoneNumber ?? "",
        "isAdult": isAdult,
        "dateOfBirth": isAdult ? null : Timestamp.fromDate(dateOfBirth!),
        "profilePhoto": profilePhoto,
        "govId": govId,
        "driverLicense": isAdult ? driverLicense ?? "" : null,
        "schoolId": isAdult ? null : schoolId ?? "",
        "schoolName": isAdult ? null : schoolName ?? "",
        "schoolIdNo": isAdult ? null : schoolIdNo ?? "",
        "grade": isAdult ? null : grade ?? "",
        "address": address,
        "gender": isAdult ? null : gender,
        "relationToChild": relationToChild,
      });
    } catch (e) {
      print("Error updating family member: $e");
      throw Exception("Failed to update family member.");
    }
  }

    /// 🔹 **Adds a new vehicle to Firestore**
  Future<void> addVehicle(Map<String, dynamic> vehicleData) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("No authenticated user found.");

    try {
      await _firestore.collection("users").doc(user.uid).collection("vehicles").add(vehicleData);
      print("✅ Vehicle added successfully.");
    } catch (e) {
      print("❌ Error adding vehicle: $e");
      throw Exception("Failed to add vehicle.");
    }
  }

  /// Updates an existing vehicle in Firestore
  Future<void> updateVehicle({
    required String vehicleId,
    required Map<String, dynamic> vehicleData, // Pass the whole vehicle map
  }) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("vehicles")
          .doc(vehicleId)
          .update(vehicleData); // Update with the whole map

      print("Vehicle Updated Successfully!");
    } catch (e) {
      print("Error updating vehicle: $e");
      throw Exception("Failed to update vehicle.");
    }
  }

  /// 🔹 **Deletes a vehicle from Firestore**
  Future<void> deleteVehicle(String vehicleId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("No authenticated user found.");

    try {
      await _firestore.collection("users").doc(user.uid).collection("vehicles").doc(vehicleId).delete();
      print("✅ Vehicle deleted successfully.");
    } catch (e) {
      print("❌ Error deleting vehicle: $e");
      throw Exception("Failed to delete vehicle.");
    }
  }

  /// 🔹 **Retrieves the list of vehicles for the logged-in user**
  Future<List<Map<String, dynamic>>> getVehicles() async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("No authenticated user found.");

    try {
      QuerySnapshot vehicleSnapshot =
          await _firestore.collection("users").doc(user.uid).collection("vehicles").get();

      List<Map<String, dynamic>> vehicles = vehicleSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data["id"] = doc.id; // Include document ID for editing/deleting
        return data;
      }).toList();

      return vehicles;
    } catch (e) {
      print("❌ Error fetching vehicles: $e");
      throw Exception("Failed to retrieve vehicles.");
    }
  }


  /// Creates a new carpool in Firestore
  Future<void> createCarpool({
    required String carpoolName,
    required String carpoolRouteStart,
    required String carpoolRouteEnd,
    required Timestamp carpoolDate,
    required Timestamp carpoolTime,
    required String carpoolVehicleId,
    required String carpoolOwnerId,
    required String carpoolDriverId,
    required int carpoolCapacity,
    required bool carpoolReturnTrip,
    bool? carpoolReturnStayOnLocation,
  }) async {
    try {
      // Reference to the logged-in user's Firestore document
      String userId = FirebaseAuth.instance.currentUser!.uid;
      CollectionReference carpoolCollection = FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("carpools");

      // Generate a unique carpool ID
      String carpoolId = carpoolCollection.doc().id;

      // Create the carpool document
      await carpoolCollection.doc(carpoolId).set({
        "carpoolId": carpoolId,
        "carpoolName": carpoolName,
        "carpoolRouteStart": carpoolRouteStart,
        "carpoolRouteEnd": carpoolRouteEnd,
        "carpoolDate": carpoolDate,
        "carpoolTime": carpoolTime,
        "carpoolVehicleId": carpoolVehicleId,
        "carpoolOwnerId": carpoolOwnerId,
        "carpoolDriverId": carpoolDriverId,
        "carpoolCapacity": carpoolCapacity,
        "carpoolReturnTrip": carpoolReturnTrip,
        "carpoolReturnStayOnLocation": carpoolReturnStayOnLocation ?? false,
        "carpoolStatus": "Available",
        "createdAt": FieldValue.serverTimestamp(), // Track creation time
      });
      print("✅ Carpool successfully created!");
    } catch (e) {
      print("🔥 Error creating carpool: $e");
      throw Exception("Failed to create carpool.");
    }
  }

  /// Fetches all carpools for the logged-in user
  Future<List<Map<String, dynamic>>> getCarpools() async {
    try {
      // Get logged-in user's ID
      String userId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("carpools")
          .orderBy("carpoolDate", descending: false) // Order by date
          .get();

      // Convert documents into a list of maps
      List<Map<String, dynamic>> carpools = querySnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      return carpools;
    } catch (e) {
      print("🔥 Error fetching carpools: $e");
      throw Exception("Failed to fetch carpools.");
    }
  }

  /// Updates an existing carpool in Firestore
  Future<void> updateCarpool({
    required String carpoolId,
    required Map<String, dynamic> updatedData,
  }) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("carpools")
          .doc(carpoolId)
          .update(updatedData);

      print("✅ Carpool successfully updated!");
    } catch (e) {
      print("🔥 Error updating carpool: $e");
      throw Exception("Failed to update carpool.");
    }
  }

  /// Deletes a carpool from Firestores
  Future<void> deleteCarpool(String carpoolId) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("carpools")
          .doc(carpoolId)
          .delete();

      print("✅ Carpool successfully deleted!");
    } catch (e) {
      print("🔥 Error deleting carpool: $e");
      throw Exception("Failed to delete carpool.");
    }
  }

  /// Checks if a vehicle is already booked for a given date and time
  Future<bool> isVehicleAvailable({
    required String vehicleId,
    required Timestamp carpoolDate,
    required Timestamp carpoolTime,
  }) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("carpools")
          .where("carpoolVehicleId", isEqualTo: vehicleId)
          .where("carpoolDate", isEqualTo: carpoolDate)
          .get();

      for (var doc in snapshot.docs) {
        Timestamp existingTime = doc["carpoolTime"];
        // We assume exact match is a conflict. Later we can add buffer/overlap logic.
        if (existingTime.toDate().hour == carpoolTime.toDate().hour &&
            existingTime.toDate().minute == carpoolTime.toDate().minute) {
          return false; // Conflict found
        }
      }

      return true; // No conflicts found
    } catch (e) {
      print("Error checking vehicle availability: $e");
      throw Exception("Failed to check vehicle availability.");
    }
  }
}

// --------------------------------------------------

