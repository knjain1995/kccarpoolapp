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
        "joinRequestIds": [], // 🔐 Ensures Firestore allows appending to this later
        'approvedRequestIds': [],     // 🆕 Initialize empty approved requests list
        'deniedRequestIds': [],       // 🆕 Initialize empty denied requests list
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

  /// 🔗 Submits a join request using the new flat collection structure
  Future<void> requestToJoinCarpoolFlat({
    required String carpoolId,
    required List<String> memberUserIds,
  }) async {
    try {
      final String? requesterId = FirebaseAuth.instance.currentUser?.uid;

      if (requesterId == null) {
        throw Exception("User not logged in.");
      }

      final String requestId = "${carpoolId}_$requesterId";
      final joinRequestRef = FirebaseFirestore.instance.collection("joinRequests").doc(requestId);


      // Create the join request document with required metadata
      await joinRequestRef.set({
        "requestId": joinRequestRef.id,           // ✅ Store requestId inside the document
        "carpoolId": carpoolId,
        "carpoolOwnerId": await _getCarpoolOwnerId(carpoolId),
        "requesterId": requesterId,
        "memberUserIds": memberUserIds,
        "status": "pending",
        "timestamp": FieldValue.serverTimestamp(),
      });

      // Also update the carpool document to track this join request ID
      await FirebaseFirestore.instance
          .collection("carpools")
          .doc(carpoolId)
          .update({
            "joinRequestIds": FieldValue.arrayUnion([joinRequestRef.id])
          });

      print("✅ Join request submitted for carpool $carpoolId by $requesterId for members: $memberUserIds");
    } catch (e) {
      print("🔥 Error submitting join request: $e");
      throw Exception("Failed to send join request.");
    }
  }

  /// 🔎 Fetches the carpoolOwnerId from Firestore given the carpoolId
  Future<String> _getCarpoolOwnerId(String carpoolId) async {
    final doc = await FirebaseFirestore.instance.collection("carpools").doc(carpoolId).get();

    if (!doc.exists || !doc.data()!.containsKey('carpoolOwnerId')) {
      throw Exception("Carpool owner not found");
    }

    return doc.data()!['carpoolOwnerId'];
  }

  /// ❌ Cancels a join request by deleting the flat joinRequest document
  /// AND removing its ID from the corresponding carpool's `joinRequestIds` array.
  ///
  /// This is used when a user taps "Cancel Request" in the Explore Carpools screen.
  Future<void> cancelJoinRequest(String carpoolId) async {
    try {
      final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == null) {
        throw Exception("User not logged in.");
      }

      // 🆔 The joinRequestId is in the format carpoolId_userId
      final String joinRequestId = "${carpoolId}_$currentUserId";

      // 📄 Reference to the flat joinRequests/{requestId} document
      final DocumentReference joinRequestRef =
          FirebaseFirestore.instance.collection("joinRequests").doc(joinRequestId);

      // 📄 Reference to the carpool document
      final DocumentReference carpoolRef =
          FirebaseFirestore.instance.collection("carpools").doc(carpoolId);

      // 🔁 Step 1: Remove the request ID from the carpool's joinRequestIds array
      await carpoolRef.update({
        "joinRequestIds": FieldValue.arrayRemove([joinRequestId])
      });

      // 🗑️ Step 2: Delete the join request document
      await joinRequestRef.delete();

      print("❌ Successfully cancelled join request for carpool $carpoolId by $currentUserId");

    } catch (e) {
      print("🔥 Error cancelling join request: $e");
      throw Exception("Failed to cancel join request.");
    }
  }


  /// 🔄 Retrieves all join requests for carpools owned by the current user.
  /// Includes requests with status: pending, approved, denied.
  Future<List<Map<String, dynamic>>> getJoinRequestsForOwner() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    List<Map<String, dynamic>> finalResults = [];

    // 🔍 Step 1: Get all carpools where current user is the owner
    final QuerySnapshot carpoolSnapshot = await _firestore
        .collection('carpools')
        .where('carpoolOwnerId', isEqualTo: currentUser.uid)
        .get();

    for (final carpoolDoc in carpoolSnapshot.docs) {
      final carpoolData = carpoolDoc.data() as Map<String, dynamic>;
      final String carpoolId = carpoolDoc.id;

      // 👥 Step 2: Get all request IDs — across all statuses
      final List<dynamic> pendingIds = carpoolData["joinRequestIds"] ?? [];
      final List<dynamic> approvedIds = carpoolData["approvedRequestIds"] ?? [];
      final List<dynamic> deniedIds = carpoolData["deniedRequestIds"] ?? [];

      // 🧮 Combine all into one list to look up
      final List<String> allRequestIds = [
        ...pendingIds,
        ...approvedIds,
        ...deniedIds,
      ].cast<String>();

      List<Map<String, dynamic>> joinRequestUsers = [];

      for (final String requestId in allRequestIds) {
        final DocumentSnapshot requestDoc = await _firestore
            .collection('joinRequests')
            .doc(requestId)
            .get();

        if (!requestDoc.exists) continue;

        final requestData = requestDoc.data() as Map<String, dynamic>;
        final String requesterId = requestData["requesterId"];

        // 🧑‍💼 Fetch requester’s user profile
        final DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(requesterId)
            .get();

        if (!userDoc.exists) continue;

        final userData = userDoc.data() as Map<String, dynamic>;

        // ✅ Build enriched join request entry
        joinRequestUsers.add({
          "userId": requesterId,
          "fullName": userData["fullName"] ?? "Unknown User",
          "profilePhoto": userData["profilePhoto"],
          "relationToChild": userData["relationToChild"],
          "memberUserIds": requestData["memberUserIds"] ?? [],
          "requestId": requestId,
          "status": requestData["status"] ?? "pending", // 💡 Used for grouping
        });
      }

      // 🧺 Add to final results only if at least one request exists
      if (joinRequestUsers.isNotEmpty) {
        finalResults.add({
          ...carpoolData,
          "carpoolId": carpoolId,
          "joinRequestUsers": joinRequestUsers,
        });
      }
    }

    return finalResults;
  }

  /// 📄 Refactored approveJoinRequest function
  /// This function:
  /// - Adds selected family members to carpoolParticipants
  /// - Removes requestId from joinRequestIds
  /// - Adds requestId to approvedRequestIds
  /// - Updates the join request document status to 'approved'
  /// 
  /// 🚀 All done atomically in a single Firestore batch

  Future<void> approveJoinRequest({
    required String carpoolId,
    required String requesterId,
    required String requestId,
    required List<String> memberUserIds,
  }) async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final WriteBatch batch = _firestore.batch();

      // 🔗 Reference to the carpool document
      final DocumentReference carpoolRef = _firestore.collection('carpools').doc(carpoolId);

      // 🔗 Reference to the join request document
      final DocumentReference joinRequestRef = _firestore.collection('joinRequests').doc(requestId);

      // ➡️ 1. Add selected family members to carpoolParticipants
      batch.update(carpoolRef, {
        'carpoolParticipants': FieldValue.arrayUnion(memberUserIds),
      });

      // ➡️ 2. Remove this join request from pending requests
      batch.update(carpoolRef, {
        'joinRequestIds': FieldValue.arrayRemove([requestId]),
      });

      // ➡️ 3. Add this request to approved requests
      batch.update(carpoolRef, {
        'approvedRequestIds': FieldValue.arrayUnion([requestId]),
      });

      // ➡️ 4. Update the status field inside the joinRequests document
      batch.update(joinRequestRef, {
        'status': 'approved',
      });

      // 🚀 Commit all batched writes atomically
      await batch.commit();

      print('✅ Successfully approved join request with ID: $requestId');
    } catch (e) {
      print('🔥 Error approving join request: $e');
      throw Exception('Failed to approve join request.');
    }
  }



  /// ❌ Deny a join request for a carpool
  ///
  /// This function will:
  /// - Update the join request's status to "Denied"
  /// - Move the request ID into deniedRequestIds[] array of the carpool
  /// - Remove the request ID from joinRequestIds[] array of the carpool
  Future<void> denyJoinRequest({
    required String carpoolId,
    required String requesterId,
    required String requestId,
  }) async {
    try {
      final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
        
      if (currentUserId == null) {
        throw Exception("User not logged in.");
      }

      final carpoolRef = FirebaseFirestore.instance.collection('carpools').doc(carpoolId);
      final joinRequestRef = FirebaseFirestore.instance.collection('joinRequests').doc(requestId);
      
      // ✅ DEBUG PRINTS: Show what we are trying to update
      print("🛠 Denying Join Request:");
      print("Request ID: $requestId");
      print("Carpool ID: $carpoolId");
      print("Requester User ID: $requesterId");
      print("Updater (current user): $currentUserId");
      
      // Step 1: Update join request status to "Denied"
      await joinRequestRef.update({
        'status': 'Denied',
      });

      // Step 2: Move requestId from joinRequestIds → deniedRequestIds in carpool
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final carpoolSnapshot = await transaction.get(carpoolRef);
        final carpoolData = carpoolSnapshot.data();

        if (carpoolData == null) {
          throw Exception('Carpool does not exist.');
        }

        List<dynamic> joinRequestIds = carpoolData['joinRequestIds'] ?? [];
        List<dynamic> deniedRequestIds = carpoolData['deniedRequestIds'] ?? [];

        joinRequestIds.remove(requestId);
        deniedRequestIds.add(requestId);

        transaction.update(carpoolRef, {
          'joinRequestIds': joinRequestIds,
          'deniedRequestIds': deniedRequestIds,
        });
      });

      print('✅ Denied join request $requestId for carpool $carpoolId.');
    } catch (e) {
      print('🔥 Error denying join request: $e');
      throw Exception('Failed to deny join request.');
    }
  }


  /// Checks if the current user has already requested to join the given carpool
  Future<bool> hasUserRequestedJoin(String carpoolId) async {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;

    final DocumentSnapshot requestDoc = await FirebaseFirestore.instance
      .collection("carpools")
      .doc(carpoolId)
      .collection("joinRequests")
      .doc(currentUserId)
      .get();

    return requestDoc.exists;
  }

}