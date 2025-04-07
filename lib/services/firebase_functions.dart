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


  // /// ✅ Updates an existing family member in Firestore
  // Future<void> updateFamilyMember({
  //   required String memberId,
  //   required String fullName,
  //   required String? email,
  //   required String? phoneNumber,
  //   required bool isAdult,
  //   DateTime? dateOfBirth,
  //   required String profilePhoto,
  //   required String govId,
  //   String? schoolId,
  //   String? schoolName,
  //   String? schoolIdNo,
  //   String? grade,
  //   String? driverLicense,
  //   required String address,
  //   String? gender,
  //   String? relationToChild,
  // }) async {
  //   String? userId = getCurrentUserId();
  //   if (userId == null) throw Exception("No authenticated user found.");

  //   try {
  //     await _firestore.collection("users").doc(userId).collection("family").doc(memberId).update({
  //       "fullName": fullName,
  //       "email": email ?? "",
  //       "phoneNumber": phoneNumber ?? "",
  //       "isAdult": isAdult,
  //       "dateOfBirth": isAdult ? null : Timestamp.fromDate(dateOfBirth!),
  //       "profilePhoto": profilePhoto,
  //       "govId": govId,
  //       "driverLicense": isAdult ? driverLicense ?? "" : null,
  //       "schoolId": isAdult ? null : schoolId ?? "",
  //       "schoolName": isAdult ? null : schoolName ?? "",
  //       "schoolIdNo": isAdult ? null : schoolIdNo ?? "",
  //       "grade": isAdult ? null : grade ?? "",
  //       "address": address,
  //       "gender": isAdult ? null : gender,
  //       "relationToChild": relationToChild,
  //     });
  //   } catch (e) {
  //     print("Error updating family member: $e");
  //     throw Exception("Failed to update family member.");
  //   }
  // }

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

  // /// 🔹 **Adds a new vehicle to Firestore**
  // Future<void> addVehicle(Map<String, dynamic> vehicleData) async {
  //   User? user = _auth.currentUser;
  //   if (user == null) throw Exception("No authenticated user found.");

  //   try {
  //     await _firestore.collection("users").doc(user.uid).collection("vehicles").add(vehicleData);
  //     print("✅ Vehicle added successfully.");
  //   } catch (e) {
  //     print("❌ Error adding vehicle: $e");
  //     throw Exception("Failed to add vehicle.");
  //   }
  // }

  /// Updates an existing vehicle in Firestore
  Future<void> updateVehicle({required String vehicleId, required Map<String, dynamic> vehicleData}) async {
    await _firestore.collection("vehicles").doc(vehicleId).update(vehicleData);
  }


  // /// Updates an existing vehicle in Firestore
  // Future<void> updateVehicle({
  //   required String vehicleId,
  //   required Map<String, dynamic> vehicleData, // Pass the whole vehicle map
  // }) async {
  //   try {
  //     String? userId = FirebaseAuth.instance.currentUser?.uid;
  //     if (userId == null) throw Exception("User not logged in");

  //     await FirebaseFirestore.instance
  //         .collection("users")
  //         .doc(userId)
  //         .collection("vehicles")
  //         .doc(vehicleId)
  //         .update(vehicleData); // Update with the whole map

  //     print("Vehicle Updated Successfully!");
  //   } catch (e) {
  //     print("Error updating vehicle: $e");
  //     throw Exception("Failed to update vehicle.");
  //   }
  // }

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




  // /// 🔹 **Retrieves the list of vehicles for the logged-in user**
  // Future<List<Map<String, dynamic>>> getVehicles() async {
  //   User? user = _auth.currentUser;
  //   if (user == null) throw Exception("No authenticated user found.");

  //   try {
  //     QuerySnapshot vehicleSnapshot =
  //         await _firestore.collection("users").doc(user.uid).collection("vehicles").get();

  //     List<Map<String, dynamic>> vehicles = vehicleSnapshot.docs.map((doc) {
  //       Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //       data["id"] = doc.id; // Include document ID for editing/deleting
  //       return data;
  //     }).toList();

  //     return vehicles;
  //   } catch (e) {
  //     print("❌ Error fetching vehicles: $e");
  //     throw Exception("Failed to retrieve vehicles.");
  //   }
  // }


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
        "carpoolParticipants": carpoolParticipants,
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

  /// 🔍 Fetches a specific vehicle by its ID
  Future<Map<String, dynamic>?> getVehicleById(String vehicleId) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");

    try {
      DocumentSnapshot vehicleDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("vehicles")
          .doc(vehicleId)
          .get();

      if (vehicleDoc.exists) {
        Map<String, dynamic> data = vehicleDoc.data() as Map<String, dynamic>;
        data["id"] = vehicleDoc.id; // Include document ID
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching vehicle by ID: $e");
      return null;
    }
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


  // /// Fetches driver details by ID from either users or family subcollection
  // /// Fetches driver info by ID from either users or family subcollection of the carpool owner
  // Future<Map<String, dynamic>?> getDriverById({
  //   required String driverId,
  //   required String carpoolOwnerId, // Always the account owner
  // }) async {
  //   try {
  //     final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //     // Case 1: If the driverId is the same as the account owner's ID
  //     if (driverId == carpoolOwnerId) {
  //       DocumentSnapshot userDoc =
  //           await _firestore.collection("users").doc(driverId).get();
  //       if (userDoc.exists) {
  //         Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
  //         userData["id"] = driverId;
  //         return userData;
  //       }
  //     }

  //     // Case 2: If the driverId is in the family subcollection of the carpool owner
  //     DocumentSnapshot familyDoc = await _firestore
  //         .collection("users")
  //         .doc(carpoolOwnerId)
  //         .collection("family")
  //         .doc(driverId)
  //         .get();

  //     if (familyDoc.exists) {
  //       Map<String, dynamic> familyData =
  //           familyDoc.data() as Map<String, dynamic>;
  //       familyData["id"] = driverId;
  //       return familyData;
  //     }

  //     return null; // Not found
  //   } catch (e) {
  //     print("Error fetching driver: $e");
  //     return null;
  //   }
  // }

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


  // /// 🔹 Resolves participant details (excluding driver) for a carpool
  // Future<List<Map<String, dynamic>>> getCarpoolParticipants({
  //   required String carpoolOwnerId,
  //   required String carpoolDriverId,
  //   required List<String> participantIds,
  // }) async {
  //   List<Map<String, dynamic>> resolvedParticipants = [];

  //   try {
  //     for (String participantId in participantIds) {
  //       // 🚫 Skip the driver
  //       if (participantId == carpoolDriverId) continue;

  //       Map<String, dynamic>? participantData;

  //       if (participantId == carpoolOwnerId) {
  //         // ✅ Reuse getUserById for account owner
  //         participantData = await getUserById(participantId);
  //       } else {
  //         // ✅ Participant is a family member
  //         DocumentSnapshot doc = await _firestore
  //             .collection("users")
  //             .doc(carpoolOwnerId)
  //             .collection("family")
  //             .doc(participantId)
  //             .get();
  //         if (doc.exists) {
  //           participantData = doc.data() as Map<String, dynamic>;
  //         }
  //       }

  //       if (participantData != null) {
  //         participantData["id"] = participantId;
  //         resolvedParticipants.add(participantData);
  //       }
  //     }

  //     return resolvedParticipants;
  //   } catch (e) {
  //     print("❌ Error resolving carpool participants: $e");
  //     return [];
  //   }
  // }



}