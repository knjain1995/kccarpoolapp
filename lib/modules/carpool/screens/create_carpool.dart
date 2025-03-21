// 📌 Filename: create_carpool.dart
// 📂 Location: lib/modules/carpool/screens/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';
import 'package:file_picker/file_picker.dart';

/// Screen for Creating a New Carpool
class CreateCarpoolScreen extends StatefulWidget {
  @override
  _CreateCarpoolScreenState createState() => _CreateCarpoolScreenState();
}

class _CreateCarpoolScreenState extends State<CreateCarpoolScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();

  // Controllers for input fields
  final TextEditingController _carpoolNameController = TextEditingController();
  final TextEditingController _routeStartController = TextEditingController();
  final TextEditingController _routeEndController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController(text: "4");

  // Date & Time Selection
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Vehicle & Driver Selection
  String? _selectedVehicle;
  String? _selectedOwner;
  String? _selectedDriver;
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _adults = []; // Account owner & adults in the family

  // Return Trip Options
  bool _hasReturnTrip = false;
  bool _stayOnLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user’s vehicles & family details
  }

  /// Fetches the user's vehicles & family members (for selecting driver & owner)
  Future<void> _fetchUserData() async {
    var userData = await _firebaseFunctions.getUserData();
    var familyMembers = await _firebaseFunctions.getFamilyMembers();
    var vehicleData = await _firebaseFunctions.getVehicles();

     // 🔄 If date/time is selected, check availability for each vehicle
    if (_selectedDate != null && _selectedTime != null) {
      for (var vehicle in vehicleData) {
        bool available = await _firebaseFunctions.isVehicleAvailable(
          vehicleId: vehicle['id'],
          carpoolDate: Timestamp.fromDate(_selectedDate!),
          carpoolTime: Timestamp.fromDate(DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          )),
        );
        vehicle['isAvailable'] = available; // 🔹 Tag vehicle as available/unavailable
      }
    } else {
      // If no time/date selected yet, assume all available
      for (var vehicle in vehicleData) {
        vehicle['isAvailable'] = true;
      }
    }

    setState(() {
      _selectedOwner = userData?["id"]; // Default owner should be account owner's ID

      // ✅ Ensure _adults contains both the account owner and adult family members
      _adults = familyMembers.where((member) => member["isAdult"] == true).toList();

      if (userData != null) {
        _adults.insert(0, {
          "id": userData["id"], // ✅ Use user ID instead of fullName
          "fullName": userData["fullName"],
          "email": userData["email"],
          "phoneNumber": userData["phoneNumber"],
          "isAdult": true, // ✅ Ensure account owner is treated as an adult
          "driverLicense": userData["driverLicense"] ?? "", // ✅ Handle driver license for selection
        });
      }

      _vehicles = vehicleData;

      print("Account Owner ID: ${userData?['id']}");
      print("Adults List: $_adults");
      print("Vehicles List: $_vehicles");
    });
  }

  /// Opens a date picker & updates the selected date
  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });

      // 🔄 Re-fetch vehicles to update their availability
      await _fetchUserData();
    }
  }

  /// Opens a time picker & updates the selected time
  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });

      // 🔄 Re-fetch vehicles to update their availability
      await _fetchUserData();
    }
  }

  /// Validates the input before saving to Firestore
  bool _validateCarpoolInputs() {
    if (_carpoolNameController.text.isEmpty ||
        _routeStartController.text.isEmpty ||
        _routeEndController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedVehicle == null ||
        _selectedDriver == null ||
        _selectedOwner == null) {
      return false;
    }
    return true;
  }

  /// Handles form submission for creating a carpool
  void _createCarpool() async {
    if (!_validateCarpoolInputs()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all required fields!")));
      return;
    }

    // ✅ Safety net check before creation (even if dropdown disables vehicle)
    bool stillAvailable = await _firebaseFunctions.isVehicleAvailable(
      vehicleId: _selectedVehicle!,
      carpoolDate: Timestamp.fromDate(_selectedDate!),
      carpoolTime: Timestamp.fromDate(DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      )),
    );

    if (!stillAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Selected vehicle is no longer available.")));
      return;
    }

    // Convert DateTime to Firestore Timestamp
    Timestamp carpoolDate = Timestamp.fromDate(_selectedDate!);
    Timestamp carpoolTime = Timestamp.fromDate(DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    ));

    try {
      _firebaseFunctions.createCarpool(
        carpoolName: _carpoolNameController.text.trim(),
        carpoolRouteStart: _routeStartController.text.trim(),
        carpoolRouteEnd: _routeEndController.text.trim(),
        carpoolDate: carpoolDate,
        carpoolTime: carpoolTime,
        carpoolVehicleId: _selectedVehicle!,
        carpoolOwnerId: _selectedOwner!,
        carpoolDriverId: _selectedDriver!,
        carpoolCapacity: int.parse(_capacityController.text),
        carpoolReturnTrip: _hasReturnTrip,
        carpoolReturnStayOnLocation: _hasReturnTrip ? _stayOnLocation : null,
      );

      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Carpool Created Successfully!")));

      // ✅ Navigate back to Home Screen
      Navigator.of(context).pop(); 
      } catch (e) {
        // ✅ Handle errors
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error creating carpool: $e")));
      }
  }

  
  /// Generic text field builder
  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(controller: controller, decoration: InputDecoration(labelText: label), keyboardType: keyboardType),
    );
  }

  /// Date-Time Picker UI
  Widget _buildDateTimePicker(String label, dynamic value, VoidCallback onTap) {
    return ListTile(
      title: Text(value != null ? value.toString() : label),
      trailing: Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }

  /// Dropdown builder
  Widget _buildDropdown(
  String label,
  String? selectedValue,
  List<Map<String, dynamic>> items,
  String idField,
  String displayField,
  Function(String?) onChangedCallback, {
  bool showAvailabilityIcon = false, // ✅ NEW optional flag
  }) {
    return DropdownButtonFormField(
      value: selectedValue,
      items: items.map((item) {
        bool isDisabled = item['isAvailable'] == false;

        return DropdownMenuItem(
          value: item[idField],
          enabled: !isDisabled, // 🔹 Disable item if unavailable
          child: Row(
            children: [
              if (showAvailabilityIcon && isDisabled)
                Icon(Icons.block, color: Colors.redAccent, size: 16),
              if (showAvailabilityIcon && isDisabled) SizedBox(width: 6),
              Text(
                item[displayField] + (showAvailabilityIcon && isDisabled ? " (Unavailable)" : ""),
                style: TextStyle(
                  color: isDisabled ? Colors.grey : null,
                  fontStyle: showAvailabilityIcon && isDisabled ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          onChangedCallback(value as String?);
        });
      },
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Carpool")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField("Carpool Name", _carpoolNameController),
            _buildTextField("Start Location", _routeStartController),
            _buildTextField("End Location", _routeEndController),

            _buildDateTimePicker("Select Date", _selectedDate, _pickDate),
            _buildDateTimePicker("Select Time", _selectedTime, _pickTime),

            // // Vehicle Selection
            // _buildDropdown("Select Vehicle", _selectedVehicle, _vehicles, "vehicleId", "vehicleMake"),

            // // Owner Selection
            // _buildDropdown("Carpool Owner", _selectedOwner, _adults, "id", "fullName"),

            // // Driver Selection
            // _buildDropdown("Driver", _selectedDriver, _adults, "id", "fullName")

            // Owner Dropdown
            _buildDropdown(
              "Carpool Owner",
              _selectedOwner,
              _adults,
              "id",
              "fullName",
              (value) => _selectedOwner = value, // 🔹 Updates _selectedOwner
            ),

            // Driver Dropdown
            _buildDropdown(
              "Driver",
              _selectedDriver,
              _adults,
              "id",
              "fullName",
              (value) => _selectedDriver = value, // 🔹 Updates _selectedDriver
            ),

            
            // Vehicle Dropdown
            _buildDropdown(
              "Select Vehicle",
              _selectedVehicle,
              _vehicles,
              "id",
              "vehicleMake",
              (value) => _selectedVehicle = value,
              showAvailabilityIcon: true, // ✅ Enable icon only for vehicles
            ),

            // Carpool Capacity
            _buildTextField("Capacity", _capacityController, keyboardType: TextInputType.number),

            // Return Trip Toggle
            SwitchListTile(
              title: Text("Include Return Trip"),
              value: _hasReturnTrip,
              onChanged: (value) => setState(() => _hasReturnTrip = value),
            ),

            if (_hasReturnTrip)
              SwitchListTile(
                title: Text("Driver Stays on Location"),
                value: _stayOnLocation,
                onChanged: (value) => setState(() => _stayOnLocation = value),
              ),

            SizedBox(height: 20),
            ElevatedButton(onPressed: _createCarpool, child: Text("Create Carpool")),
          ],
        ),
      ),
    );
  }
}
