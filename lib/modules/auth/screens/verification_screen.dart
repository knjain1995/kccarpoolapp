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