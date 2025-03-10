import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
  Future<void> _submitVerification() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please complete all required fields.")),
      );
      return;
    }

    try {
      await _firebaseFunctions.storeVerificationData(
        emailOtp: _emailOtpController.text.trim(),
        phoneOtp: _phoneOtpController.text.trim(),
        photoUrl: _photoFile!,
        driverLicenseUrl: _driverLicenseFile, // Optional
        govIdUrl: _govIdFile!,
        address: _addressController.text.trim(),
        relationToChild: _relationToChild!,
      );

      // Navigate to Home after successful verification
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting verification data.")),
      );
    }
  }

  /// used to upload documents to firestore
  Future<String?> _uploadFile(String fieldName) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'], // Restrict to images and PDFs
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final fileName = "${FirebaseAuth.instance.currentUser!.uid}_$fieldName.${file.extension}";

    // Upload to Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child("uploads/$fileName");
    await storageRef.putData(file.bytes!);

    // Return download URL
    return await storageRef.getDownloadURL();
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
                if (url != null) setState(() => _photoFile = url);
              },
              child: Text(_photoFile == null ? "Upload Photo" : "Photo Uploaded"),
            ),
            SizedBox(height: 10),

            /// Upload Driver License (Optional)
            Text("Upload Driver License (Optional)"),
            ElevatedButton(
              onPressed: () async {
                String? url = await _uploadFile("driverLicense");
                if (url != null) setState(() => _driverLicenseFile = url);
              },
              child: Text(_driverLicenseFile == null ? "Upload License" : "License Uploaded"),
            ),
            SizedBox(height: 10),

            /// Upload Government ID (Required)
            Text("Upload Government ID (Required)"),
            ElevatedButton(
              onPressed: () async {
                String? url = await _uploadFile("govId");
                if (url != null) setState(() => _govIdFile = url);
              },
              child: Text(_govIdFile == null ? "Upload ID" : "ID Uploaded"),
            ),
            SizedBox(height: 20),

            /// Address Input
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: "Enter Your Address"),
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
                onPressed: _submitVerification,
                child: Text("Submit & Proceed to Home"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
