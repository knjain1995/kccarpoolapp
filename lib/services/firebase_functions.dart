import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// FirebaseFunctions - Centralized class for Firebase Authentication calls
class FirebaseFunctions {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


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

  /// Save use signup data in Firestore
  Future<void> saveUserData({
  required String fullName,
  required String email,
  required String phoneNumber,
}) async {
  User? user = _auth.currentUser;
  if (user == null) {
    throw Exception("No authenticated user found.");
  }

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


   /// Store user verification data in Firestore
  Future<void> storeVerificationData({
    required String emailOtp,
    required String phoneOtp,
    required String photoUrl,
    required String? driverLicenseUrl, // Optional
    required String govIdUrl,
    required String address,
    required String relationToChild,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("No authenticated user found.");
    }

    try {
      await _firestore.collection("users").doc(user.uid).set({
        "emailOtp": emailOtp, // Placeholder for now
        "phoneOtp": phoneOtp, // Placeholder for now
        "photoUrl": photoUrl,
        "driverLicenseUrl": driverLicenseUrl ?? "",
        "govIdUrl": govIdUrl,
        "address": address,
        "relationToChild": relationToChild,
        "verified": true, // Mark user as verified
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("Verification data stored successfully.");
    } catch (e) {
      print("Error storing verification data: $e");
      throw Exception("Failed to store verification data.");
    }
  }

  /// When OTP verification is successful, we update the Firestore document
  Future<void> markVerificationSuccess({
  required bool emailVerified,
  required bool phoneVerified,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("No authenticated user found.");
    }

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

    /// Uploads file to Firebase Storage and returns the download URL
  Future<String?> uploadFile(String fileType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = "${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}";

      try {
        // Upload file to Firebase Storage
        Reference storageRef = FirebaseStorage.instance.ref().child('uploads/$fileType/$fileName');
        UploadTask uploadTask = storageRef.putFile(file);
        
        // Wait for upload completion
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        
        print("Uploaded File URL: $downloadUrl");
        return downloadUrl; // Return the URL to save in Firestore
      } catch (e) {
        print("File upload error: $e");
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
      await FirebaseFirestore.instance.collection("users").doc(userId).update(verificationData);
      print("Verification data saved successfully!");
    } catch (e) {
      print("Error saving verification data: $e");
    }
  }
}
