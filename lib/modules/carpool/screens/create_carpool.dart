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

  // Toggle for Recurring Carpool
  // Recurring Carpool
  bool _isRecurring = false;
  String _recurringType = "Daily"; // Default value
  DateTime? _recurringStartDate;
  DateTime? _recurringEndDate;
  List<String> _selectedDays = []; // For Weekly
  List<int> _selectedDates = []; // For Monthly
  List<DateTime> _customDates = []; // For Custom Recurrence

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
    });
  }


  /// Opens a date picker & updates the selected date
  Future<void> _pickDate({required bool isStartDate}) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _selectedDate = pickedDate;
        } else {
          _recurringEndDate = pickedDate;
        }
      });
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
    }
  }

  /// Handles form submission for creating a carpool
  void _createCarpool() {
    if (_carpoolNameController.text.isEmpty ||
        _routeStartController.text.isEmpty ||
        _routeEndController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedVehicle == null ||
        _selectedDriver == null ||
        _selectedOwner == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all required fields!")));
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

    Map<String, dynamic> carpoolData = {
      "carpoolName": _carpoolNameController.text.trim(),
      "carpoolRouteStart": _routeStartController.text.trim(),
      "carpoolRouteEnd": _routeEndController.text.trim(),
      "carpoolDate": carpoolDate,
      "carpoolTime": carpoolTime,
      "carpoolIsRecurring": _isRecurring,
      "carpoolRecurringType": _isRecurring ? _recurringType : null,
      "carpoolRecurringDays": _recurringType == "Weekly" ? _selectedDays : null,
      "carpoolRecurringDates": _recurringType == "Monthly" ? _selectedDates : null,
      "carpoolCustomDates": _recurringType == "Custom" ? _customDates.map((d) => d.toString()).toList() : null,
      "carpoolStartDate": _recurringStartDate != null ? Timestamp.fromDate(_recurringStartDate!) : null,
      "carpoolEndDate": _recurringEndDate != null ? Timestamp.fromDate(_recurringEndDate!) : null,
      "carpoolVehicleId": _selectedVehicle,
      "carpoolOwnerId": _selectedOwner,
      "carpoolDriverId": _selectedDriver,
      "carpoolCapacity": int.parse(_capacityController.text),
      "carpoolReturnTrip": _hasReturnTrip,
      "carpoolReturnStayOnLocation": _hasReturnTrip ? _stayOnLocation : null,
      "carpoolStatus": "Available",
    };

    print("Carpool Created: $carpoolData");
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

            // Date & Time Pickers
            // _buildDateTimePicker("Select Date", _selectedDate, _pickDate),
            _buildDateTimePicker("Select Start Date", _selectedDate, () => _pickDate(isStartDate: true)),
            _buildDateTimePicker("Select End Date", _recurringEndDate, () => _pickDate(isStartDate: false)),

            _buildDateTimePicker("Select Time", _selectedTime, _pickTime),

            // Recurring Carpool Options
            SwitchListTile(
              title: Text("Recurring Carpool"),
              value: _isRecurring,
              onChanged: (value) => setState(() => _isRecurring = value),
            ),

            if (_isRecurring)
              Column(
                children: [
                  DropdownButtonFormField(
                    value: _recurringType,
                    items: ["Daily", "Weekly", "Monthly", "Custom"].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) => setState(() => _recurringType = value as String),
                    decoration: InputDecoration(labelText: "Recurring Type"),
                  ),
                ],
              ),

            // Vehicle Selection
            _buildDropdown("Select Vehicle", _selectedVehicle, _vehicles, "vehicleId", "vehicleMake"),

            // Owner Selection
            _buildDropdown("Carpool Owner", _selectedOwner, _adults, "id", "fullName"),

            // Driver Selection
            _buildDropdown("Driver", _selectedDriver, _adults, "id", "fullName"),

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
  Widget _buildDropdown(String label, String? selected, List<Map<String, dynamic>> items, String idField, String displayField) {
    return DropdownButtonFormField(
      value: selected,
      items: items.map((item) => DropdownMenuItem(value: item[idField], child: Text(item[displayField]))).toList(),
      onChanged: (value) => setState(() => selected = value as String?),
      decoration: InputDecoration(labelText: label),
    );
  }
}
