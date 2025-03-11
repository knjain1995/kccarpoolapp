import 'dart:io'; // Required for handling local file storage
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart'; // Firebase interaction class
import 'package:kccarpoolapp/services/auth_service.dart'; // Authentication service
import 'package:file_picker/file_picker.dart'; // Used for selecting local files

/// The Profile Screen allows users to view and update their details.
/// Users can change their profile picture, update their address, and manage uploaded documents.
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions(); // Firebase interaction instance
  final AuthService _authService = AuthService(); // Authentication service instance

  // Controllers for text fields, allowing users to edit their details
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // User profile-related fields
  String? _profilePhoto; // Stores local path of profile photo
  String? _govId; // Stores local path of government ID
  String? _driverLicense; // Stores local path of driver’s license (optional)
  String? _relationToChild; // Stores relation to child (Father, Mother, Guardian)

  bool _isEditing = false; // Controls whether user is in "Edit Mode"

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Fetch user data when the screen loads
  }

  /// Fetches the user's profile data from Firestore
  Future<void> _loadUserProfile() async {
    var userData = await _firebaseFunctions.getUserData();
    if (userData != null) {
      setState(() {
        _nameController.text = userData["fullName"] ?? "";
        _emailController.text = userData["email"] ?? "";
        _phoneController.text = userData["phoneNumber"] ?? "";
        _addressController.text = userData["address"] ?? "";
        _profilePhoto = userData["profilePhoto"];
        _govId = userData["govId"];
        _driverLicense = userData["driverLicense"];
        _relationToChild = userData["relationToChild"];
      });
    }
  }

  /// Opens a file picker and saves the selected file locally
  Future<void> _pickFile(String fileType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, // Allows selection of specific file types
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], // Supported file types
    );

    if (result != null) {
      // Save the file locally
      String? savedPath = await _firebaseFunctions.saveFileLocally(fileType);
      if (savedPath != null) {
        setState(() {
          if (fileType == "profilePhoto") _profilePhoto = savedPath;
          if (fileType == "govId") _govId = savedPath;
          if (fileType == "driverLicense") _driverLicense = savedPath;
        });
      }
    }
  }

  /// Saves the updated user profile data to Firestore
  Future<void> _saveProfile() async {
    await _firebaseFunctions.updateUserProfile(
      fullName: _nameController.text,
      phoneNumber: _phoneController.text,
      address: _addressController.text,
      profilePhoto: _profilePhoto!,
      govId: _govId!,
      driverLicense: _driverLicense ?? "",
      relationToChild: _relationToChild!,
    );

    setState(() => _isEditing = false); // Exit edit mode
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile updated!")));
  }

  /// Logs the user out and navigates back to the login screen
  Future<void> _logout() async {
    await _authService.logout(context); // Now properly handles logout and navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          // Logout Button
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            /// Profile Picture Section
            GestureDetector(
              onTap: () => _pickFile("profilePhoto"),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profilePhoto != null ? FileImage(File(_profilePhoto!)) : null,
                child: _profilePhoto == null ? Icon(Icons.person, size: 50) : null,
              ),
            ),
            SizedBox(height: 20),

            /// Editable Text Fields
            _buildTextField("Full Name", _nameController, _isEditing),
            _buildTextField("Email", _emailController, false),
            _buildTextField("Phone Number", _phoneController, _isEditing),
            _buildTextField("Address", _addressController, _isEditing),

            /// File Upload Sections
            _buildFileUploadSection("Government ID", _govId, "govId"),
            _buildFileUploadSection("Driver License (Optional)", _driverLicense, "driverLicense"),

            /// Relation to Child Dropdown (Only editable in Edit Mode)
            if (_isEditing)
              DropdownButtonFormField<String>(
                value: _relationToChild,
                items: ["Father", "Mother", "Guardian"].map((relation) {
                  return DropdownMenuItem(value: relation, child: Text(relation));
                }).toList(),
                onChanged: (value) {
                  setState(() => _relationToChild = value);
                },
                decoration: InputDecoration(labelText: "Relation to Child"),
              ),
            SizedBox(height: 20),

            /// Save / Edit Profile Button
            _isEditing
                ? ElevatedButton(onPressed: _saveProfile, child: Text("Save"))
                : ElevatedButton(onPressed: () => setState(() => _isEditing = true), child: Text("Edit Profile")),
          ],
        ),
      ),
    );
  }

  /// Builds a text field with optional editing capability
  Widget _buildTextField(String label, TextEditingController controller, bool isEditable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: isEditable,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  /// Builds a section for file uploads
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
}