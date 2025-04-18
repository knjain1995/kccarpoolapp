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
      title: 'KCCarpoolApp',
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
import 'package:kccarpoolapp/modules/carpool/screens/explore_carpools_screen.dart';
import 'package:kccarpoolapp/modules/carpool/screens/join_requests_screen.dart';
import 'package:kccarpoolapp/modules/home/screens/home_screen.dart';
import 'package:kccarpoolapp/modules/onboarding/onboarding_screen.dart';
import 'package:kccarpoolapp/modules/profile/screens/manage_family.dart';
import 'package:kccarpoolapp/modules/profile/screens/manage_vehicles.dart';
import 'package:kccarpoolapp/modules/profile/screens/profile_screen.dart';
import 'package:kccarpoolapp/modules/carpool/screens/carpool_list_screen.dart';


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
  static const String carpoolList = '/carpoolList';
  static const String exploreCarpools = '/explore-carpools';
  static const String joinRequests = '/join-requests';



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
    carpoolList: (context) => CarpoolListScreen(),
    exploreCarpools: (context) => ExploreCarpoolsScreen(),
    joinRequests: (context) => JoinRequestsScreen(),
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
  final TextEditingController _emailController = TextEditingController(text: 'knjain100@gmail.com'); // Default test email (Remove before production)
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
import 'package:kccarpoolapp/utils/file_utils.dart';
import 'package:kccarpoolapp/utils/ui_helpers.dart'; // For handleFileUpload

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
              onPressed: () => handleFileUpload(
                context: context,
                fileType: "profilePhoto",
                firebaseFunctions: _firebaseFunctions,
                allowedExtensions: ['jpg', 'jpeg', 'png'],
                onFilePicked: (path) => setState(() => _photoFile = path),
              ),
              child: Text(_photoFile == null ? "Upload Photo" : "Photo Saved Locally ✅"),
            ),
            // ElevatedButton(
            //   onPressed: () async {
            //     String? pickedPath = await FileUtils.pickFile(allowedExtensions: ['jpg', 'jpeg', 'png']);
            //     if (pickedPath != null) {
            //       String? path = await _firebaseFunctions.saveFileLocally("profilePhoto", pickedPath);
            //       if (path != null) {
            //         setState(() {
            //           _photoFile = path;
            //         });
            //         print("Profile photo saved at: $path");
            //       }
            //     }
            //   },
            //   child: Text(_photoFile == null ? "Upload Photo" : "Photo Saved Locally ✅"),
            // ),
            SizedBox(height: 10),

            /// Upload Driver License (Optional)
            Text("Upload Driver License (Optional)"),
            ElevatedButton(
              onPressed: () => handleFileUpload(
                context: context,
                fileType: "driverLicense",
                firebaseFunctions: _firebaseFunctions,
                allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                onFilePicked: (path) => setState(() => _driverLicenseFile = path),
              ),
              child: Text(_driverLicenseFile == null ? "Upload License" : "License Uploaded ✅"),
            ),
            // ElevatedButton(
            //   onPressed: () async {
            //     String? pickedPath = await FileUtils.pickFile(allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf']);
            //     if (pickedPath != null) {
            //       String? path = await _firebaseFunctions.saveFileLocally("driverLicense", pickedPath);
            //       if (path != null) {
            //         setState(() {
            //           _driverLicenseFile = path;
            //         });
            //         print("License saved at: $path");
            //       }
            //     }
            //   },
            //   child: Text(_driverLicenseFile == null ? "Upload License" : "License Uploaded ✅"),
            // ),
            SizedBox(height: 10),
            
            /// Upload Government ID (Required)
            Text("Upload Government ID (Required)"),
            ElevatedButton(
              onPressed: () => handleFileUpload(
                context: context,
                fileType: "govId",
                firebaseFunctions: _firebaseFunctions,
                allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                onFilePicked: (path) => setState(() => _govIdFile = path),
              ),
              child: Text(_govIdFile == null ? "Upload ID" : "ID Uploaded ✅"),
            ),
            // ElevatedButton(
            //   onPressed: () async {
            //     String? pickedPath = await FileUtils.pickFile(allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf']);
            //     if (pickedPath != null) {
            //       String? path = await _firebaseFunctions.saveFileLocally("govId", pickedPath);
            //       if (path != null) {
            //         setState(() {
            //           _govIdFile = path;
            //         });
            //         print("Govt ID saved at: $path");
            //       }
            //     }
            //   },
            //   child: Text(_govIdFile == null ? "Upload ID" : "ID Uploaded ✅"),
            // ),
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

import 'package:flutter/material.dart';
import 'package:kccarpoolapp/core/routes.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';
import 'package:kccarpoolapp/modules/carpool/widgets/carpool_card.dart';


class CarpoolListScreen extends StatefulWidget {
  @override
  _CarpoolListScreenState createState() => _CarpoolListScreenState();
}

class _CarpoolListScreenState extends State<CarpoolListScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();
  List<Map<String, dynamic>> _carpools = [];
  bool _isLoading = false; // 🌀 Indicates whether we are fetching carpools

  @override
  void initState() {
    super.initState();
    _loadCarpools(); // 🔹 Fetch user's carpools on screen load
  }

  /// Loads carpools created by the logged-in user
  Future<void> _loadCarpools() async {
    setState(() => _isLoading = true); // 🌀 Start loading spinner

    List<Map<String, dynamic>> rawCarpools = await _firebaseFunctions.getCarpools();

    // 🔄 Fetch driver & vehicle info for each carpool
    List<Map<String, dynamic>> enrichedCarpools = [];

    for (var carpool in rawCarpools) {
      // 🔸 Fetch Driver Info
      final driverData = await _firebaseFunctions.getDriverById(
        driverId: carpool["carpoolDriverId"],
      );
      carpool['driverName'] = driverData?['fullName'] ?? "Unknown";
      carpool['driverPhoto'] = driverData?['profilePhoto'];

      // 🔸 Fetch Vehicle Info
      var vehicleData = await _firebaseFunctions.getVehicleById(carpool['carpoolVehicleId']);
      carpool['vehicleMakeModel'] = vehicleData != null
          ? "${vehicleData['vehicleMake']} ${vehicleData['vehicleModel']}"
          : "Unknown Vehicle";
      carpool['vehicleImage'] = vehicleData?['vehicleImage'];

      // Inside the for-loop that enriches each carpool:
      final List<String> participantIds = List<String>.from(carpool['carpoolParticipants'] ?? []);
      final List<Map<String, dynamic>> resolvedParticipants =
          await _firebaseFunctions.getCarpoolParticipants(
        carpoolDriverId: carpool['carpoolDriverId'],
        participantIds: participantIds,
      );
      carpool['resolvedParticipants'] = resolvedParticipants;

      enrichedCarpools.add(carpool);
    }

    setState(() {
      _carpools = enrichedCarpools;
      _isLoading = false; // ✅ Stop spinner after data is loaded
    });
  }

  /// Deletes a carpool by ID
  Future<void> _deleteCarpool(String carpoolId) async {
    setState(() => _isLoading = true); // 🌀 Show loading during deletion

    try {
      await _firebaseFunctions.deleteCarpool(carpoolId);
      await _loadCarpools(); // 🔁 Refresh list after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Carpool deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting carpool: $e")),
      );
    } finally {
      setState(() => _isLoading = false); // ✅ Stop spinner
    }
  }

  /// 🔹 Builds the full screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Carpools")),
      
      // 🪄 Sticky Create Button (FloatingActionButton)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createCarpool);
        },
        child: Icon(Icons.add),
        tooltip: "Create Carpool",
      ),

  body: _isLoading
    ? Center(child: CircularProgressIndicator()) // 🌀 Show spinner
    : _carpools.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text("No Carpools Yet!",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  "Start by creating your first carpool.",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        : RefreshIndicator(
        onRefresh: _loadCarpools, // 🔁 Pull to refresh
        child: ListView.builder(
          itemCount: _carpools.length,
          itemBuilder: (context, index) {
            return CarpoolCard(
              carpool: _carpools[index], // 🔹 Send carpool data
              onDelete: _deleteCarpool,  // 🔹 Pass delete handler from your screen
            );
          },
        ),
      ),
    );
  }
}


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
import 'package:kccarpoolapp/utils/ui_helpers.dart'; // For buildTextField

/// Screen for Creating a New Carpool
class CreateCarpoolScreen extends StatefulWidget {
  @override
  _CreateCarpoolScreenState createState() => _CreateCarpoolScreenState();
}

class _CreateCarpoolScreenState extends State<CreateCarpoolScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();

  Map<String, dynamic>? _editingCarpool; // Will store carpool data for editing
  String? _carpoolId; // Firestore document ID
  bool _isEditing = false; // Whether we're editing an existing carpool

  // 👨‍👩‍👧‍👦 Stores selected participant IDs for this carpool
  List<String> _carpoolParticipants = [];

  // Controllers for input fields
  final TextEditingController _carpoolNameController = TextEditingController();
  final TextEditingController _routeStartController = TextEditingController();
  final TextEditingController _routeEndController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController(text: "4");
  Map<String, dynamic>? _loggedInUserData;

  // Date & Time Selection
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Vehicle & Driver Selection
  String? _selectedVehicle;
  String? _selectedOwner;
  String? _selectedDriver;
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _adults = []; // Account owner & adults in the family
  List<Map<String, dynamic>> _familyMembers = []; // 🔹 All family members for participant selection
  List<String> _selectedParticipants = []; // 🔹 Stores selected participant IDs
  int? _vehicleMaxCapacity; // Holds the selected vehicle’s seatingCapacity

  // Return Trip Options
  bool _hasReturnTrip = false;
  bool _stayOnLocation = false;

  @override
  void initState() {
    super.initState();

    // Ensures we access route arguments only after widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 🔄 Check if carpool data is passed for editing
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

      if (args != null && args.containsKey('carpoolData')) {
        _editingCarpool = args['carpoolData']; // 📦 Store the carpool data
        _carpoolId = _editingCarpool!['carpoolId']; // 🆔 Save Firestore doc ID
        _isEditing = true; // ✅ We're in edit mode

        // ⬅️ Prefill form fields using the existing carpool data
        _preFillFormWithCarpoolData(_editingCarpool!);
      }

      _fetchUserData(); // 🔄 Always fetch vehicles & adults
    });
  }
  
  /// Fetches the logged-in user's profile, family members, and vehicles.
  /// Refactored to use the flat user model instead of nested subcollections.
  /// This method supports smart defaults (driver auto-select, vehicle availability) and ensures the carpool form is prefilled properly.
  Future<void> _fetchUserData() async {
    // 🔹 Get current account owner's document from top-level `users/` collection
    _loggedInUserData = await _firebaseFunctions.getUserData();

    // 🔹 Get all family members using the new flat structure (includes account owner implicitly)
    final familyMembers = await _firebaseFunctions.getFamilyMembersByIds();

    // 🔹 Get vehicles owned by the current user (this logic is NOT changed in this phase)
    final vehicleData = await _firebaseFunctions.getFamilyVehicles();

    // 🔹 If carpool date/time is selected, check vehicle availability
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

        // 🔸 In edit mode, allow selected vehicle even if it's normally "unavailable"
        if (_isEditing && vehicle['id'] == _selectedVehicle) {
          available = true;
        }

        vehicle['isAvailable'] = available;
      }
    } else {
      // 🔸 If date/time not selected, allow all vehicles by default
      for (var vehicle in vehicleData) {
        vehicle['isAvailable'] = true;
      }
    }

    setState(() {
      _vehicles = vehicleData;

      // ✅ Account owner is already included in the result of getUserData()
      // Used for setting ownership in carpool creation
      _selectedOwner = _loggedInUserData?["id"];

      // ✅ Update member and adult lists from flat user data
      _familyMembers = familyMembers;

      // 🔹 Drivers must be adults AND have a non-empty driver license
      _adults = familyMembers
          .where((m) =>
              m["isAdult"] == true &&
              (m["driverLicense"]?.toString().isNotEmpty ?? false))
          .toList();

      // ✅ Smart default: if only one valid driver, auto-select them
      if (_adults.length == 1) {
        _selectedDriver = _adults.first["id"];
      }

      // ✅ Preserve vehicle prefill logic in edit mode
      if (_isEditing && _selectedVehicle != null) {
        _onVehicleSelected(_selectedVehicle!);
      }
    });
  }


  // /// Fetches the user's vehicles & family members (for selecting driver & owner)
  // Future<void> _fetchUserData() async {
  //   var userData = await _firebaseFunctions.getUserData();
  //   var familyMembers = await _firebaseFunctions.getFamilyMembers();
  //   var vehicleData = await _firebaseFunctions.getVehicles();
  //   _loggedInUserData = await _firebaseFunctions.getUserData();

  //    // 🔄 If date/time is selected, check availability for each vehicle
  //   if (_selectedDate != null && _selectedTime != null) {
  //     for (var vehicle in vehicleData) {
  //       bool available = await _firebaseFunctions.isVehicleAvailable(
  //       vehicleId: vehicle['id'],
  //       carpoolDate: Timestamp.fromDate(_selectedDate!),
  //       carpoolTime: Timestamp.fromDate(DateTime(
  //         _selectedDate!.year,
  //         _selectedDate!.month,
  //         _selectedDate!.day,
  //         _selectedTime!.hour,
  //         _selectedTime!.minute,
  //       )),
  //     );

  //     // ✅ If in edit mode and this vehicle is the selected one, allow it
  //     if (_isEditing && vehicle['id'] == _selectedVehicle) {
  //       available = true;
  //     }

  //     vehicle['isAvailable'] = available; // 🔹 Tag vehicle as available/unavailable
  //     }
  //   } else {
  //     // If no time/date selected yet, assume all available
  //     for (var vehicle in vehicleData) {
  //       vehicle['isAvailable'] = true;
  //     }
  //   }

  //   setState(() {
  //     _selectedOwner = _loggedInUserData?["id"];
  //     print("Selected Owner:");
  //     print(_selectedOwner);

  //     // add all adults of the family
  //     _adults = familyMembers.where((member) => member["isAdult"] == true).toList();

  //     // add all members of the family
  //     _familyMembers.clear(); // ✅ Prevent duplicates
  //     _familyMembers.addAll(familyMembers);

  //     _adults.clear(); // ✅ Clear previous data before adding adults again
  //     _adults = familyMembers.where((member) => member["isAdult"] == true).toList();

  //     _familyMembers.removeWhere((m) => m["id"] == userData?["id"]); // prevent duplicate if already added
  //     _adults.removeWhere((m) => m["id"] == userData?["id"]);        // prevent duplicate if already added

  //     // assign all vehicle data to vehicles variables
  //     _vehicles = vehicleData;

  //     if (userData != null) {
  //     // 🔹 Include account owner in _adults for driver selectionZ
  //       _adults.insert(0, {
  //         "id": userData["id"],
  //         "fullName": userData["fullName"],
  //         "email": userData["email"],
  //         "phoneNumber": userData["phoneNumber"],
  //         "isAdult": true,
  //         "driverLicense": userData["driverLicense"] ?? "",
  //         "profilePhoto": userData["profilePhoto"],
  //       });

  //     // 🔹 Include account owner in _familyMembers for participant selection
  //        _familyMembers.add({
  //         "id": userData["id"],
  //         "fullName": userData["fullName"],
  //         "email": userData["email"],
  //         "phoneNumber": userData["phoneNumber"],
  //         "isAdult": true,
  //         "driverLicense": userData["driverLicense"] ?? "",
  //         "profilePhoto": userData["profilePhoto"],
  //       });
  //     }

  //     // 👇 Smart Default: Auto-select the only driver if only one exists
  //     if (_adults.length == 1) {
  //       _selectedDriver = _adults.first["id"];
  //     }

  //     if (_isEditing && _selectedVehicle != null) {
  //       _onVehicleSelected(_selectedVehicle!); // ✅ Ensure vehicle max capacity is set for validation
  //     }
  //   });
  // }

  // ⬅️ Called from initState when editing an existing carpool
  void _preFillFormWithCarpoolData(Map<String, dynamic> data) {
    // 📝 Pre-fill all text controllers
    _carpoolNameController.text = data['carpoolName'] ?? '';
    _routeStartController.text = data['carpoolRouteStart'] ?? '';
    _routeEndController.text = data['carpoolRouteEnd'] ?? '';
    _capacityController.text = (data['carpoolCapacity'] ?? 0).toString();

    // 🚗 Pre-fill dropdown values
    _selectedVehicle = data['carpoolVehicleId'];
    _selectedOwner = data['carpoolOwnerId'];
    _selectedDriver = data['carpoolDriverId'];

    // 👨‍👩‍👧‍👦 Pre-fill list of participant IDs
    // 👨‍👩‍👧‍👦 Pre-fill list of participant IDs (excluding driver)
    _carpoolParticipants = List<String>.from(data['carpoolParticipants'] ?? []);
    _selectedParticipants = _carpoolParticipants
      .where((id) => id != data['carpoolDriverId'])
      .toList(); // ✅ Only non-driver participants go into the checkboxes

    // 🔄 Return trip toggles
    _hasReturnTrip = data['carpoolReturnTrip'] ?? false;
    _stayOnLocation = data['carpoolReturnStayOnLocation'] ?? false;

    // 📅 Parse Timestamp objects into DateTime/TimeOfDay
    Timestamp carpoolDate = data['carpoolDate'];
    Timestamp carpoolTime = data['carpoolTime'];

    _selectedDate = carpoolDate.toDate();
    _selectedTime = TimeOfDay.fromDateTime(carpoolTime.toDate());

    // 🔁 Trigger capacity and vehicle availability logic for the selected vehicle
    if (_selectedVehicle != null) {
      _onVehicleSelected(_selectedVehicle!);
    }
  }

  // 🔄 Called when a vehicle is selected or prefilled to get max seating capacity
  void _onVehicleSelected(String vehicleId) {
    final vehicleData = _vehicles.firstWhere(
      (v) => v['id'] == vehicleId,
      orElse: () => {},
    );

    if (vehicleData.isNotEmpty && vehicleData['seatingCapacity'] != null) {
      _vehicleMaxCapacity = vehicleData['seatingCapacity'];

      // 🧠 If user hasn't entered a capacity yet, set it to vehicle max
      if (_capacityController.text.isEmpty || int.tryParse(_capacityController.text) == null) {
        _capacityController.text = _vehicleMaxCapacity.toString();
      }
    }
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

  /// 📅 Opens a time picker & updates the selected time
  Future<void> _pickTime() async {
    // 🕒 Get the current time
    TimeOfDay now = TimeOfDay.now();

    // 🔄 Round minutes to nearest 15
    int roundedMinutes = (now.minute / 15).round() * 15;

    if (roundedMinutes == 60) {
      // ➕ If 60, roll over to next hour
      now = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
    } else {
      now = TimeOfDay(hour: now.hour, minute: roundedMinutes);
    }

    // 📅 Show the time picker
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: now, // 🧠 Use rounded time here
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });

      // 🔄 Re-fetch vehicles to update availability
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

  /// 🔄 Resets all form fields (used by the Clear button)
  void _resetCarpoolForm() {
    setState(() {
      _carpoolNameController.clear();
      _routeStartController.clear();
      _routeEndController.clear();
      _capacityController.text = "4"; // Default capacity

      _selectedDate = null;
      _selectedTime = null;
      _selectedVehicle = null;
      _selectedDriver = null;
      _vehicleMaxCapacity = null;
      _selectedParticipants.clear();
      _carpoolParticipants.clear();
      _hasReturnTrip = false;
      _stayOnLocation = false;

      if (!_isEditing) {
        _carpoolId = null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Form cleared.")),
    );
  }

  /// Handles form submission for creating a carpool
  void _createCarpool() async {
    if (!_validateCarpoolInputs()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all required fields!")));
      return;
    }

    // 🚫 Check if entered capacity exceeds max vehicle capacity
    if (_vehicleMaxCapacity != null &&
        int.tryParse(_capacityController.text.trim())! > _vehicleMaxCapacity!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Capacity cannot exceed vehicle’s max capacity ($_vehicleMaxCapacity).")),
      );
      return;
    }

    // ✅ Safety net check before creation (even if dropdown disables vehicle)
    // 🔓 Allow vehicle if it's already being used by the carpool being edited
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

    // 🔓 Allow vehicle if it's already being used by the carpool being edited
    if (_isEditing && _selectedVehicle == _editingCarpool?['carpoolVehicleId']) {
      stillAvailable = true;
    }

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

    // 👥 Prepare carpoolParticipants (driver + selected participants)
    List<String> allParticipants = [_selectedDriver!, ..._selectedParticipants.toSet()];

    // 🔍 Participant Count Validation
    int enteredCapacity = int.tryParse(_capacityController.text.trim()) ?? 0;
    int participantCount = _carpoolParticipants.length;

    // Exclude driver from participant list (just in case)
    if (_carpoolParticipants.contains(_selectedDriver)) {
      participantCount -= 1;
    }

    if (participantCount > (enteredCapacity - 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Too many participants selected for the available seats!")),
      );
      return; // ❌ Stop submission
    }

    try {
      if (_isEditing && _carpoolId != null) {
        // 🔄 UPDATE EXISTING CARPOOL
        await _firebaseFunctions.updateCarpool(
          carpoolId: _carpoolId!,
          updatedData: {
            "carpoolName": _carpoolNameController.text.trim(),
            "carpoolRouteStart": _routeStartController.text.trim(),
            "carpoolRouteEnd": _routeEndController.text.trim(),
            "carpoolDate": carpoolDate,
            "carpoolTime": carpoolTime,
            "carpoolVehicleId": _selectedVehicle!,
            "carpoolOwnerId": _selectedOwner!,
            "carpoolDriverId": _selectedDriver!,
            "carpoolParticipants": allParticipants,
            "carpoolCapacity": int.parse(_capacityController.text),
            "carpoolReturnTrip": _hasReturnTrip,
            "carpoolReturnStayOnLocation": _hasReturnTrip ? _stayOnLocation : null,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Carpool '${_carpoolNameController.text.trim()}' updated successfully!")),
        );
      } else {
        // 🆕 CREATE NEW CARPOOL
        await _firebaseFunctions.createCarpool(
          carpoolName: _carpoolNameController.text.trim(),
          carpoolRouteStart: _routeStartController.text.trim(),
          carpoolRouteEnd: _routeEndController.text.trim(),
          carpoolDate: carpoolDate,
          carpoolTime: carpoolTime,
          carpoolVehicleId: _selectedVehicle!,
          carpoolOwnerId: _selectedOwner!,
          carpoolDriverId: _selectedDriver!,
          carpoolParticipants: allParticipants,
          carpoolCapacity: int.parse(_capacityController.text),
          carpoolReturnTrip: _hasReturnTrip,
          carpoolReturnStayOnLocation: _hasReturnTrip ? _stayOnLocation : null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Carpool '${_carpoolNameController.text.trim()}' created successfully!")),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving carpool: $e")));
    }

  }

  
  // /// Generic text field builder
  // Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8),
  //     child: TextField(controller: controller, decoration: InputDecoration(labelText: label), keyboardType: keyboardType),
  //   );
  // }

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
    bool showAvailabilityIcon = false,
    bool showImage = false, // ✅ NEW PARAMETER
    String imageField = '', // ✅ Which image to use
    }
  ) {
    return DropdownButtonFormField(
      value: selectedValue,
      items: items.map((item) {
        bool isDisabled = item['isAvailable'] == false;

        return DropdownMenuItem(
          value: item[idField],
          enabled: !isDisabled,
          child: Row(
            children: [
              if (showImage && item[imageField] != null && item[imageField] != "")
                CircleAvatar(
                  backgroundImage: FileImage(File(item[imageField])),
                  radius: 12,
                ),
              if (showImage) SizedBox(width: 8),
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
      onChanged: (value) => setState(() => onChangedCallback(value as String?)),
      decoration: InputDecoration(labelText: label),
    );
  }

  /// 🧩 Builds a checkbox list tile for each participant
  Widget _buildParticipantCheckbox(Map<String, dynamic> member) {
    final memberId = member['id'];
    final memberName = member['fullName'];

    return CheckboxListTile(
      title: Text(memberName),
      value: _selectedParticipants.contains(memberId),
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            _selectedParticipants.add(memberId);
          } else {
            _selectedParticipants.remove(memberId);
          }
        });
      },
    );
  }


  /// 🔍 Checks if all required form fields are filled
  /// Used to enable/disable the Submit button dynamically
  bool _isFormComplete() {
    return _carpoolNameController.text.isNotEmpty &&         // 📝 Carpool name filled
          _routeStartController.text.isNotEmpty &&          // 🗺️ Start location filled
          _routeEndController.text.isNotEmpty &&            // 📍 End location filled
          _selectedDate != null &&                          // 📅 Date selected
          _selectedTime != null &&                          // ⏰ Time selected
          _selectedVehicle != null &&                       // 🚗 Vehicle selected
          _selectedDriver != null &&                        // 👨‍✈️ Driver selected
          _capacityController.text.isNotEmpty;              // 💺 Capacity entered
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Carpool")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // _buildTextField("Carpool Name", _carpoolNameController),
            // _buildTextField("Start Location", _routeStartController),
            // _buildTextField("End Location", _routeEndController),
            buildTextField(label: "Carpool Name", controller: _carpoolNameController),
            buildTextField(label: "Start Location", controller: _routeStartController),
            buildTextField(label: "End Location", controller: _routeEndController),

            _buildDateTimePicker("Select Date", _selectedDate, _pickDate),
            _buildDateTimePicker("Select Time", _selectedTime, _pickTime),

            // Owner Dropdown
            // TextFormField(
            //   decoration: InputDecoration(labelText: "Carpool Owner"),
            //   initialValue: _adults.firstWhere((a) => a['id'] == _selectedOwner)['fullName'],
            //   enabled: false, // 🔒 Locked
            // ),
            // 🔒 Locked Carpool Owner Field - Always the logged-in account owner
            if (_selectedOwner != null && _loggedInUserData != null)
              ListTile(
                title: Text("Carpool Owner"),
                subtitle: Text(_loggedInUserData?["fullName"] ?? "Unknown"),
                leading: Icon(Icons.lock),
              ),
            // _buildDropdown(
            //   "Carpool Owner",
            //   _selectedOwner,
            //   _adults,
            //   "id",
            //   "fullName",
            //   (value) => _selectedOwner = value, // 🔹 Updates _selectedOwner
            // ),

            // Driver Dropdown
            _buildDropdown(
              "Driver",
              _selectedDriver,
              _adults,
              "id",
              "fullName",
              (value) {
                setState(() {
                  _selectedDriver = value;

                  // ✅ Auto-clear participants when driver changes
                  _selectedParticipants.clear();

                  // ✅ Also ensure participants list doesn't include the new driver
                  _carpoolParticipants.remove(_selectedDriver);
                });
              },
              showImage: true, // ✅ Show driver image
              imageField: "profilePhoto", // ✅ Use profile image field
            ),

            
            // Vehicle Dropdown
            _buildDropdown(
              "Select Vehicle",
              _selectedVehicle,
              _vehicles,
              "id",
              "vehicleMake",
              (value) {
                setState(() {
                  _selectedVehicle = value;
                  _onVehicleSelected(value!);
                });
              },
              showAvailabilityIcon: true,
              showImage: true, // ✅ Show vehicle image
              imageField: "vehicleImage", // ✅ Field to use
            ),

            // 📌 Purpose: Lets user select additional carpool participants from the family
            // 🔄 Loop through family members and build checkboxes
            /// 🔄 Participant Section: Split into Children and Adults for clarity
            if (_selectedDriver != null) ...[
              SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Select Participants", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 10),

              /// 👶 CHILDREN PARTICIPANTS
              if (_familyMembers.any((m) => m['isAdult'] == false && m['id'] != _selectedDriver)) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Children", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                ),
                ..._familyMembers
                    .where((m) => m['isAdult'] == false && m['id'] != _selectedDriver)
                    .map((member) => _buildParticipantCheckbox(member))
                    .toList(),
                SizedBox(height: 10),
              ],

              /// 🧑‍🦱 ADULT PARTICIPANTS
              if (_familyMembers.any((m) => m['isAdult'] == true && m['id'] != _selectedDriver)) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Adults", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                ),
                ..._familyMembers
                    .where((m) => m['isAdult'] == true && m['id'] != _selectedDriver)
                    .map((member) => _buildParticipantCheckbox(member))
                    .toList(),
              ]
            ],

            // Carpool Capacity
            buildTextField(
              label: _vehicleMaxCapacity != null
                  ? "Capacity (Max: $_vehicleMaxCapacity)"
                  : "Capacity",
              controller: _capacityController,
              keyboardType: TextInputType.number,
            ),

            // _buildTextField("Capacity", _capacityController, keyboardType: TextInputType.number),
            // _buildTextField(
            //   _vehicleMaxCapacity != null
            //       ? "Capacity (Max: $_vehicleMaxCapacity)"
            //       : "Capacity",
            //   _capacityController,
            //   keyboardType: TextInputType.number,
            // ),

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
            // ✅ Submit button becomes enabled only when all required fields are filled
            ElevatedButton(
              onPressed: _isFormComplete() ? _createCarpool : null, // 🔒 Disabled if form incomplete
              child: Text(_isEditing ? "Update Carpool" : "Create Carpool"),
            ),

            // 🔘 Reset/Clear Button
            TextButton.icon(
              onPressed: _resetCarpoolForm,
              icon: Icon(Icons.refresh),
              label: Text("Clear Form"),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          ],          
        ),
      ),
    );
  }
}


// --------------------------------------------------

// 📌 Filename: explore_carpools_screen.dart
// 📂 Location: modules\carpool\screens

import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart'; // Firestore interaction logic
import 'package:kccarpoolapp/modules/carpool/widgets/carpool_card.dart'; // Existing reusable carpool UI

/// 🔍 Screen to explore carpools created by other families
/// This screen helps the user find joinable carpools that they do not own or already participate in.
class ExploreCarpoolsScreen extends StatefulWidget {
  @override
  _ExploreCarpoolsScreenState createState() => _ExploreCarpoolsScreenState();
}

class _ExploreCarpoolsScreenState extends State<ExploreCarpoolsScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions(); // Firebase abstraction class

  List<Map<String, dynamic>> _carpools = []; // Holds list of external carpools to display
  bool _isLoading = true; // Tracks whether data is being fetched
  String _currentUserId = ""; // Stores logged-in user's UID

  @override
  void initState() {
    super.initState();
    _loadExploreCarpools(); // Load available carpools wfrequestToJoinCarpoolhen screen loads
  }

  /// 🔍 Loads carpools from other families for the Explore screen.
  /// This function performs the following:
  /// 1. Fetch carpools the user can explore (i.e. not created by their family and not already joined)
  /// 2. Enrich each carpool with required display fields for the CarpoolCard:
  ///    - driverName, driverPhoto
  ///    - vehicleMakeModel, vehicleImage
  ///    - resolvedParticipants (full participant info)
  /// 3. Set the enriched list in state for rendering
  Future<void> _loadExploreCarpools() async {
    // Step 1: Show loading indicator while data is being fetched
    setState(() => _isLoading = true);

    try {
      // Step 2: Get the currently logged-in user's UID
      final String userId = _firebaseFunctions.getCurrentUserId() ?? "";

      // Step 3: Fetch carpools from other families that the user hasn't joined
      final List<Map<String, dynamic>> exploreCarpools =
          await _firebaseFunctions.getExploreCarpools();

      // Step 4: Enrich each carpool with the fields expected by CarpoolCard
      final List<Map<String, dynamic>> enrichedCarpools = [];

      for (final carpool in exploreCarpools) {
        // Get vehicle data from Firestore using carpoolVehicleId
        final vehicleData =
            await _firebaseFunctions.getVehicleById(carpool['carpoolVehicleId']);

        // Get driver user data using carpoolDriverId
        final driverData = await _firebaseFunctions.getDriverById(
          driverId: carpool['carpoolDriverId'],
        );

        // Get list of full participant documents based on carpoolParticipants field
        final resolvedParticipants = await _firebaseFunctions.getCarpoolParticipants(
          carpoolDriverId: carpool['carpoolDriverId'],
          participantIds: List<String>.from(carpool['carpoolParticipants'] ?? []),
        );

        // Flatten the required fields so CarpoolCard works correctly
        carpool['driverName'] = driverData?['fullName'] ?? "Unknown Driver";
        carpool['driverPhoto'] = driverData?['profilePhoto'];
        carpool['vehicleMakeModel'] = vehicleData != null
            ? "${vehicleData['vehicleMake']} ${vehicleData['vehicleModel']}"
            : "Unknown Vehicle";
        carpool['vehicleImage'] = vehicleData?['vehicleImage'];
        carpool['resolvedParticipants'] = resolvedParticipants;

        // Add this enriched carpool to the final list
        enrichedCarpools.add(carpool);
      }

      // Step 5: Save the results to the screen's state to trigger UI rebuild
      setState(() {
        _carpools = enrichedCarpools;
        _currentUserId = userId;
      });
    } catch (e) {
      // Step 6: Handle errors (e.g., permission issues or Firestore failures)
      print("Error loading explore carpools: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load carpools")),
      );
    } finally {
      // Step 7: Stop showing the loading spinner
      setState(() => _isLoading = false);
    }
  }

  /// 🔄 Fetches the current user's family members (excluding self)
  Future<List<Map<String, dynamic>>> _fetchFamilyMembers() async {
    try {
      return await FirebaseFunctions().getFamilyMembersByIds(includePrimaryUser: false);
    } catch (e) {
      print("Error fetching family members: $e");
      return [];
    }
  }



  /// 🚀 Triggered when user taps "Request to Join"
  Future<void> _handleJoinRequest(String carpoolId) async {
    try {
      await _firebaseFunctions.requestToJoinCarpool(carpoolId); // 👈 Calls Firestore function
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Join request sent!")),
      );
      _loadExploreCarpools(); // 🔄 Reload to reflect state change
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send join request.")),
      );
    }
  }

  /// 🛑 Triggered when user taps "Cancel Request"
  Future<void> _handleCancelRequest(String carpoolId) async {
    try {
      await _firebaseFunctions.cancelJoinRequest(carpoolId); // 🔧 (to be implemented later)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request cancelled.")),
      );
      _loadExploreCarpools(); // 🔄 Reload
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to cancel request.")),
      );
    }
  }

  /// 🔁 Builds dynamic button based on whether the user has requested to join already
  Widget _buildActionButton(Map<String, dynamic> carpool) {
    final List<dynamic> requestedUsers = carpool['requestedUserIds'] ?? [];

    final bool alreadyRequested = requestedUsers.contains(_currentUserId);

    return ElevatedButton.icon(
      icon: Icon(alreadyRequested ? Icons.cancel : Icons.group_add),
      label: Text(alreadyRequested ? "Cancel Request" : "Request to Join"),
      onPressed: () {
        alreadyRequested
            ? _handleCancelRequest(carpool['carpoolId'])
            : _handleJoinRequest(carpool['carpoolId']);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Explore Carpools")),

      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // 🌀 Loading Spinner
          : _carpools.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text("No Carpools Available", style: TextStyle(fontSize: 20)),
                      SizedBox(height: 8),
                      Text("Try again later or adjust your filters."),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadExploreCarpools, // 🔁 Pull to refresh support
                  child: ListView.builder(
                    itemCount: _carpools.length,
                    itemBuilder: (context, index) {
                      final carpool = _carpools[index];

                      return Column(
                        children: [
                          CarpoolCard(
                            carpool: carpool,
                            onDelete: (_) {}, // 🔒 No delete allowed in Explore screen
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildActionButton(carpool), // 🎯 Main "Join/Cancel" button
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}


// --------------------------------------------------

// 📌 Filename: join_requests_screen.dart
// 📂 Location: modules\carpool\screens

import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart'; // Your Firestore abstraction
import 'package:kccarpoolapp/core/routes.dart'; // For navigation

/// 📥 Screen to show all incoming join requests for carpools owned by the current user.
class JoinRequestsScreen extends StatefulWidget {
  @override
  _JoinRequestsScreenState createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();

  List<Map<String, dynamic>> _carpoolsWithRequests = []; // Each map contains carpool data + requesters
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJoinRequests(); // Fetch data when the screen loads
  }

  /// 🔄 Loads all join requests for carpools owned by the current user
  Future<void> _loadJoinRequests() async {
    setState(() => _isLoading = true);

    try {
      final List<Map<String, dynamic>> results = await _firebaseFunctions.getJoinRequestsForOwner();

      setState(() {
        _carpoolsWithRequests = results;
      });
    } catch (e) {
      print("Failed to load join requests: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading join requests")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📦 Approves a join request
  Future<void> _approveRequest(String carpoolId, String userId) async {
    try {
      await _firebaseFunctions.approveJoinRequest(carpoolId, userId);
      _loadJoinRequests(); // Refresh
    } catch (e) {
      final message = e.toString().contains("full")
          ? "This carpool is already at full capacity."
          : "Failed to approve request.";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// 🛑 Denies a join request
  Future<void> _denyRequest(String carpoolId, String userId) async {
    try {
      await _firebaseFunctions.denyJoinRequest(carpoolId, userId);
      _loadJoinRequests(); // Refresh the list
    } catch (e) {
      print("Denial failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to deny request")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Join Requests")),

      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _carpoolsWithRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text("No Join Requests", style: TextStyle(fontSize: 20)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadJoinRequests,
                  child: ListView.builder(
                    itemCount: _carpoolsWithRequests.length,
                    itemBuilder: (context, index) {
                      final carpool = _carpoolsWithRequests[index];
                      final List<dynamic> requesters = carpool['joinRequestUsers'] ?? [];

                      return Card(
                        margin: EdgeInsets.all(12),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🚌 Carpool name
                              Text(
                                carpool['carpoolName'] ?? "Unnamed Carpool",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 12),

                              // 🔁 Loop over all requesters for this carpool
                              ...requesters.map((user) => ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: user['profilePhoto'] != null
                                          ? NetworkImage(user['profilePhoto'])
                                          : null,
                                      child: user['profilePhoto'] == null
                                          ? Icon(Icons.person)
                                          : null,
                                    ),
                                    title: Text(user['fullName']),
                                    subtitle: Text("Relation: ${user['relationToChild']}"),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.check, color: Colors.green),
                                          onPressed: () => _approveRequest(
                                              carpool['carpoolId'], user['userId']),
                                          tooltip: "Approve",
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.close, color: Colors.red),
                                          onPressed: () => _denyRequest(
                                              carpool['carpoolId'], user['userId']),
                                          tooltip: "Deny",
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}


// --------------------------------------------------

// 📌 Filename: carpool_card.dart
// 📂 Location: modules\carpool\widgets

// 📌 Filename: carpool_card.dart
// 📂 Location: lib/modules/carpool/widgets

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kccarpoolapp/core/routes.dart';

/// 🔹 CarpoolCard displays one carpool item in the list.
/// It receives carpool data and handles navigation/edit/delete logic.
class CarpoolCard extends StatelessWidget {
  final Map<String, dynamic> carpool;
  final Function(String carpoolId) onDelete;

  const CarpoolCard({
    Key? key,
    required this.carpool,
    required this.onDelete,
  }) : super(key: key);

  /// 🔹 Displays avatars & names of participants (excluding driver)
  Widget _buildParticipantAvatars(List<Map<String, dynamic>> participants) {
    if (participants.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        children: [
          Icon(Icons.group, size: 20, color: Colors.grey[700]),
          SizedBox(width: 8),
          ...participants.map((p) {
            String name = p['fullName'] ?? 'Unknown';
            String? photo = p['profilePhoto'];

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: photo != null && photo.isNotEmpty
                        ? FileImage(File(photo))
                        : null,
                    child: (photo == null || photo.isEmpty)
                        ? Icon(Icons.person, size: 16)
                        : null,
                  ),
                  SizedBox(height: 2),
                  Text(
                    name.split(' ').first,
                    style: TextStyle(fontSize: 10),
                  )
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime carpoolDate = (carpool['carpoolDate'] as Timestamp).toDate();
    DateTime carpoolTime = (carpool['carpoolTime'] as Timestamp).toDate();

    String formattedDateTime = DateFormat('E, dd MMM • h:mm a').format(
      DateTime(
        carpoolDate.year,
        carpoolDate.month,
        carpoolDate.day,
        carpoolTime.hour,
        carpoolTime.minute,
      ),
    );

    final int capacity = carpool['carpoolCapacity'] ?? 0;
    final List<dynamic> participants = carpool['carpoolParticipants'] ?? [];
    final int availableSeats = capacity - participants.length;
    final String status = availableSeats == 0 ? "Full" : "Available";
    final Color statusColor = status == "Full" ? Colors.red : Colors.green;

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Carpool Title + Return Tag + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(carpool['carpoolName'],
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (carpool['carpoolReturnTrip'] == true)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text("↩ Return Trip",
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor)),
                ),
              ],
            ),

            SizedBox(height: 8),

            // 🔹 Route Info
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: Colors.green),
                SizedBox(width: 6),
                Text(carpool['carpoolRouteStart'] ?? "", style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 16, color: Colors.black54),
                SizedBox(width: 6),
                Text(carpool['carpoolRouteEnd'] ?? "", style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(width: 6),
                Icon(Icons.flag, size: 14, color: Colors.red),
              ],
            ),

            // 🔹 Driver Info
            Row(
              children: [
                carpool['driverPhoto'] != null
                    ? CircleAvatar(
                        backgroundImage: FileImage(File(carpool['driverPhoto'])),
                        radius: 14,
                      )
                    : Icon(Icons.person, size: 20),
                SizedBox(width: 6),
                Text("Driver: ${carpool['driverName']}", style: TextStyle(fontSize: 14)),
              ],
            ),

            // 🔹 Participants
            if (carpool.containsKey('resolvedParticipants'))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Participants:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  _buildParticipantAvatars(List<Map<String, dynamic>>.from(carpool['resolvedParticipants'])),
                ],
              ),

            // 🔹 Date & Time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
                SizedBox(width: 4),
                Text(formattedDateTime, style: TextStyle(fontSize: 14)),
              ],
            ),

            // 🔹 Vehicle Info + Seats + Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    carpool['vehicleImage'] != null
                        ? Image.file(
                            File(carpool['vehicleImage']),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.directions_car, size: 30, color: Colors.blue),
                    SizedBox(width: 6),
                    Text(carpool['vehicleMakeModel']),
                  ],
                ),
                Row(
                  children: [
                    Text("Seats: $availableSeats/$capacity", style: TextStyle(fontSize: 14)),
                    SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.orange),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.createCarpool,
                          arguments: {"carpoolData": carpool},
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        bool confirmed = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text("Confirm Deletion"),
                            content: Text("Are you sure you want to delete this carpool?"),
                            actions: [
                              TextButton(
                                child: Text("Cancel"),
                                onPressed: () => Navigator.of(context).pop(false),
                              ),
                              ElevatedButton(
                                child: Text("Delete"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.of(context).pop(true),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          onDelete(carpool['carpoolId']);
                        }
                      },
                    )
                  ],
                ),
              ],
            ),
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
              ////////////////////////////
              // Create Carpool Button //
              ///////////////////////////
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.createCarpool);
                },
                icon: Icon(Icons.add_circle_outline),
                label: Text("Create Carpool"),
              ),

              /////////////////////////
              // My Carpools Screen //
              ////////////////////////
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.carpoolList);
                },
                icon: Icon(Icons.list),
                label: Text("My Carpools"),
              ),

              ////////////////////////////////////
              // Join Request Management Screen //
              ////////////////////////////////////
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.joinRequests);
                },
                icon: Icon(Icons.mark_email_unread_outlined),
                label: Text("Join Requests"),
              ),


              /////////////////////////////
              // Explore Carpools Screen //
              /////////////////////////////
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.exploreCarpools),
                icon: Icon(Icons.travel_explore),
                label: Text("Explore Carpools"),
              ),
            ],
          ),
        ),
      ),
    );
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
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for handling Firestore Timestamp
import 'package:kccarpoolapp/utils/ui_helpers.dart'; // 📁 For picking files


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

  // /// Opens a file picker and saves the selected file locally
  // Future<void> _pickFile(String fileType) async {
  //   String? savedPath = await _firebaseFunctions.saveFileLocally(fileType);
  //   if (savedPath != null) {
  //     setState(() {
  //       if (fileType == "profilePhoto") _profilePhoto = savedPath;
  //       if (fileType == "govId") _govId = savedPath;
  //       if (fileType == "driverLicense") _driverLicense = savedPath;
  //       if (fileType == "schoolId") _schoolId = savedPath;
  //     });
  //   }
  // }

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
      await _firebaseFunctions.updateFamilyMemberInUsers(
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
      await _firebaseFunctions.addFamilyMemberToUsers(
        fullName: _nameController.text.trim(),
        isAdult: _isAdult,
        relationToChild: _isAdult ? (_relationToChild ?? "") : "",
        profilePhotoPath: _profilePhoto!,
        govIdPath: _govId!,
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        emailVerified: false,                              // Placeholder
        phoneVerified: false,                              // Placeholder
        driverLicensePath: _isAdult ? _driverLicense : null,
        address: _addressController.text.trim(),

        // Child fields (only used if !isAdult)
        dateOfBirth: !_isAdult ? _dateOfBirthController.text.trim() : null,
        gender: !_isAdult ? _gender : null,
        grade: !_isAdult ? _gradeController.text.trim() : null,
        schoolName: !_isAdult ? _schoolNameController.text.trim() : null,
        schoolIdNo: !_isAdult ? _schoolIdNoController.text.trim() : null,
        schoolIdImagePath: !_isAdult ? _schoolId : null,
      );
//   await _firebaseFunctions.addFamilyMember(
      //   fullName: _nameController.text.trim(),
      //   email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      //   phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      //   isAdult: _isAdult,
      //   dateOfBirth: _isAdult ? null : _selectedDateOfBirth, // 🔹 Store as timestamp in Firestore
      //   // dateOfBirth: _isAdult ? null : _dateOfBirthController.text.trim(),
      //   profilePhoto: _profilePhoto!,
      //   govId: _govId!,
      //   schoolId: _isAdult ? null : _schoolId ?? "",
      //   schoolName: _isAdult ? null : _schoolNameController.text.trim(),
      //   schoolIdNo: _isAdult ? null : _schoolIdNoController.text.trim(),
      //   grade: _isAdult ? null : _gradeController.text.trim(),
      //   driverLicense: _isAdult ? _driverLicense ?? "" : null,
      //   address: _addressController.text.trim(),
      //   gender: _isAdult ? null : (_gender ?? ""),
      //   // relationToChild: _isAdult ? _relationToChild! : null, // 🔹 Removed for Children
      //   relationToChild: _isAdult ? _relationToChild! : null, // 🔹 Removed for Children
      // );
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
            // _buildTextField("Full Name", _nameController),
            // _buildTextField("Email (Optional)", _emailController),
            // _buildTextField("Phone Number (Optional)", _phoneController),
            buildTextField(label: "Full Name", controller: _nameController, enabled: true),
            buildTextField(label: "Email (Optional)", controller: _emailController, enabled: true),
            buildTextField(label: "Phone Number (Optional)", controller: _phoneController, enabled: true),


            /// Fields only for Child
            if (!_isAdult) ...[
              _buildDatePickerField("Date of Birth", _dateOfBirthController, _pickDateOfBirth),
              buildTextField(label: "School Name", controller: _schoolNameController, enabled: true),
              buildTextField(label: "School ID No.", controller: _schoolIdNoController, enabled: true),
              buildTextField(label: "Grade", controller: _gradeController, enabled: true),
              // _buildTextField("Date of Birth", _dateOfBirthController),
              // _buildTextField("School Name", _schoolNameController),
              // _buildTextField("School ID No.", _schoolIdNoController),
              // _buildTextField("Grade", _gradeController),

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
            // _buildFileUploadSection("Profile Photo", _profilePhoto, "profilePhoto"),
            buildFileUploadSection(
              context: context,
              label: "Profile Photo",
              fileType: "profilePhoto",
              currentPath: _profilePhoto,
              firebaseFunctions: _firebaseFunctions,
              onFilePicked: (path) => setState(() => _profilePhoto = path),
            ),

            /// Government ID Upload
            // _buildFileUploadSection("Government ID", _govId, "govId"),
            buildFileUploadSection(
              context: context,
              label: "Government ID",
              fileType: "govId",
              currentPath: _govId,
              firebaseFunctions: _firebaseFunctions,
              onFilePicked: (path) => setState(() => _govId = path),
            ),

            /// Driver's License Upload (Only for Adults)
            // if (_isAdult) _buildFileUploadSection("Driver License (Optional)", _driverLicense, "driverLicense"),
            if (_isAdult)
              buildFileUploadSection(
                context: context,
                label: "Driver License (Optional)",
                fileType: "driverLicense",
                currentPath: _driverLicense,
                firebaseFunctions: _firebaseFunctions,
                onFilePicked: (path) => setState(() => _driverLicense = path),
              ),

            /// School ID Upload (Only for Children)
            // if (!_isAdult) _buildFileUploadSection("School ID", _schoolId, "schoolId"),
            if (!_isAdult)
              buildFileUploadSection(
                context: context,
                label: "School ID",
                fileType: "schoolId",
                currentPath: _schoolId,
                firebaseFunctions: _firebaseFunctions,
                onFilePicked: (path) => setState(() => _schoolId = path),
              ),


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

  // /// Builds a text field
  // Widget _buildTextField(String label, TextEditingController controller) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8),
  //     child: TextField(
  //       controller: controller,
  //       decoration: InputDecoration(labelText: label),
  //     ),
  //   );
  // }

//   // /// Builds a file upload button
//   Widget _buildFileUploadSection(String label, String? filePath, String fileType) {
//   return ListTile(
//     title: Text(label),
//     subtitle: filePath != null ? Text("Uploaded") : Text("Not uploaded"),
//     trailing: ElevatedButton(
//       onPressed: () async {
//         // 1. Pick a file using the FileUtils helper
//         String? pickedPath = await FileUtils.pickFile(
//           allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
//         );

//         if (pickedPath != null) {
//           // 2. Save the picked file locally using existing FirebaseFunctions method
//           String? savedPath = await _firebaseFunctions.saveFileLocally(fileType, pickedPath);

//           if (savedPath != null) {
//             // 3. Update the correct state variable based on fileType
//             setState(() {
//               if (fileType == "profilePhoto") _profilePhoto = savedPath;
//               if (fileType == "govId") _govId = savedPath;
//               if (fileType == "driverLicense") _driverLicense = savedPath;
//               if (fileType == "schoolId") _schoolId = savedPath;
//             });
//           }
//         }
//       },
//       child: Text(filePath != null ? "Replace" : "Upload"),
//     ),
//   );
// }


  // Widget _buildFileUploadSection(String label, String? filePath, String fileType) {
  //   return ListTile(
  //     title: Text(label),
  //     subtitle: filePath != null ? Text("Uploaded") : Text("Not uploaded"),
  //     trailing: ElevatedButton(
  //       onPressed: () => _pickFile(fileType),
  //       child: Text(filePath != null ? "Replace" : "Upload"),
  //     ),
  //   );
  // }

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
import 'package:kccarpoolapp/utils/ui_helpers.dart'; // 📁 For picking files

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
  final TextEditingController _makeController = TextEditingController(text: 'Maruti');
  final TextEditingController _modelController = TextEditingController(text: 'Swift');
  final TextEditingController _yearController = TextEditingController(text: '2010');
  final TextEditingController _colorController = TextEditingController(text: 'White');
  final TextEditingController _licenseNumberController = TextEditingController(text: '1234');
  final TextEditingController _registrationNumberController = TextEditingController(text: '12345');
  final TextEditingController _seatingCapacityController = TextEditingController(text: '5');

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

  // /// Opens file picker and saves selected file locally
  // Future<void> _pickFile(String fileType) async {
  //   String? savedPath = await _firebaseFunctions.saveFileLocally(fileType);
  //   if (savedPath != null) {
  //     setState(() {
  //       if (fileType == "vehicleImage") _vehicleImage = savedPath;
  //       if (fileType == "registrationDocument") _registrationDocument = savedPath;
  //        if (fileType == "licensePlateImage") _licensePlateImage = savedPath; // ✅ New field
  //     });
  //   }
  // }

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

  // /// Builds a text field
  // Widget _buildTextField(String label, TextEditingController controller) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8),
  //     child: TextField(
  //       controller: controller,
  //       decoration: InputDecoration(labelText: label),
  //       keyboardType: label.contains("Year") || label.contains("Capacity") ? TextInputType.number : TextInputType.text,
  //     ),
  //   );
  // }

  // /// Builds a file upload button
  // Widget _buildFileUploadSection(String label, String? filePath, String fileType) {
  //   return ListTile(
  //     title: Text(label),
  //     subtitle: filePath != null ? Text("Uploaded") : Text("Not uploaded"),
  //     trailing: ElevatedButton(
  //       onPressed: () async {
  //         // Step 1: Let user pick a file using shared utility
  //         String? pickedPath = await FileUtils.pickFile(
  //           allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
  //         );

  //         if (pickedPath != null) {
  //           // Step 2: Save the file locally
  //           String? savedPath = await _firebaseFunctions.saveFileLocally(fileType, pickedPath);

  //           if (savedPath != null) {
  //             // Step 3: Update the correct state variable
  //             setState(() {
  //               if (fileType == "vehicleImage") _vehicleImage = savedPath;
  //               if (fileType == "registrationDocument") _registrationDocument = savedPath;
  //               if (fileType == "licensePlateImage") _licensePlateImage = savedPath;
  //             });
  //           }
  //         }
  //       },
  //       child: Text(filePath != null ? "Replace" : "Upload"),
  //     ),
  //   );
  // }

  
  // Widget _buildFileUploadSection(String label, String? filePath, String fileType) {
  //   return ListTile(
  //     title: Text(label),
  //     subtitle: filePath != null ? Text("Uploaded") : Text("Not uploaded"),
  //     trailing: ElevatedButton(
  //       onPressed: () => _pickFile(fileType),
  //       child: Text(filePath != null ? "Replace" : "Upload"),
  //     ),
  //   );
  // }

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
            // _buildTextField("Vehicle Make", _makeController),
            // _buildTextField("Vehicle Model", _modelController),
            // _buildTextField("Vehicle Year", _yearController),
            // _buildTextField("Vehicle Color", _colorController),
            // _buildTextField("License Number", _licenseNumberController),
            // _buildTextField("Registration Number", _registrationNumberController),
            // _buildTextField("Seating Capacity", _seatingCapacityController),
            buildTextField(label: "Vehicle Make", controller: _makeController),
            buildTextField(label: "Vehicle Model", controller: _modelController),
            buildTextField(label: "Vehicle Year", controller: _yearController),
            buildTextField(label: "Vehicle Color", controller: _colorController),
            buildTextField(label: "License Number", controller: _licenseNumberController),
            buildTextField(label: "Registration Number", controller: _registrationNumberController),
            buildTextField(
              label: "Seating Capacity",
              controller: _seatingCapacityController,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),

            /// Vehicle Image Upload
            // _buildFileUploadSection("Vehicle Image", _vehicleImage, "vehicleImage"),
            buildFileUploadSection(
              context: context,
              label: "Vehicle Image",
              fileType: "vehicleImage",
              currentPath: _vehicleImage,
              firebaseFunctions: _firebaseFunctions,
              onFilePicked: (path) => setState(() => _vehicleImage = path),
            ),

            /// Registration Document Upload
            // _buildFileUploadSection("Registration Document", _registrationDocument, "registrationDocument"),
            buildFileUploadSection(
              context: context,
              label: "Registration Document",
              fileType: "registrationDocument",
              currentPath: _registrationDocument,
              firebaseFunctions: _firebaseFunctions,
              onFilePicked: (path) => setState(() => _registrationDocument = path),
            ),

            // License Plate Image Upload (Mandatory)
            // _buildFileUploadSection("License Plate Image", _licensePlateImage, "licensePlateImage"),
            buildFileUploadSection(
              context: context,
              label: "License Plate Image",
              fileType: "licensePlateImage",
              currentPath: _licensePlateImage,
              firebaseFunctions: _firebaseFunctions,
              onFilePicked: (path) => setState(() => _licensePlateImage = path),
            ),
            
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
import 'package:kccarpoolapp/utils/ui_helpers.dart'; // File upload + UI helpers


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

  // /// Opens a file picker and saves the selected file locally
  // Future<void> _pickFile(String fileType) async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom, // Allows selection of specific file types
  //     allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], // Supported file types
  //   );

  //   if (result != null) {
  //     // Save the file locally
  //     String? savedPath = await _firebaseFunctions.saveFileLocally(fileType);
  //     if (savedPath != null) {
  //       setState(() {
  //         if (fileType == "profilePhoto") _profilePhoto = savedPath;
  //         if (fileType == "govId") _govId = savedPath;
  //         if (fileType == "driverLicense") _driverLicense = savedPath;
  //       });
  //     }
  //   }
  // }

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
  /// Loads family members using flat user model & families/{familyId}/memberUserIds
  Future<void> _loadFamilyMembers() async {
    List<Map<String, dynamic>> familyData =
        await _firebaseFunctions.getFamilyMembersByIds(includePrimaryUser: false); // 🔄 New flat model

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
      try {
        await _firebaseFunctions.deleteFamilyMemberFromUsers(memberId);
        await _loadFamilyMembers(); // Refresh list after deletion
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Family member deleted.")));
      } catch (e) {
        print("Error deleting family member: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting family member.")));
      }
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
    List<Map<String, dynamic>> vehicleData = await _firebaseFunctions.getFamilyVehicles();

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
              // onTap: () => _pickFile("profilePhoto"),
              onTap: () => handleFileUpload(
                context: context,
                fileType: "profilePhoto",
                firebaseFunctions: _firebaseFunctions,
                onFilePicked: (path) => setState(() => _profilePhoto = path),
                allowedExtensions: ['jpg', 'jpeg', 'png'],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profilePhoto != null ? FileImage(File(_profilePhoto!)) : null,
                child: _profilePhoto == null ? Icon(Icons.person, size: 50) : null,
              ),
            ),
            SizedBox(height: 20),

            /// Editable Text Fields
            // _buildTextField("Full Name", _nameController, _isEditing),
            // _buildTextField("Email", _emailController, false),
            // _buildTextField("Phone Number", _phoneController, _isEditing),
            // _buildTextField("Address", _addressController, _isEditing),
            buildTextField(label: "Full Name", controller: _nameController, enabled: _isEditing),
            buildTextField(label: "Email", controller: _emailController, enabled: false),
            buildTextField(label: "Phone Number", controller: _phoneController, enabled: _isEditing),
            buildTextField(label: "Address", controller: _addressController, enabled: _isEditing),

            /// File Upload Sections
            // _buildFileUploadSection("Government ID", _govId, "govId"),
            // _buildFileUploadSection("Driver License (Optional)", _driverLicense, "driverLicense"),
            buildFileUploadSection(
              context: context,
              label: "Government ID",
              fileType: "govId",
              currentPath: _govId,
              firebaseFunctions: _firebaseFunctions,
              onFilePicked: (path) => setState(() => _govId = path),
            ),

            buildFileUploadSection(
              context: context,
              label: "Driver License (Optional)",
              fileType: "driverLicense",
              currentPath: _driverLicense,
              firebaseFunctions: _firebaseFunctions,
              onFilePicked: (path) => setState(() => _driverLicense = path),
            ),

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
}
  // /// Builds a text field with optional editing capability
  // Widget _buildTextField(String label, TextEditingController controller, bool isEditable) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8),
  //     child: TextField(
  //       controller: controller,
  //       enabled: isEditable,
  //       decoration: InputDecoration(labelText: label),
  //     ),
  //   );
  // }

  // /// Builds a section for file uploads
  // Widget _buildFileUploadSection(String label, String? filePath, String fileType) {
  //   return ListTile(
  //     title: Text(label),
  //     subtitle: filePath != null ? Text("Uploaded") : Text("Not uploaded"),
  //     trailing: ElevatedButton(
  //       onPressed: () async {
  //         // 1. Let user pick a file
  //         String? pickedPath = await FileUtils.pickFile(
  //           allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
  //         );

  //         if (pickedPath != null) {
  //           // 2. Save it locally (your existing logic)
  //           String? savedPath = await _firebaseFunctions.saveFileLocally(fileType, pickedPath);

  //           if (savedPath != null) {
  //             setState(() {
  //               if (fileType == "profilePhoto") _profilePhoto = savedPath;
  //               if (fileType == "govId") _govId = savedPath;
  //               if (fileType == "driverLicense") _driverLicense = savedPath;
  //             });
  //           }
  //         }
  //       },
  //       child: Text(filePath != null ? "Replace" : "Upload"),
  //     ),
  //   );
  // }


  // Widget _buildFileUploadSection(String label, String? filePath, String fileType) {
  //   return ListTile(
  //     title: Text(label),
  //     subtitle: filePath != null ? Text("Uploaded") : Text("Not uploaded"),
  //     trailing: ElevatedButton(
  //       onPressed: () => _pickFile(fileType),
  //       child: Text(filePath != null ? "Replace" : "Upload"),
  //     ),
  //   );
  // }

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
  /// Save a file that was already picked using FileUtils
  Future<String?> saveFileLocally(String fileType, String pickedFilePath) async {
    try {
      Directory? appDocDir = await getExternalStorageDirectory();
      if (appDocDir == null) {
        print("Failed to get external storage directory.");
        return null;
      }

      String localPath = '${appDocDir.path}/$fileType';
      await Directory(localPath).create(recursive: true);

      File file = File(pickedFilePath);
      String newFilePath = '$localPath/${file.uri.pathSegments.last}';
      await file.copy(newFilePath);

      print("File saved publicly at: $newFilePath");
      return newFilePath;
    } catch (e) {
      print("Error saving file locally: $e");
      return null;
    }
  }

  /// Saves user verification data in Firestore
  /// Saves verification data for the account owner (primary user),
  /// creates a new 'users' document, and initializes the 'families' collection.
  /// This is called after registration and identity verification.
  Future<void> saveVerificationData({
    required String profilePhoto,       // Local path to profile photo
    required String govId,              // Local path to government ID
    required String? driverLicense,     // Optional local path to driver’s license
    required String address,
    required String relationToChild,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;

    final String userId = auth.currentUser!.uid;

    // ✅ STEP 1: Create a new document in the 'families' collection.
    // This family document represents the user's household and will later hold more members.
    final DocumentReference familyDoc = await firestore.collection('families').add({
      'primaryUserId': userId,             // The account owner (admin of the family)
      'memberUserIds': [userId],           // Start with just the owner; others will be added later
      'createdAt': Timestamp.now(),        // Metadata
    });

    final String familyId = familyDoc.id; // We’ll use this to link the user to their family

    // ✅ STEP 2: Prepare the user's Firestore data with all fields
    final Map<String, dynamic> userData = {
      // 'fullName': auth.currentUser?.displayName ?? '',
      'email': auth.currentUser?.email ?? '',
      // 'phoneNumber': auth.currentUser?.phoneNumber ?? '',
      'address': address.trim(),
      'relationToChild': relationToChild,
      'profilePhoto': profilePhoto,         // Stored as local file path
      'govId': govId,                       // Local file path
      'driverLicense': driverLicense ?? '', // Optional local file path
      'emailVerified': false,                // Assume true if OTP verified
      'phoneVerified': false,                // Assume true if OTP verified
      'timestamp': Timestamp.now(),

      // 🔥 NEW STRUCTURE FIELDS
      'isPrimaryUser': true,                // Marks this as the family account owner
      'isAdult': true,                      // All account owners are adults
      'familyId': familyId,                 // Links this user to their family group
    };

    // ✅ STEP 3: Save the user to 'users/{uid}' in Firestore
    await firestore.collection('users').doc(userId).set(
      userData,
      SetOptions(merge: true), // Keep any previously stored values
    );

    print('✅ User and family records created successfully.');
  }

  /// Adds a new family member to the global 'users' collection (flat structure).
  /// This replaces the older 'users/{uid}/family' subcollection method.
  /// It supports both adults and children, and uses the current user's familyId.
  Future<void> addFamilyMemberToUsers({
    required String fullName,
    required bool isAdult,
    required String relationToChild,
    required String address,
    required String profilePhotoPath,
    required String govIdPath,
    String? email,
    String? phoneNumber,
    bool emailVerified = false,
    bool phoneVerified = false,
    String? driverLicensePath, // Optional - for adults only

    // Fields specific to children
    String? dateOfBirth,
    String? gender,
    String? grade,
    String? schoolName,
    String? schoolIdNo,
    String? schoolIdImagePath,
  }) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final String accountOwnerId = auth.currentUser!.uid;

    // 1️⃣ Get the current user's document to access their familyId
    final DocumentSnapshot userSnapshot =
        await firestore.collection("users").doc(accountOwnerId).get();

    if (!userSnapshot.exists) {
      throw Exception("User document does not exist.");
    }

    // ✅ Safely cast the snapshot's data to a Map so we can check keys
    final userData = userSnapshot.data() as Map<String, dynamic>;

    if (!userData.containsKey("familyId")) {
      throw Exception("Missing familyId in user document.");
    }

    final String familyId = userData["familyId"];

    // 2️⃣ Prepare base data common to all family members
    Map<String, dynamic> memberData = {
      "fullName": fullName,
      "email": email ?? '',
      "phoneNumber": phoneNumber ?? '',
      "emailVerified": emailVerified,
      "phoneVerified": phoneVerified,
      "isAdult": isAdult,
      "isPrimaryUser": false,              // All added family members are not the account owner
      "familyId": familyId,                // Same family as the account owner
      "createdBy": accountOwnerId,         // Who added this member
      "relationToChild": relationToChild,
      "address": address,
      "profilePhoto": profilePhotoPath,
      "govId": govIdPath,
      "driverLicense": driverLicensePath ?? '',
      "timestamp": Timestamp.now(),
    };

    // 3️⃣ Add child-specific fields if the member is a child
    if (!isAdult) {
      memberData.addAll({
        "dateOfBirth": (dateOfBirth != null && dateOfBirth.isNotEmpty)
          ? Timestamp.fromDate(DateTime.parse(dateOfBirth))
          : null,
        "gender": gender ?? '',
        "grade": grade ?? '',
        "schoolName": schoolName ?? '',
        "schoolIdNo": schoolIdNo ?? '',
        "schoolId": schoolIdImagePath ?? '',
      });
    }

    // await firestore.collection("users").add(memberData);
    // 4️⃣ Add the member to the top-level 'users' collection
    final DocumentReference memberRef =
    await firestore.collection("users").add(memberData);

    final String newMemberId = memberRef.id;

    // Append this member ID to the family's memberUserIds list
    await firestore.collection("families").doc(familyId).update({
      "memberUserIds": FieldValue.arrayUnion([newMemberId])
    });

    print('✅ Family member added to users collection (flat model).');
  }

  /// Fetches family members using the 'memberUserIds' array in families/{familyId}.
  /// If [includePrimaryUser] is false, the account owner will be excluded.
  Future<List<Map<String, dynamic>>> getFamilyMembersByIds({bool includePrimaryUser = true}) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final String uid = auth.currentUser!.uid;

    // 1️⃣ Get the current user's document to retrieve familyId
    final DocumentSnapshot userDoc =
        await firestore.collection("users").doc(uid).get();

    if (!userDoc.exists) {
      throw Exception("User document not found.");
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final String familyId = userData["familyId"];

    // 2️⃣ Get the family's memberUserIds list
    final DocumentSnapshot familyDoc =
        await firestore.collection("families").doc(familyId).get();

    if (!familyDoc.exists) {
      throw Exception("Family document not found.");
    }

    final familyData = familyDoc.data() as Map<String, dynamic>;
    final List<dynamic> memberIds = familyData["memberUserIds"] ?? [];

    List<Map<String, dynamic>> familyMembers = [];

    for (String memberId in memberIds) {
      final DocumentSnapshot memberDoc =
          await firestore.collection("users").doc(memberId).get();

      if (memberDoc.exists) {
        final data = memberDoc.data() as Map<String, dynamic>;
        data['id'] = memberDoc.id;

        // 🔹 Exclude primary user if requested
        if (!includePrimaryUser && data["isPrimaryUser"] == true) {
          continue;
        }

        familyMembers.add(data);
      }
    }

    return familyMembers;
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

  /// Deletes a family member from Firestore.
  ///
  /// This function removes the user document from the top-level `users` collection
  /// and also removes their UID from the `memberUserIds` array in the corresponding
  /// family document.
  Future<void> deleteFamilyMemberFromUsers(String memberId) async {
    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(memberId);
      final userSnapshot = await userDocRef.get();

      if (!userSnapshot.exists) {
        throw Exception("User not found with ID: $memberId");
      }

      final userData = userSnapshot.data();
      if (userData == null || !userData.containsKey('familyId')) {
        throw Exception("Family ID not found for user: $memberId");
      }

      final String familyId = userData['familyId'];
      final familyDocRef = FirebaseFirestore.instance.collection('families').doc(familyId);

      // ✅ Start a batch operation to ensure atomicity
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Delete the user document
      batch.delete(userDocRef);

      // 2. Remove their ID from the `memberUserIds` array in the corresponding family document
      batch.update(familyDocRef, {
        'memberUserIds': FieldValue.arrayRemove([memberId])
      });

      // ✅ Commit the batch
      await batch.commit();
    } catch (e) {
      print("Error deleting family member: $e");
      rethrow;
    }
  }

  /// Updates an existing family member (flat model under /users collection)
  Future<void> updateFamilyMemberInUsers({
    required String memberId,
    required String fullName,
    String? email,
    String? phoneNumber,
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
    final docRef = _firestore.collection('users').doc(memberId);

    final Map<String, dynamic> data = {
      'fullName': fullName,
      'email': email ?? "",
      'phoneNumber': phoneNumber ?? "",
      'emailVerified': false,  // Placeholder for future verification
      'phoneVerified': false,
      'isAdult': isAdult,
      'address': address,
      'profilePhoto': profilePhoto,
      'govId': govId,
      'driverLicense': driverLicense ?? "",
      'relationToChild': isAdult ? relationToChild ?? "" : "",
      'gender': isAdult ? null : gender ?? "",
      'dateOfBirth': isAdult ? null : Timestamp.fromDate(dateOfBirth!),
      'schoolId': isAdult ? null : schoolId ?? "",
      'schoolName': isAdult ? null : schoolName ?? "",
      'schoolIdNo': isAdult ? null : schoolIdNo ?? "",
      'grade': isAdult ? null : grade ?? "",
      'timestamp': FieldValue.serverTimestamp(),
    };

    await docRef.update(data);
  }

  /// Adds a new vehicle to the top-level vehicles collection
  Future<void> addVehicle(Map<String, dynamic> vehicleData) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");

    final userDoc = await _firestore.collection("users").doc(currentUser.uid).get();
    if (!userDoc.exists) throw Exception("User document not found");

    final String familyId = userDoc.data()?['familyId'];
    if (familyId.isEmpty) throw Exception("User missing familyId");

    // Include metadata in vehicle document
    vehicleData["userId"] = currentUser.uid;
    vehicleData["familyId"] = familyId;
    vehicleData["createdAt"] = FieldValue.serverTimestamp();

    await _firestore.collection("vehicles").add(vehicleData);
  }

  /// Updates an existing vehicle in Firestore
  Future<void> updateVehicle({required String vehicleId, required Map<String, dynamic> vehicleData}) async {
    await _firestore.collection("vehicles").doc(vehicleId).update(vehicleData);
  }

  /// 🔹 **Deletes a vehicle from Firestore**
  Future<void> deleteVehicle(String vehicleId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("No authenticated user found.");

    try {
      await _firestore.collection("vehicles").doc(vehicleId).delete();
      print("✅ Vehicle deleted successfully.");
    } catch (e) {
      print("❌ Error deleting vehicle: $e");
      throw Exception("Failed to delete vehicle.");
    }
  }

  /// ✅ Fetches vehicles directly from top-level /vehicles where familyId matches
  Future<List<Map<String, dynamic>>> getFamilyVehicles() async {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception("No user is logged in.");

    // Fetch the current user's familyId
    DocumentSnapshot userDoc = await _firestore.collection("users").doc(currentUserId).get();
    final familyId = userDoc["familyId"];

    // ✅ Query vehicles where familyId matches
    final querySnapshot = await _firestore
        .collection("vehicles")
        .where("familyId", isEqualTo: familyId)
        .get();

    List<Map<String, dynamic>> vehicles = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data["id"] = doc.id;
      return data;
    }).toList();

    return vehicles;
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
    required List<String> carpoolParticipants,
    required int carpoolCapacity,
    required bool carpoolReturnTrip,
    bool? carpoolReturnStayOnLocation,
  }) async {
    try {
      // Get the user's familyId from their user document
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(carpoolOwnerId).get();
      if (!userDoc.exists) throw Exception("User not found.");

      final userData = userDoc.data() as Map<String, dynamic>;
      final String familyId = userData["familyId"];

      // Generate a new document in the flat 'carpools' collection
      DocumentReference carpoolDoc = _firestore.collection("carpools").doc();

      await carpoolDoc.set({
        "carpoolId": carpoolDoc.id,
        "carpoolName": carpoolName,
        "carpoolRouteStart": carpoolRouteStart,
        "carpoolRouteEnd": carpoolRouteEnd,
        "carpoolDate": carpoolDate,
        "carpoolTime": carpoolTime,
        "carpoolVehicleId": carpoolVehicleId,
        "carpoolOwnerId": carpoolOwnerId,
        "carpoolDriverId": carpoolDriverId,
        "carpoolParticipants": carpoolParticipants,
        "carpoolCapacity": carpoolCapacity,
        "carpoolReturnTrip": carpoolReturnTrip,
        "carpoolReturnStayOnLocation": carpoolReturnTrip ? carpoolReturnStayOnLocation ?? false : null,
        "carpoolStatus": "Available",
        "createdAt": FieldValue.serverTimestamp(),

        // ✅ New field for visibility and future invite logic
        "familyId": familyId,

        // 🔐 New fields for join flow
        "requestedUserIds": [],
        "invitedUserIds": [],
      });

      print("✅ Carpool successfully created in flat structure!");
    } catch (e) {
      print("🔥 Error creating carpool: $e");
      throw Exception("Failed to create carpool.");
    }
  }

  /// 🔄 Fetches all carpools visible to the current user's family
  /// ✅ Uses the new flat Firestore structure: /carpools collection
  /// ✅ Only shows carpools where familyId matches the logged-in user
  Future<List<Map<String, dynamic>>> getCarpools() async {
    try {
      // 🔹 Get the current user’s UID (logged-in user)
      final String userId = FirebaseAuth.instance.currentUser!.uid;

      // 🔹 Fetch their full user document from Firestore
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection("users").doc(userId).get();

      // 🚨 Safety check: If user document doesn’t exist, stop
      if (!userDoc.exists) {
        throw Exception("User document not found.");
      }

      // 🔹 Get the user's familyId (used to filter visible carpools)
      final String familyId = (userDoc.data() as Map<String, dynamic>)["familyId"];

      // 🔍 Fetch all carpools in the same family, ordered by date
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("carpools")
          .where("familyId", isEqualTo: familyId) // Filter by family group
          .orderBy("carpoolDate", descending: false) // Sort by upcoming date
          .get();

      // 🔄 Convert each document into a usable map and return as a list
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data["carpoolId"] = doc.id; // Include Firestore ID
        return data;
      }).toList();
    } catch (e) {
      print("🔥 Error fetching carpools: $e");
      throw Exception("Failed to fetch carpools.");
    }
  }

  /// 🔁 Updates an existing carpool in the flat `/carpools` collection.
  /// Only the `carpoolOwnerId` is allowed to update it (enforced by Firestore rules).
  Future<void> updateCarpool({
    required String carpoolId,                 // 🆔 Firestore document ID of the carpool
    required Map<String, dynamic> updatedData, // 🧾 Fields to update (from UI form)
  }) async {
    try {
      // 🔹 Reference to the carpool document directly in the top-level collection
      final DocumentReference carpoolRef =
          FirebaseFirestore.instance.collection("carpools").doc(carpoolId);

      // 🛠️ Update the document with new values (merged fields)
      await carpoolRef.update(updatedData);

      print("✅ Carpool successfully updated!");
    } catch (e) {
      print("🔥 Error updating carpool: $e");
      throw Exception("Failed to update carpool.");
    }
  }

  /// 🗑️ Deletes a carpool from the top-level /carpools collection.
  ///
  /// 🔐 Only the carpoolOwnerId (creator) is allowed to delete it.
  /// 📄 Firestore rules ensure this authorization.
  Future<void> deleteCarpool(String carpoolId) async {
    try {
      // 🔹 Directly reference the carpool document using flat structure
      final carpoolRef = FirebaseFirestore.instance.collection("carpools").doc(carpoolId);

      // 🔥 Delete the document
      await carpoolRef.delete();

      print("✅ Carpool deleted successfully.");
    } catch (e) {
      print("🔥 Error deleting carpool: $e");
      throw Exception("Failed to delete carpool.");
    }
  }

  /// 🔍 Checks if the given vehicle is available at the given date and time.
  /// ✅ Uses the flat /carpools collection instead of old nested path.
  Future<bool> isVehicleAvailable({
    required String vehicleId,
    required Timestamp carpoolDate,
    required Timestamp carpoolTime,
  }) async {
    try {
      // 🔍 Query top-level 'carpools' collection for any overlap on the same date & vehicle
      final query = await FirebaseFirestore.instance
          .collection('carpools')
          .where('carpoolVehicleId', isEqualTo: vehicleId)
          .where('carpoolDate', isEqualTo: carpoolDate)
          .get();

      // 🔁 Check if any entry already exists at the exact same time
      for (var doc in query.docs) {
        final data = doc.data();
        if (data['carpoolTime'] == carpoolTime) {
          return false; // 🚫 Vehicle already booked at this time
        }
      }

      return true; // ✅ No conflict, vehicle is available
    } catch (e) {
      print("🔥 Error checking vehicle availability: $e");
      throw Exception("Failed to check vehicle availability.");
    }
  }


  /// 🔍 Fetches a specific vehicle by its ID
  Future<Map<String, dynamic>?> getVehicleById(String vehicleId) async {
    try {
      final doc = await _firestore.collection('vehicles').doc(vehicleId).get();
      if (doc.exists) {
        return {
          ...doc.data()!,
          "id": doc.id,
        };
      }
    } catch (e) {
      print("Error fetching vehicle by ID: $e");
    }
    return null;
  }

  /// Fetches driver info by ID from the flat `users` collection only.
  Future<Map<String, dynamic>?> getDriverById({
    required String driverId,
  }) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection("users").doc(driverId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userData["id"] = userDoc.id;
        return userData;
      }

      return null;
    } catch (e) {
      print("Error fetching driver: $e");
      return null;
    }
  }

  /// 🔍 Fetches a user's document from the `users` collection using their user ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      // Fetch the document from the "users" collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Return the user data along with their ID
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userData['id'] = userDoc.id;
        return userData;
      } else {
        print("⚠️ No user found with ID: $userId");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching user by ID ($userId): $e");
      return null;
    }
  }

  /// Fetches all participants (excluding driver) from the flat users collection.
  Future<List<Map<String, dynamic>>> getCarpoolParticipants({
    required String carpoolDriverId,
    required List<String> participantIds,
  }) async {
    List<Map<String, dynamic>> resolvedParticipants = [];

    for (String participantId in participantIds) {
      if (participantId == carpoolDriverId) continue; // 🚫 Skip the driver

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(participantId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          userData["id"] = userDoc.id;
          resolvedParticipants.add(userData);
        }
      } catch (e) {
        print("Error fetching participant $participantId: $e");
      }
    }

    return resolvedParticipants;
  }

  /// 📦 Function: getExploreCarpools
  ///
  /// This function retrieves carpools that the logged-in user might want to join.
  /// It excludes:
  /// - Carpools owned by the user’s family
  /// - Carpools where the user is already a confirmed participant
  ///
  /// These carpools will be shown on the ExploreCarpoolsScreen.
  Future<List<Map<String, dynamic>>> getExploreCarpools() async {
    try {
      // Step 1: Get the currently logged-in user’s UID
      final String userId = FirebaseAuth.instance.currentUser!.uid;

      // Step 2: Fetch the user's document from the 'users' collection to retrieve their familyId
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection("users").doc(userId).get();

      if (!userDoc.exists) {
        throw Exception("User document not found.");
      }

      // Extract the familyId from the user document
      final String familyId = (userDoc.data() as Map<String, dynamic>)["familyId"];

      // Step 3: Query the 'carpools' collection with filters:
      // - The carpool must NOT belong to the same family
      // - The current user must NOT already be a confirmed participant
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("carpools")
          .where("familyId", isNotEqualTo: familyId) // Exclude same family carpools
          .get();

      // Step 4: Filter out carpools that already include the user in 'carpoolParticipants'
      final List<Map<String, dynamic>> exploreCarpools = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Skip any carpool where user is already in the confirmed participants list
        final List<dynamic> participants = data["carpoolParticipants"] ?? [];
        if (!participants.contains(userId)) {
          // Append carpool data to the results list
          exploreCarpools.add({
            ...data,
            "carpoolId": doc.id, // Add Firestore document ID
          });
        }
      }

      // Step 5: Return the filtered carpools
      return exploreCarpools;
    } catch (e) {
      print("🔥 Error fetching explore carpools: $e");
      throw Exception("Failed to fetch explore carpools.");
    }
  }

  /// 🚀 Adds the current user to a carpool's requestedUserIds list
  ///
  /// This is used when someone taps "Request to Join" on ExploreCarpoolsScreen.
  /// Firestore rules are configured to only allow the current user to add themselves.
  /// ✅ Sends a join request for selected family members to a carpool.
  /// Stores the request as: requestedUsers: { currentUserUid: [memberUid1, memberUid2] }
Future<void> requestToJoinCarpool(String carpoolId, List<String> memberUserIds) async {
  try {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      throw Exception("User not logged in.");
    }

    final DocumentReference carpoolRef =
        FirebaseFirestore.instance.collection("carpools").doc(carpoolId);

    // Use merge: true to preserve other fields in the document
    await carpoolRef.set({
      "requestedUsers": {
        currentUserId: memberUserIds,
      }
    }, SetOptions(merge: true)); // 🔁 Only updates this user's request

    print("✅ Join request sent by $currentUserId for members: $memberUserIds");
  } catch (e) {
    print("🔥 Error requesting to join carpool: $e");
    throw Exception("Failed to send join request");
  }
}


  /// ❌ Cancels a join request for a carpool by removing the user's UID
  ///
  /// This is used when a user taps "Cancel Request" on a carpool they've previously requested to join.
  Future<void> cancelJoinRequest(String carpoolId) async {
    // Step 1: Get the currently logged-in user ID
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      throw Exception("User not authenticated.");
    }

    try {
      // Step 2: Reference the carpool document in Firestore
      final DocumentReference carpoolRef =
          FirebaseFirestore.instance.collection("carpools").doc(carpoolId);

      // Step 3: Perform atomic update to remove the user's UID from requestedUserIds
      await carpoolRef.update({
        "requestedUserIds": FieldValue.arrayRemove([userId])
      });

      print("✅ Join request cancelled successfully.");
    } catch (e) {
      print("🔥 Error cancelling join request: $e");
      throw Exception("Failed to cancel join request.");
    }
  }

  /// 📥 Fetches all carpools owned by the current user that have pending join requests
  ///
  /// Returns a list of carpool maps, each containing:
  /// - Carpool metadata
  /// - A list of user maps (requesters) under `joinRequestUsers`
  Future<List<Map<String, dynamic>>> getJoinRequestsForOwner() async {
    // Step 1: Get the current user ID (this is the owner)
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    try {
      // Step 2: Query all carpools where the logged-in user is the owner
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("carpools")
          .where("carpoolOwnerId", isEqualTo: userId)
          .get();

      final List<Map<String, dynamic>> result = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> requestedUserIds = data['requestedUserIds'] ?? [];

        // Step 3: Skip carpools with no pending requests
        if (requestedUserIds.isEmpty) continue;

        // Step 4: Fetch full user details for each requester
        final List<Map<String, dynamic>> requesters = [];

        for (final String requesterId in requestedUserIds) {
          final DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection("users")
              .doc(requesterId)
              .get();

          if (userDoc.exists) {
            final requesterData = userDoc.data() as Map<String, dynamic>;
            requesters.add({
              'userId': requesterId,
              'fullName': requesterData['fullName'] ?? "Unknown User",
              'profilePhoto': requesterData['profilePhoto'],
              'relationToChild': requesterData['relationToChild'],
            });
          }
        }

        // Step 5: Merge carpool data + join request info
        result.add({
          ...data,
          'carpoolId': doc.id,
          'joinRequestUsers': requesters, // 👈 Used by the UI
        });
      }

      return result;
    } catch (e) {
      print("🔥 Error fetching join requests: $e");
      throw Exception("Failed to fetch join requests");
    }
  }

  /// ✅ Approves a join request only if the carpool has available capacity
  Future<void> approveJoinRequest(String carpoolId, String userId) async {
    try {
      final DocumentReference carpoolRef =
          FirebaseFirestore.instance.collection("carpools").doc(carpoolId);

      // Step 1: Get the current state of the carpool
      final doc = await carpoolRef.get();

      if (!doc.exists) {
        throw Exception("Carpool not found");
      }

      final data = doc.data() as Map<String, dynamic>;

      final List<dynamic> requested = data['requestedUserIds'] ?? [];
      final List<dynamic> participants = data['carpoolParticipants'] ?? [];
      final int capacity = data['carpoolCapacity'] ?? 0;

      // Step 2: Ensure the user is in the requestedUserIds list
      if (!requested.contains(userId)) {
        throw Exception("User did not request to join");
      }

      // Step 3: Check if carpool is already full
      if (participants.length >= capacity) {
        throw Exception("Carpool is already full");
      }

      // Step 4: Perform the approval if there's room
      await carpoolRef.update({
        "carpoolParticipants": FieldValue.arrayUnion([userId]),
        "requestedUserIds": FieldValue.arrayRemove([userId]),
      });

      print("✅ Approved join request for $userId in $carpoolId");
    } catch (e) {
      print("🔥 Error approving join request: $e");
      throw Exception("Failed to approve join request: ${e.toString()}");
    }
  }


  /// 🛑 Denies a join request by removing the user from requestedUserIds only
  Future<void> denyJoinRequest(String carpoolId, String userId) async {
    try {
      final DocumentReference carpoolRef =
          FirebaseFirestore.instance.collection("carpools").doc(carpoolId);

      // Step 1: Read current document to ensure user is in requestedUserIds
      final doc = await carpoolRef.get();

      if (!doc.exists) {
        throw Exception("Carpool not found");
      }

      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> requested = data['requestedUserIds'] ?? [];

      if (!requested.contains(userId)) {
        throw Exception("User not in join request list");
      }

      // Step 2: Perform the removal
      await carpoolRef.update({
        "requestedUserIds": FieldValue.arrayRemove([userId]),
      });

      print("❌ Denied join request for $userId in $carpoolId");
    } catch (e) {
      print("🔥 Error denying join request: $e");
      throw Exception("Failed to deny join request");
    }
  }
}

// --------------------------------------------------

// 📌 Filename: file_utils.dart
// 📂 Location: utils

// 📦 Filename: file_utils.dart
// 📂 Location: lib/utils/

import 'package:file_picker/file_picker.dart';

/// Utility class to encapsulate file picking functionality.
class FileUtils {
  /// Prompts user to select a file and returns the file path.
  ///
  /// [allowedExtensions] - Optional file types like ['jpg', 'pdf'].
  /// Returns null if user cancels selection.
  static Future<String?> pickFile({List<String>? allowedExtensions}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: allowedExtensions,
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path;
    }

    return null; // User cancelled
  }
}


// --------------------------------------------------

// 📌 Filename: ui_helpers.dart
// 📂 Location: utils

// 📂 lib/utils/ui_helpers.dart
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';
import 'package:kccarpoolapp/utils/file_utils.dart';

/// Type definition for a function that takes a file path and updates state
typedef FileSetter = void Function(String path);

/// 🔁 Handles the full file upload flow using FileUtils + saveFileLocally.
Future<void> handleFileUpload({
  required BuildContext context,
  required String fileType,
  required FileSetter onFilePicked,
  required FirebaseFunctions firebaseFunctions,
  List<String>? allowedExtensions,
}) async {
  // Step 1: Pick a file
  String? pickedPath = await FileUtils.pickFile(
    allowedExtensions: allowedExtensions ?? ['jpg', 'jpeg', 'png', 'pdf'],
  );

  if (pickedPath != null) {
    // Step 2: Save it locally
    String? savedPath = await firebaseFunctions.saveFileLocally(fileType, pickedPath);

    if (savedPath != null) {
      onFilePicked(savedPath); // Step 3: Notify caller
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to save file locally."),
        backgroundColor: Colors.red,
      ));
    }
  }
}

/// 🔁 Builds a consistent file upload section for any screen.
Widget buildFileUploadSection({
  required BuildContext context,
  required String label,
  required String fileType,
  required String? currentPath,
  required FirebaseFunctions firebaseFunctions,
  required FileSetter onFilePicked,
  List<String>? allowedExtensions,
}) {
  return ListTile(
    title: Text(label),
    subtitle: currentPath != null ? Text("Uploaded") : Text("Not uploaded"),
    trailing: ElevatedButton(
      onPressed: () => handleFileUpload(
        context: context,
        fileType: fileType,
        firebaseFunctions: firebaseFunctions,
        onFilePicked: onFilePicked,
        allowedExtensions: allowedExtensions,
      ),
      child: Text(currentPath != null ? "Replace" : "Upload"),
    ),
  );
}

/// 🔁 Builds a reusable text field with optional editability (used in profile/family screens)
Widget buildTextField({
  required String label,
  required TextEditingController controller,
  bool enabled = true,
  TextInputType keyboardType = TextInputType.text,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

// /// 🗓️ Shared Date Picker Field
// ///
// /// Displays a label and the selected date. Triggers `onTap()` when tapped.
// /// Doesn't include date picker logic — allows screens to handle their own `showDatePicker()`
// /// constraints (e.g., future vs past dates).
// Widget buildDatePickerField({
//   required String label,
//   required DateTime? selectedDate,
//   required VoidCallback onTap,
//   bool asTextField = false,
// }) {
//   final String displayText = selectedDate != null
//       ? "${selectedDate.day.toString().padLeft(2, '0')}/"
//         "${selectedDate.month.toString().padLeft(2, '0')}/"
//         "${selectedDate.year}"
//       : label;

//   if (asTextField) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: TextField(
//         readOnly: true,
//         onTap: onTap,
//         decoration: InputDecoration(
//           labelText: label,
//           hintText: displayText,
//           suffixIcon: Icon(Icons.calendar_today),
//         ),
//       ),
//     );
//   }

//   return ListTile(
//     title: Text(displayText),
//     trailing: Icon(Icons.calendar_today),
//     onTap: onTap,
//   );
// }




// --------------------------------------------------

