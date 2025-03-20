// Filename: manage_vehicles.dart  Location: lib/modules/profile/screens/
import 'dart:io'; // Required for handling local file storage
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart'; // Firebase interaction class
import 'package:file_picker/file_picker.dart'; // Used for selecting local files

/// Screen for adding and editing vehicles
class ManageVehiclesScreen extends StatefulWidget {
  final Map<String, dynamic>? vehicleData; // Optional vehicle data for editing

  ManageVehiclesScreen({this.vehicleData});

  @override
  _ManageVehiclesScreenState createState() => _ManageVehiclesScreenState();
}

class _ManageVehiclesScreenState extends State<ManageVehiclesScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions(); // Firebase interaction instance

  // Controllers for text fields
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _registrationNumberController = TextEditingController();
  final TextEditingController _seatingCapacityController = TextEditingController();

  // Image paths for vehicle & registration document
  String? _vehicleImage;
  String? _registrationDocument;
  String? _vehicleId; // Used when editing

  bool _isEditing = false; // Tracks if the form is for editing

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      
      if (args is Map<String, dynamic> && args.containsKey("id")) { // ✅ Ensure arguments exist
        print("🚀 Received vehicleData: $args"); // Debugging Output
        
        setState(() {
          _vehicleId = args["id"]; // ✅ Store vehicle ID
          _isEditing = true; // ✅ Enable editing mode
          _makeController.text = args["vehicleMake"] ?? "";
          _modelController.text = args["vehicleModel"] ?? "";
          _yearController.text = args["vehicleYear"]?.toString() ?? "";
          _colorController.text = args["vehicleColor"] ?? "";
          _licenseNumberController.text = args["vehicleLicenseNumber"] ?? "";
          _registrationNumberController.text = args["vehicleRegistrationNumber"] ?? "";
          _seatingCapacityController.text = args["seatingCapacity"]?.toString() ?? "";
          _vehicleImage = args["vehicleImage"];
          _registrationDocument = args["registrationDocument"];
        });
      } else {
        print("🚨 vehicleData is NULL or missing 'id' field! Editing disabled."); // Debug
      }
    });
  }

  /// If editing, load vehicle data into form fields
  void _initializeForm() {
    if (widget.vehicleData != null && widget.vehicleData!.containsKey("id")) {
      print("Setting _isEditing to true, vehicleId: ${widget.vehicleData!["id"]}");
      setState(() {
        _isEditing = true;
        _vehicleId = widget.vehicleData!["id"]; // ✅ Ensure _vehicleId is assigned
        _makeController.text = widget.vehicleData!["vehicleMake"];
        _modelController.text = widget.vehicleData!["vehicleModel"];
        _yearController.text = widget.vehicleData!["vehicleYear"].toString();
        _colorController.text = widget.vehicleData!["vehicleColor"];
        _licenseNumberController.text = widget.vehicleData!["vehicleLicenseNumber"];
        _registrationNumberController.text = widget.vehicleData!["vehicleRegistrationNumber"];
        _seatingCapacityController.text = widget.vehicleData!["seatingCapacity"].toString();
        _vehicleImage = widget.vehicleData!["vehicleImage"];
        _registrationDocument = widget.vehicleData!["registrationDocument"];
      });
    }
  }

  /// Opens file picker and saves selected file locally
  Future<void> _pickFile(String fileType) async {
    String? savedPath = await _firebaseFunctions.saveFileLocally(fileType);
    if (savedPath != null) {
      setState(() {
        if (fileType == "vehicleImage") _vehicleImage = savedPath;
        if (fileType == "registrationDocument") _registrationDocument = savedPath;
      });
    }
  }

  /// Saves or updates vehicle data in Firestore
  Future<void> _saveVehicle() async {
    // Validate required fields
    if (_makeController.text.isEmpty ||
        _modelController.text.isEmpty ||
        _yearController.text.isEmpty ||
        _licenseNumberController.text.isEmpty ||
        _registrationNumberController.text.isEmpty ||
        _seatingCapacityController.text.isEmpty ||
        _vehicleImage == null ||
        _registrationDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all required fields!")));
      return;
    }

    // Convert fields to correct types
    int year = int.tryParse(_yearController.text.trim()) ?? 0;
    int seatingCapacity = int.tryParse(_seatingCapacityController.text.trim()) ?? 0;

    Map<String, dynamic> vehicleData = {
      "vehicleMake": _makeController.text.trim(),
      "vehicleModel": _modelController.text.trim(),
      "vehicleYear": year,
      "vehicleColor": _colorController.text.trim(),
      "vehicleLicenseNumber": _licenseNumberController.text.trim(),
      "vehicleRegistrationNumber": _registrationNumberController.text.trim(),
      "seatingCapacity": seatingCapacity,
      "vehicleImage": _vehicleImage!,
      "registrationDocument": _registrationDocument!,
    };

    if (_isEditing) {
      // ✅ Ensure we pass the existing vehicleId for an update
      await _firebaseFunctions.updateVehicle(
        vehicleId: _vehicleId!,
        vehicleData: vehicleData,
      );
    } else {
      // ✅ Add new vehicle
      await _firebaseFunctions.addVehicle(vehicleData);
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? "Vehicle Updated!" : "Vehicle Added!")));
    Navigator.pop(context); // Return to profile screen
  }

  /// Deletes vehicle after confirmation
  Future<void> _deleteVehicle() async {
    bool confirmDelete = await _showDeleteConfirmationDialog();
    if (confirmDelete && _vehicleId != null) {
      await _firebaseFunctions.deleteVehicle(_vehicleId!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vehicle Deleted!")));
      Navigator.pop(context);
    }
  }

  /// Confirmation dialog for deletion
  Future<bool> _showDeleteConfirmationDialog() async {
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

  /// Builds a text field
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: label.contains("Year") || label.contains("Capacity") ? TextInputType.number : TextInputType.text,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Vehicle" : "Add Vehicle"),
        actions: _isEditing
            ? [
                IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: _deleteVehicle),
              ]
            : [],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField("Vehicle Make", _makeController),
            _buildTextField("Vehicle Model", _modelController),
            _buildTextField("Vehicle Year", _yearController),
            _buildTextField("Vehicle Color", _colorController),
            _buildTextField("License Number", _licenseNumberController),
            _buildTextField("Registration Number", _registrationNumberController),
            _buildTextField("Seating Capacity", _seatingCapacityController),

            SizedBox(height: 20),

            /// Vehicle Image Upload
            _buildFileUploadSection("Vehicle Image", _vehicleImage, "vehicleImage"),

            /// Registration Document Upload
            _buildFileUploadSection("Registration Document", _registrationDocument, "registrationDocument"),

            SizedBox(height: 20),

            /// Save Button
            ElevatedButton(onPressed: _saveVehicle, child: Text(_isEditing ? "Update Vehicle" : "Save Vehicle")),
          ],
        ),
      ),
    );
  }
}
