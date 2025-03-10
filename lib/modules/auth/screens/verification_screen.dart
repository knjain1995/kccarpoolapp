import 'package:flutter/material.dart';

/// VerificationScreen - Handles user verification after signup
class VerificationScreen extends StatefulWidget {
  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _emailOtpController = TextEditingController();
  final TextEditingController _phoneOtpController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
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

  /// Handles form submission
  void _submitVerification() {
    if (_validateForm()) {
      // Navigate to Home Screen
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please complete all required fields.")),
      );
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
              onPressed: () {
                // TODO: Implement file picker
                setState(() => _photoFile = "photo_uploaded.jpg");
              },
              child: Text(_photoFile == null ? "Upload Photo" : "Photo Uploaded"),
            ),
            SizedBox(height: 10),

            /// Upload Driver License (Optional)
            Text("Upload Driver License (Optional)"),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement file picker
                setState(() => _driverLicenseFile = "license_uploaded.jpg");
              },
              child: Text(_driverLicenseFile == null ? "Upload License" : "License Uploaded"),
            ),
            SizedBox(height: 10),

            /// Upload Government ID (Required)
            Text("Upload Government ID (Required)"),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement file picker
                setState(() => _govIdFile = "gov_id_uploaded.jpg");
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
