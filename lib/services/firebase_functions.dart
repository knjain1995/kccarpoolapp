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