import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/modules/home/screens/home_screen.dart';
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

  /// for file upload
  File? _selectedFile;
  String? _fileName;
  bool _isFileUploaded = false; // Flag for UI update

  /// Validates if all required fields are filled
  bool _validateForm() {
    if (_emailOtpController.text.isEmpty ||
        _phoneOtpController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _photoFile == null ||
        _govIdFile == null ||
        _relationToChild == null) {
      return false;
    }
    return true;
  }

  /// Submits verification data to Firestore
  Future<void> _saveVerificationData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    Map<String, dynamic> verificationData = {
      "profilePhoto": _photoFile ?? "",
      "driverLicense": _driverLicenseFile ?? "",
      "govId": _govIdFile ?? "",
      "address": _addressController.text.trim(),
      "relationToChild": _relationToChild,
      "emailVerified": true, // Placeholder for now
      "phoneVerified": true, // Placeholder for now
    };

    try {
      await FirebaseFirestore.instance.collection("users").doc(userId).update(verificationData);
      print("Verification data saved successfully!");

      // Navigate to Home Screen after successful submission
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));

    } catch (e) {
      print("Error saving verification data: $e");
    }
  }

  /// used to upload documents to firestore
  Future<String?> _uploadFile(String fileType) async {
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
                String? url = await _uploadFile("profilePhoto");
                if (url != null) {
                  setState(() {
                    _photoFile = url;
                  });
                  print("Profile photo uploaded: $url");
                }
              },
              child: Text(_photoFile == null ? "Upload Photo" : "Photo Uploaded ✅"),
            ),
            SizedBox(height: 10),

            /// Upload Driver License (Optional)
            Text("Upload Driver License (Optional)"),
            ElevatedButton(
              onPressed: () async {
                String? url = await _uploadFile("driverLicense");
                if (url != null) {
                  setState(() {
                    _driverLicenseFile = url;
                  });
                  print("Driver License uploaded: $url");
                }
              },
              child: Text(_driverLicenseFile == null ? "Upload License" : "License Uploaded ✅"),
            ),
            SizedBox(height: 10),

            /// Upload Government ID (Required)
            Text("Upload Government ID (Required)"),
            ElevatedButton(
              onPressed: () async {
                String? url = await _uploadFile("govId");
                if (url != null) {
                  setState(() {
                    _govIdFile = url;
                  });
                  print("Government ID uploaded: $url");
                }
              },
              child: Text(_govIdFile == null ? "Upload ID" : "ID Uploaded ✅"),
            ),
            SizedBox(height: 20),

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
                    await _saveVerificationData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please complete all required fields!"))
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
