// Filename: profile_screen.dart  Location: lib/modules/profile/screens/
import 'dart:io'; // Required for handling local file storage
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/core/routes.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart'; // Firebase interaction class
import 'package:kccarpoolapp/services/auth_service.dart'; // Authentication service
import 'package:kccarpoolapp/utils/ui_helpers.dart'; // File upload + UI helpers


/// The Profile Screen allows users to view and update their details.
/// Users can change their profile picture, update their address, and manage uploaded documents.
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions(); // Firebase interaction instance
  final AuthService _authService = AuthService(); // Authentication service instance

  List<Map<String, dynamic>> _adults = []; // Stores list of adult family members
  List<Map<String, dynamic>> _children = []; // Stores list of child family members
  List<Map<String, dynamic>> _vehicles = []; // Stores list of vehicles
  bool _isLoading = true; // Tracks loading state

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
    _loadFamilyMembers(); // Fetch family members on screen load
    _loadVehicles(); // Fetch user's vehicles
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

  // /// Opens a file picker and saves the selected file locally
  // Future<void> _pickFile(String fileType) async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom, // Allows selection of specific file types
  //     allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], // Supported file types
  //   );

  //   if (result != null) {
  //     // Save the file locally
  //     String? savedPath = await _firebaseFunctions.saveFileLocally(fileType);
  //     if (savedPath != null) {
  //       setState(() {
  //         if (fileType == "profilePhoto") _profilePhoto = savedPath;
  //         if (fileType == "govId") _govId = savedPath;
  //         if (fileType == "driverLicense") _driverLicense = savedPath;
  //       });
  //     }
  //   }
  // }

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

  /// Fetches family members from Firestore and separates them into Adults and Children
  /// Loads family members using flat user model & families/{familyId}/memberUserIds
  Future<void> _loadFamilyMembers() async {
    List<Map<String, dynamic>> familyData =
        await _firebaseFunctions.getFamilyMembersByIds(includePrimaryUser: false); // 🔄 New flat model

    setState(() {
      _adults = familyData.where((member) => member['isAdult'] == true).toList();
      _children = familyData.where((member) => member['isAdult'] == false).toList();
      _isLoading = false;
    });
  }


  /// Deletes a family member after confirmation
  void _deleteFamilyMember(String memberId) async {
    bool confirmDelete = await _showDeleteConfirmationDialog();
    if (confirmDelete) {
      try {
        await _firebaseFunctions.deleteFamilyMemberFromUsers(memberId);
        await _loadFamilyMembers(); // Refresh list after deletion
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Family member deleted.")));
      } catch (e) {
        print("Error deleting family member: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting family member.")));
      }
    }
  }

  /// Shows a confirmation dialog before deleting a family member
  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Delete Family Member"),
            content: Text("Are you sure you want to remove this family member?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete", style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }

  /// Navigates to Manage Family screen for editing a family member
  void _editFamilyMember(Map<String, dynamic> memberData) {
    Navigator.pushNamed(context, AppRoutes.manageFamily, arguments: memberData);
  }

    /// Fetches the user's vehicles from Firestore
  Future<void> _loadVehicles() async {
    List<Map<String, dynamic>> vehicleData = await _firebaseFunctions.getFamilyVehicles();

    setState(() {
      _vehicles = vehicleData;
      _isLoading = false;
    });
  }

    /// Deletes a vehicle after confirmation
  void _deleteVehicle(String vehicleId) async {
    bool confirmDelete = await _showDeleteVehicleConfirmationDialog();
    if (confirmDelete) {
      await _firebaseFunctions.deleteVehicle(vehicleId);
      _loadVehicles(); // Refresh list after deletion
    }
  }

    /// Shows a confirmation dialog before deleting a vehicle
  Future<bool> _showDeleteVehicleConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Delete Vehicle"),
            content: Text("Are you sure you want to remove this vehicle?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete", style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }

  /// Navigates to Manage Vehicles screen for adding/editing a vehicle
  void _manageVehicle({Map<String, dynamic>? vehicleData}) {
  if (vehicleData != null && vehicleData.containsKey("id")) { // ✅ Ensure `id` exists when editing
    print("🚀 Navigating to ManageVehiclesScreen with: $vehicleData"); // Debug
  } else {
    print("🚀 Navigating to ManageVehiclesScreen for adding a new vehicle."); // Debug
  }

    Navigator.pushNamed(
      context,
      AppRoutes.manageVehicles,
      arguments: vehicleData, // ✅ Pass data if editing, otherwise null for adding
    ).then((_) => _loadVehicles()); // ✅ Reload vehicle list after returning
  }
  

  /// Logs the user out and navigates back to the login screen
  Future<void> _logout() async {
    await _authService.logout(context); // Properly handles logout and navigation
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            /// Profile Picture Section
            GestureDetector(
              // onTap: () => _pickFile("profilePhoto"),
              onTap: () => handleFileUpload(
                context: context,
                fileType: "profilePhoto",
                firebaseFunctions: _firebaseFunctions,
                onFilePicked: (path) => setState(() => _profilePhoto = path),
                allowedExtensions: ['jpg', 'jpeg', 'png'],
              ),
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
            // _buildFileUploadSection("Government ID", _govId, "govId"),
            // _buildFileUploadSection("Driver License (Optional)", _driverLicense, "driverLicense"),
            buildFileUploadSection(
              context: context,
              label: "Government ID",
              fileType: "govId",
              currentPath: _govId,
              firebaseFunctions: _firebaseFunctions,
              onFilePicked: (path) => setState(() => _govId = path),
            ),

            buildFileUploadSection(
              context: context,
              label: "Driver License (Optional)",
              fileType: "driverLicense",
              currentPath: _driverLicense,
              firebaseFunctions: _firebaseFunctions,
              onFilePicked: (path) => setState(() => _driverLicense = path),
            ),

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
          
            // ✅ Manage Family Button
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.manageFamily); // ✅ Navigate to Manage Family
              },
              icon: Icon(Icons.family_restroom),
              label: Text("Manage Family"),
            ),

            SizedBox(height: 20),

            // Family Members Section
            Text("Your Family Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            // Adults Section
            if (_adults.isNotEmpty) ...[
              Text("Adults", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              _buildFamilyList(_adults),
              SizedBox(height: 10),
            ],

            // Children Section
            if (_children.isNotEmpty) ...[
              Text("Children", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              _buildFamilyList(_children),
            ],

            SizedBox(height: 20),

            /// Manage Vehicles Button
            ElevatedButton.icon(
              onPressed: () => _manageVehicle(),
              icon: Icon(Icons.directions_car),
              label: Text("Manage Vehicles"),
            ),

            SizedBox(height: 20),

            /// Vehicles List Section
            if (_vehicles.isNotEmpty) ...[
              Text("Your Vehicles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildVehicleList(),
            ],            
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

  // /// Builds a section for file uploads
  // Widget _buildFileUploadSection(String label, String? filePath, String fileType) {
  //   return ListTile(
  //     title: Text(label),
  //     subtitle: filePath != null ? Text("Uploaded") : Text("Not uploaded"),
  //     trailing: ElevatedButton(
  //       onPressed: () async {
  //         // 1. Let user pick a file
  //         String? pickedPath = await FileUtils.pickFile(
  //           allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
  //         );

  //         if (pickedPath != null) {
  //           // 2. Save it locally (your existing logic)
  //           String? savedPath = await _firebaseFunctions.saveFileLocally(fileType, pickedPath);

  //           if (savedPath != null) {
  //             setState(() {
  //               if (fileType == "profilePhoto") _profilePhoto = savedPath;
  //               if (fileType == "govId") _govId = savedPath;
  //               if (fileType == "driverLicense") _driverLicense = savedPath;
  //             });
  //           }
  //         }
  //       },
  //       child: Text(filePath != null ? "Replace" : "Upload"),
  //     ),
  //   );
  // }


  // Widget _buildFileUploadSection(String label, String? filePath, String fileType) {
  //   return ListTile(
  //     title: Text(label),
  //     subtitle: filePath != null ? Text("Uploaded") : Text("Not uploaded"),
  //     trailing: ElevatedButton(
  //       onPressed: () => _pickFile(fileType),
  //       child: Text(filePath != null ? "Replace" : "Upload"),
  //     ),
  //   );
  // }

  /// Builds a scrollable list of family members
  Widget _buildFamilyList(List<Map<String, dynamic>> familyMembers) {
    return Column(
      children: familyMembers.map((member) {
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: member['profilePhoto'] != null ? FileImage(File(member['profilePhoto'])) : null,
              child: member['profilePhoto'] == null ? Icon(Icons.person) : null,
            ),
            title: Text(member['fullName']),
            subtitle: Text(member['isAdult']
                ? member['relationToChild'] // Show relation for adults
                : "Age: ${_calculateAge(member['dateOfBirth'])}"), // Show age for children
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.edit), onPressed: () => _editFamilyMember(member)), // Edit Button
                IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteFamilyMember(member['id'])), // Delete Button
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Helper function to calculate age from Firestore Timestamp
  int _calculateAge(Timestamp dobTimestamp) {
    DateTime birthDate = dobTimestamp.toDate(); // Convert Firestore Timestamp to DateTime
    DateTime today = DateTime.now();

    int age = today.year - birthDate.year;
    
    // Adjust age if birthday hasn't occurred yet this year
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /// Builds a scrollable list of vehicles
  Widget _buildVehicleList() {
    return Column(
      children: _vehicles.map((vehicle) {
        print("Building vehicle list: $vehicle"); // 🔍 Debugging Output
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            leading: vehicle['vehicleImage'] != null
                ? Image.file(File(vehicle['vehicleImage']), width: 50, height: 50, fit: BoxFit.cover)
                : Icon(Icons.directions_car, size: 50),
            title: Text("${vehicle['vehicleMake']} ${vehicle['vehicleModel']}"),
            subtitle: Text("License No: ${vehicle['vehicleLicenseNumber']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // IconButton(icon: Icon(Icons.edit), onPressed: () => _manageVehicle(vehicleData: vehicle)), // Edit Button
              
                IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  if (vehicle.containsKey("id")) {
                    _manageVehicle(vehicleData: vehicle);
                  } else {
                    print("Error: Vehicle data missing 'id' field!"); // 🔍 Debug
                  }
                },
              ),


                IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteVehicle(vehicle['id'])), // Delete Button
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}