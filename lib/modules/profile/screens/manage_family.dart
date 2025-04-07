// Filename: manage_family.dart  Location: lib/modules/profile/screens/
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for handling Firestore Timestamp


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

  /// Opens a file picker and saves the selected file locally
  Future<void> _pickFile(String fileType) async {
    String? savedPath = await _firebaseFunctions.saveFileLocally(fileType);
    if (savedPath != null) {
      setState(() {
        if (fileType == "profilePhoto") _profilePhoto = savedPath;
        if (fileType == "govId") _govId = savedPath;
        if (fileType == "driverLicense") _driverLicense = savedPath;
        if (fileType == "schoolId") _schoolId = savedPath;
      });
    }
  }

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
            _buildTextField("Full Name", _nameController),
            _buildTextField("Email (Optional)", _emailController),
            _buildTextField("Phone Number (Optional)", _phoneController),

            /// Fields only for Child
            if (!_isAdult) ...[
              _buildDatePickerField("Date of Birth", _dateOfBirthController, _pickDateOfBirth),
              // _buildTextField("Date of Birth", _dateOfBirthController),
              _buildTextField("School Name", _schoolNameController),
              _buildTextField("School ID No.", _schoolIdNoController),
              _buildTextField("Grade", _gradeController),

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
            _buildFileUploadSection("Profile Photo", _profilePhoto, "profilePhoto"),
            /// Government ID Upload
            _buildFileUploadSection("Government ID", _govId, "govId"),

            /// Driver's License Upload (Only for Adults)
            if (_isAdult) _buildFileUploadSection("Driver License (Optional)", _driverLicense, "driverLicense"),

            /// School ID Upload (Only for Children)
            if (!_isAdult) _buildFileUploadSection("School ID", _schoolId, "schoolId"),

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

  /// Builds a text field
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  /// Builds a file upload button
  Widget _buildFileUploadSection(String label, String? filePath, String fileType) {
    return ListTile(
      title: Text(label),
      subtitle: filePath != null ? Text("Uploaded") : Text("Not uploaded"),
      trailing: ElevatedButton(
        onPressed: () => _pickFile(fileType),
        child: Text(filePath != null ? "Replace" : "Upload"),
      ),
    );
  }

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