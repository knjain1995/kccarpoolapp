import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';
import 'package:file_picker/file_picker.dart';

/// The Manage Vehicles screen allows users to add, edit, and delete vehicles.
class ManageVehiclesScreen extends StatefulWidget {
  @override
  _ManageVehiclesScreenState createState() => _ManageVehiclesScreenState();
}

class _ManageVehiclesScreenState extends State<ManageVehiclesScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();

  List<Map<String, dynamic>> _vehicles = []; // Stores the list of vehicles
  bool _isLoading = true; // Tracks loading state

  // Controllers for input fields
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleYearController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  final TextEditingController _vehicleLicenseNumberController = TextEditingController();
  final TextEditingController _vehicleRegistrationNumberController = TextEditingController();
  final TextEditingController _seatingCapacityController = TextEditingController();

  // File paths for uploads
  String? _vehicleImage;
  String? _registrationDocument;
  String? _editingVehicleId; // Stores the ID of the vehicle being edited

  @override
  void initState() {
    super.initState();
    _loadVehicles(); // Load vehicles from Firestore
  }

  /// Fetches the user's vehicles from Firestore
  Future<void> _loadVehicles() async {
    List<Map<String, dynamic>> vehicleData = await _firebaseFunctions.getVehicles();
    setState(() {
      _vehicles = vehicleData;
      _isLoading = false;
    });
  }

  /// Opens a file picker and saves the selected file locally
  Future<void> _pickFile(String fileType) async {
    String? savedPath = await _firebaseFunctions.saveFileLocally(fileType);
    if (savedPath != null) {
      setState(() {
        if (fileType == "vehicleImage") _vehicleImage = savedPath;
        if (fileType == "registrationDocument") _registrationDocument = savedPath;
      });
    }
  }

  /// Saves or updates the vehicle in Firestore
  Future<void> _saveVehicle() async {
    if (_vehicleMakeController.text.isEmpty ||
        _vehicleModelController.text.isEmpty ||
        _vehicleYearController.text.isEmpty ||
        _vehicleColorController.text.isEmpty ||
        _vehicleLicenseNumberController.text.isEmpty ||
        _vehicleRegistrationNumberController.text.isEmpty ||
        _seatingCapacityController.text.isEmpty ||
        _vehicleImage == null ||
        _registrationDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all required fields!")));
      return;
    }

    if (_editingVehicleId == null) {
      // Adding a new vehicle
      await _firebaseFunctions.addVehicle(
        vehicleMake: _vehicleMakeController.text.trim(),
        vehicleModel: _vehicleModelController.text.trim(),
        vehicleYear: int.parse(_vehicleYearController.text.trim()),
        vehicleColor: _vehicleColorController.text.trim(),
        vehicleLicenseNumber: _vehicleLicenseNumberController.text.trim(),
        vehicleRegistrationNumber: _vehicleRegistrationNumberController.text.trim(),
        seatingCapacity: int.parse(_seatingCapacityController.text.trim()),
        vehicleImage: _vehicleImage!,
        registrationDocument: _registrationDocument!,
      );
    } else {
      // Updating an existing vehicle
      await _firebaseFunctions.updateVehicle(
        vehicleId: _editingVehicleId!,
        vehicleMake: _vehicleMakeController.text.trim(),
        vehicleModel: _vehicleModelController.text.trim(),
        vehicleYear: int.parse(_vehicleYearController.text.trim()),
        vehicleColor: _vehicleColorController.text.trim(),
        vehicleLicenseNumber: _vehicleLicenseNumberController.text.trim(),
        vehicleRegistrationNumber: _vehicleRegistrationNumberController.text.trim(),
        seatingCapacity: int.parse(_seatingCapacityController.text.trim()),
        vehicleImage: _vehicleImage!,
        registrationDocument: _registrationDocument!,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vehicle Saved!")));
    _clearFields();
    _loadVehicles(); // Refresh list
  }

  /// Deletes a vehicle after confirmation
  void _deleteVehicle(String vehicleId) async {
    bool confirmDelete = await _showDeleteConfirmationDialog();
    if (confirmDelete) {
      await _firebaseFunctions.deleteVehicle(vehicleId);
      _loadVehicles(); // Refresh list after deletion
    }
  }

  /// Shows a confirmation dialog before deleting a vehicle
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

  /// Clears form fields after successful save
  void _clearFields() {
    setState(() {
      _vehicleMakeController.clear();
      _vehicleModelController.clear();
      _vehicleYearController.clear();
      _vehicleColorController.clear();
      _vehicleLicenseNumberController.clear();
      _vehicleRegistrationNumberController.clear();
      _seatingCapacityController.clear();
      _vehicleImage = null;
      _registrationDocument = null;
      _editingVehicleId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Vehicles")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  /// Form for adding/editing vehicles
                  _buildTextField("Vehicle Make", _vehicleMakeController),
                  _buildTextField("Vehicle Model", _vehicleModelController),
                  _buildTextField("Vehicle Year", _vehicleYearController),
                  _buildTextField("Vehicle Color", _vehicleColorController),
                  _buildTextField("License Plate", _vehicleLicenseNumberController),
                  _buildTextField("Registration Number", _vehicleRegistrationNumberController),
                  _buildTextField("Seating Capacity", _seatingCapacityController),

                  /// Upload Sections
                  _buildFileUploadSection("Vehicle Image", _vehicleImage, "vehicleImage"),
                  _buildFileUploadSection("Registration Document", _registrationDocument, "registrationDocument"),

                  SizedBox(height: 20),
                  ElevatedButton(onPressed: _saveVehicle, child: Text("Save Vehicle")),
                  SizedBox(height: 20),

                  /// Vehicle List
                  Text("Your Vehicles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ..._vehicles.map((vehicle) => _buildVehicleTile(vehicle)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

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

    /// Builds a vehicle list tile showing vehicle details with edit & delete buttons
  Widget _buildVehicleTile(Map<String, dynamic> vehicleData) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: vehicleData['vehicleImage'] != null
              ? FileImage(File(vehicleData['vehicleImage']))
              : null,
          child: vehicleData['vehicleImage'] == null
              ? Icon(Icons.directions_car, size: 30)
              : null,
        ),
        title: Text("${vehicleData['vehicleMake']} ${vehicleData['vehicleModel']}"),
        subtitle: Text("Year: ${vehicleData['vehicleYear']} | Seats: ${vehicleData['seatingCapacity']}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editVehicle(vehicleData),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteVehicle(vehicleData['id']),
            ),
          ],
        ),
      ),
    );
  }
}
