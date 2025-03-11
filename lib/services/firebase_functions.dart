import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// FirebaseFunctions - Centralized class for Firebase Authentication and Firestore interactions
class FirebaseFunctions {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

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
    User? user = _auth.currentUser;
    if (user == null) return null; // No user logged in

    try {
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(user.uid).get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>; // Return user data
      } else {
        return null; // No data found
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
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
  Future<String?> saveFileLocally(String fileType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      try {
        // Get external storage directory (PUBLIC access)
        Directory? appDocDir = await getExternalStorageDirectory();
        if (appDocDir == null) {
          print("Failed to get external storage directory.");
          return null;
        }

        String localPath = '${appDocDir.path}/$fileType';

        // Ensure the directory exists
        Directory(localPath).createSync(recursive: true);

        // Create new file path
        File file = File(result.files.single.path!);
        String newFilePath = '$localPath/${result.files.single.name}';

        // Copy the file to public storage
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
}
