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

  Map<String, dynamic>? _editingCarpool; // Will store carpool data for editing
  String? _carpoolId; // Firestore document ID
  bool _isEditing = false; // Whether we're editing an existing carpool

  // 👨‍👩‍👧‍👦 Stores selected participant IDs for this carpool
  List<String> _carpoolParticipants = [];

  // Controllers for input fields
  final TextEditingController _carpoolNameController = TextEditingController();
  final TextEditingController _routeStartController = TextEditingController();
  final TextEditingController _routeEndController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController(text: "4");
  Map<String, dynamic>? _loggedInUserData;

  // Date & Time Selection
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Vehicle & Driver Selection
  String? _selectedVehicle;
  String? _selectedOwner;
  String? _selectedDriver;
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _adults = []; // Account owner & adults in the family
  List<Map<String, dynamic>> _familyMembers = []; // 🔹 All family members for participant selection
  List<String> _selectedParticipants = []; // 🔹 Stores selected participant IDs
  int? _vehicleMaxCapacity; // Holds the selected vehicle’s seatingCapacity

  // Return Trip Options
  bool _hasReturnTrip = false;
  bool _stayOnLocation = false;

  @override
  void initState() {
    super.initState();

    // Ensures we access route arguments only after widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 🔄 Check if carpool data is passed for editing
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

      if (args != null && args.containsKey('carpoolData')) {
        _editingCarpool = args['carpoolData']; // 📦 Store the carpool data
        _carpoolId = _editingCarpool!['carpoolId']; // 🆔 Save Firestore doc ID
        _isEditing = true; // ✅ We're in edit mode

        // ⬅️ Prefill form fields using the existing carpool data
        _preFillFormWithCarpoolData(_editingCarpool!);
      }

      _fetchUserData(); // 🔄 Always fetch vehicles & adults
    });
  }

  /// Fetches the user's vehicles & family members (for selecting driver & owner)
  Future<void> _fetchUserData() async {
    var userData = await _firebaseFunctions.getUserData();
    var familyMembers = await _firebaseFunctions.getFamilyMembers();
    var vehicleData = await _firebaseFunctions.getVehicles();
    _loggedInUserData = await _firebaseFunctions.getUserData();

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

      // ✅ If in edit mode and this vehicle is the selected one, allow it
      if (_isEditing && vehicle['id'] == _selectedVehicle) {
        available = true;
      }

      vehicle['isAvailable'] = available; // 🔹 Tag vehicle as available/unavailable
      }
    } else {
      // If no time/date selected yet, assume all available
      for (var vehicle in vehicleData) {
        vehicle['isAvailable'] = true;
      }
    }

    setState(() {
      _selectedOwner = _loggedInUserData?["id"];
      print("Selected Owner:");
      print(_selectedOwner);

      // add all adults of the family
      _adults = familyMembers.where((member) => member["isAdult"] == true).toList();

      // add all members of the family
      _familyMembers.clear(); // ✅ Prevent duplicates
      _familyMembers.addAll(familyMembers);

      _adults.clear(); // ✅ Clear previous data before adding adults again
      _adults = familyMembers.where((member) => member["isAdult"] == true).toList();

      _familyMembers.removeWhere((m) => m["id"] == userData?["id"]); // prevent duplicate if already added
      _adults.removeWhere((m) => m["id"] == userData?["id"]);        // prevent duplicate if already added

      // assign all vehicle data to vehicles variables
      _vehicles = vehicleData;

      if (userData != null) {
      // 🔹 Include account owner in _adults for driver selectionZ
        _adults.insert(0, {
          "id": userData["id"],
          "fullName": userData["fullName"],
          "email": userData["email"],
          "phoneNumber": userData["phoneNumber"],
          "isAdult": true,
          "driverLicense": userData["driverLicense"] ?? "",
          "profilePhoto": userData["profilePhoto"],
        });

      // 🔹 Include account owner in _familyMembers for participant selection
         _familyMembers.add({
          "id": userData["id"],
          "fullName": userData["fullName"],
          "email": userData["email"],
          "phoneNumber": userData["phoneNumber"],
          "isAdult": true,
          "driverLicense": userData["driverLicense"] ?? "",
          "profilePhoto": userData["profilePhoto"],
        });
      }

      // 👇 Smart Default: Auto-select the only driver if only one exists
      if (_adults.length == 1) {
        _selectedDriver = _adults.first["id"];
      }

      if (_isEditing && _selectedVehicle != null) {
        _onVehicleSelected(_selectedVehicle!); // ✅ Ensure vehicle max capacity is set for validation
      }
    });
  }

  // ⬅️ Called from initState when editing an existing carpool
  void _preFillFormWithCarpoolData(Map<String, dynamic> data) {
    // 📝 Pre-fill all text controllers
    _carpoolNameController.text = data['carpoolName'] ?? '';
    _routeStartController.text = data['carpoolRouteStart'] ?? '';
    _routeEndController.text = data['carpoolRouteEnd'] ?? '';
    _capacityController.text = (data['carpoolCapacity'] ?? 0).toString();

    // 🚗 Pre-fill dropdown values
    _selectedVehicle = data['carpoolVehicleId'];
    _selectedOwner = data['carpoolOwnerId'];
    _selectedDriver = data['carpoolDriverId'];

    // 👨‍👩‍👧‍👦 Pre-fill list of participant IDs
    // 👨‍👩‍👧‍👦 Pre-fill list of participant IDs (excluding driver)
    _carpoolParticipants = List<String>.from(data['carpoolParticipants'] ?? []);
    _selectedParticipants = _carpoolParticipants
      .where((id) => id != data['carpoolDriverId'])
      .toList(); // ✅ Only non-driver participants go into the checkboxes

    // 🔄 Return trip toggles
    _hasReturnTrip = data['carpoolReturnTrip'] ?? false;
    _stayOnLocation = data['carpoolReturnStayOnLocation'] ?? false;

    // 📅 Parse Timestamp objects into DateTime/TimeOfDay
    Timestamp carpoolDate = data['carpoolDate'];
    Timestamp carpoolTime = data['carpoolTime'];

    _selectedDate = carpoolDate.toDate();
    _selectedTime = TimeOfDay.fromDateTime(carpoolTime.toDate());

    // 🔁 Trigger capacity and vehicle availability logic for the selected vehicle
    if (_selectedVehicle != null) {
      _onVehicleSelected(_selectedVehicle!);
    }
  }

  // 🔄 Called when a vehicle is selected or prefilled to get max seating capacity
  void _onVehicleSelected(String vehicleId) {
    final vehicleData = _vehicles.firstWhere(
      (v) => v['id'] == vehicleId,
      orElse: () => {},
    );

    if (vehicleData.isNotEmpty && vehicleData['seatingCapacity'] != null) {
      _vehicleMaxCapacity = vehicleData['seatingCapacity'];

      // 🧠 If user hasn't entered a capacity yet, set it to vehicle max
      if (_capacityController.text.isEmpty || int.tryParse(_capacityController.text) == null) {
        _capacityController.text = _vehicleMaxCapacity.toString();
      }
    }
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

  /// 📅 Opens a time picker & updates the selected time
  Future<void> _pickTime() async {
    // 🕒 Get the current time
    TimeOfDay now = TimeOfDay.now();

    // 🔄 Round minutes to nearest 15
    int roundedMinutes = (now.minute / 15).round() * 15;

    if (roundedMinutes == 60) {
      // ➕ If 60, roll over to next hour
      now = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
    } else {
      now = TimeOfDay(hour: now.hour, minute: roundedMinutes);
    }

    // 📅 Show the time picker
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: now, // 🧠 Use rounded time here
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });

      // 🔄 Re-fetch vehicles to update availability
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

  /// 🔄 Resets all form fields (used by the Clear button)
  void _resetCarpoolForm() {
    setState(() {
      _carpoolNameController.clear();
      _routeStartController.clear();
      _routeEndController.clear();
      _capacityController.text = "4"; // Default capacity

      _selectedDate = null;
      _selectedTime = null;
      _selectedVehicle = null;
      _selectedDriver = null;
      _vehicleMaxCapacity = null;
      _selectedParticipants.clear();
      _carpoolParticipants.clear();
      _hasReturnTrip = false;
      _stayOnLocation = false;

      if (!_isEditing) {
        _carpoolId = null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Form cleared.")),
    );
  }

  /// Handles form submission for creating a carpool
  void _createCarpool() async {
    if (!_validateCarpoolInputs()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all required fields!")));
      return;
    }

    // 🚫 Check if entered capacity exceeds max vehicle capacity
    if (_vehicleMaxCapacity != null &&
        int.tryParse(_capacityController.text.trim())! > _vehicleMaxCapacity!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Capacity cannot exceed vehicle’s max capacity ($_vehicleMaxCapacity).")),
      );
      return;
    }

    // ✅ Safety net check before creation (even if dropdown disables vehicle)
    // 🔓 Allow vehicle if it's already being used by the carpool being edited
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

    // 🔓 Allow vehicle if it's already being used by the carpool being edited
    if (_isEditing && _selectedVehicle == _editingCarpool?['carpoolVehicleId']) {
      stillAvailable = true;
    }

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

    // 👥 Prepare carpoolParticipants (driver + selected participants)
    List<String> allParticipants = [_selectedDriver!, ..._selectedParticipants.toSet()];

    // 🔍 Participant Count Validation
    int enteredCapacity = int.tryParse(_capacityController.text.trim()) ?? 0;
    int participantCount = _carpoolParticipants.length;

    // Exclude driver from participant list (just in case)
    if (_carpoolParticipants.contains(_selectedDriver)) {
      participantCount -= 1;
    }

    if (participantCount > (enteredCapacity - 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Too many participants selected for the available seats!")),
      );
      return; // ❌ Stop submission
    }

    try {
      if (_isEditing && _carpoolId != null) {
        // 🔄 UPDATE EXISTING CARPOOL
        await _firebaseFunctions.updateCarpool(
          carpoolId: _carpoolId!,
          updatedData: {
            "carpoolName": _carpoolNameController.text.trim(),
            "carpoolRouteStart": _routeStartController.text.trim(),
            "carpoolRouteEnd": _routeEndController.text.trim(),
            "carpoolDate": carpoolDate,
            "carpoolTime": carpoolTime,
            "carpoolVehicleId": _selectedVehicle!,
            "carpoolOwnerId": _selectedOwner!,
            "carpoolDriverId": _selectedDriver!,
            "carpoolParticipants": allParticipants,
            "carpoolCapacity": int.parse(_capacityController.text),
            "carpoolReturnTrip": _hasReturnTrip,
            "carpoolReturnStayOnLocation": _hasReturnTrip ? _stayOnLocation : null,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Carpool '${_carpoolNameController.text.trim()}' updated successfully!")),
        );
      } else {
        // 🆕 CREATE NEW CARPOOL
        await _firebaseFunctions.createCarpool(
          carpoolName: _carpoolNameController.text.trim(),
          carpoolRouteStart: _routeStartController.text.trim(),
          carpoolRouteEnd: _routeEndController.text.trim(),
          carpoolDate: carpoolDate,
          carpoolTime: carpoolTime,
          carpoolVehicleId: _selectedVehicle!,
          carpoolOwnerId: _selectedOwner!,
          carpoolDriverId: _selectedDriver!,
          carpoolParticipants: allParticipants,
          carpoolCapacity: int.parse(_capacityController.text),
          carpoolReturnTrip: _hasReturnTrip,
          carpoolReturnStayOnLocation: _hasReturnTrip ? _stayOnLocation : null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Carpool '${_carpoolNameController.text.trim()}' created successfully!")),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving carpool: $e")));
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
    bool showAvailabilityIcon = false,
    bool showImage = false, // ✅ NEW PARAMETER
    String imageField = '', // ✅ Which image to use
    }
  ) {
    return DropdownButtonFormField(
      value: selectedValue,
      items: items.map((item) {
        bool isDisabled = item['isAvailable'] == false;

        return DropdownMenuItem(
          value: item[idField],
          enabled: !isDisabled,
          child: Row(
            children: [
              if (showImage && item[imageField] != null && item[imageField] != "")
                CircleAvatar(
                  backgroundImage: FileImage(File(item[imageField])),
                  radius: 12,
                ),
              if (showImage) SizedBox(width: 8),
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
      onChanged: (value) => setState(() => onChangedCallback(value as String?)),
      decoration: InputDecoration(labelText: label),
    );
  }

  /// 🧩 Builds a checkbox list tile for each participant
  Widget _buildParticipantCheckbox(Map<String, dynamic> member) {
    final memberId = member['id'];
    final memberName = member['fullName'];

    return CheckboxListTile(
      title: Text(memberName),
      value: _selectedParticipants.contains(memberId),
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            _selectedParticipants.add(memberId);
          } else {
            _selectedParticipants.remove(memberId);
          }
        });
      },
    );
  }


  /// 🔍 Checks if all required form fields are filled
  /// Used to enable/disable the Submit button dynamically
  bool _isFormComplete() {
    return _carpoolNameController.text.isNotEmpty &&         // 📝 Carpool name filled
          _routeStartController.text.isNotEmpty &&          // 🗺️ Start location filled
          _routeEndController.text.isNotEmpty &&            // 📍 End location filled
          _selectedDate != null &&                          // 📅 Date selected
          _selectedTime != null &&                          // ⏰ Time selected
          _selectedVehicle != null &&                       // 🚗 Vehicle selected
          _selectedDriver != null &&                        // 👨‍✈️ Driver selected
          _capacityController.text.isNotEmpty;              // 💺 Capacity entered
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

            // Owner Dropdown
            // TextFormField(
            //   decoration: InputDecoration(labelText: "Carpool Owner"),
            //   initialValue: _adults.firstWhere((a) => a['id'] == _selectedOwner)['fullName'],
            //   enabled: false, // 🔒 Locked
            // ),
            // 🔒 Locked Carpool Owner Field - Always the logged-in account owner
            if (_selectedOwner != null && _loggedInUserData != null)
              ListTile(
                title: Text("Carpool Owner"),
                subtitle: Text(_loggedInUserData?["fullName"] ?? "Unknown"),
                leading: Icon(Icons.lock),
              ),
            // _buildDropdown(
            //   "Carpool Owner",
            //   _selectedOwner,
            //   _adults,
            //   "id",
            //   "fullName",
            //   (value) => _selectedOwner = value, // 🔹 Updates _selectedOwner
            // ),

            // Driver Dropdown
            _buildDropdown(
              "Driver",
              _selectedDriver,
              _adults,
              "id",
              "fullName",
              (value) {
                setState(() {
                  _selectedDriver = value;

                  // ✅ Auto-clear participants when driver changes
                  _selectedParticipants.clear();

                  // ✅ Also ensure participants list doesn't include the new driver
                  _carpoolParticipants.remove(_selectedDriver);
                });
              },
              showImage: true, // ✅ Show driver image
              imageField: "profilePhoto", // ✅ Use profile image field
            ),

            
            // Vehicle Dropdown
            _buildDropdown(
              "Select Vehicle",
              _selectedVehicle,
              _vehicles,
              "id",
              "vehicleMake",
              (value) {
                setState(() {
                  _selectedVehicle = value;
                  _onVehicleSelected(value!);
                });
              },
              showAvailabilityIcon: true,
              showImage: true, // ✅ Show vehicle image
              imageField: "vehicleImage", // ✅ Field to use
            ),

            // 📌 Purpose: Lets user select additional carpool participants from the family
            // 🔄 Loop through family members and build checkboxes
            /// 🔄 Participant Section: Split into Children and Adults for clarity
            if (_selectedDriver != null) ...[
              SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Select Participants", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 10),

              /// 👶 CHILDREN PARTICIPANTS
              if (_familyMembers.any((m) => m['isAdult'] == false && m['id'] != _selectedDriver)) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Children", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                ),
                ..._familyMembers
                    .where((m) => m['isAdult'] == false && m['id'] != _selectedDriver)
                    .map((member) => _buildParticipantCheckbox(member))
                    .toList(),
                SizedBox(height: 10),
              ],

              /// 🧑‍🦱 ADULT PARTICIPANTS
              if (_familyMembers.any((m) => m['isAdult'] == true && m['id'] != _selectedDriver)) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Adults", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                ),
                ..._familyMembers
                    .where((m) => m['isAdult'] == true && m['id'] != _selectedDriver)
                    .map((member) => _buildParticipantCheckbox(member))
                    .toList(),
              ]
            ],

            // Carpool Capacity

            // _buildTextField("Capacity", _capacityController, keyboardType: TextInputType.number),
            _buildTextField(
              _vehicleMaxCapacity != null
                  ? "Capacity (Max: $_vehicleMaxCapacity)"
                  : "Capacity",
              _capacityController,
              keyboardType: TextInputType.number,
            ),

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
            // ✅ Submit button becomes enabled only when all required fields are filled
            ElevatedButton(
              onPressed: _isFormComplete() ? _createCarpool : null, // 🔒 Disabled if form incomplete
              child: Text(_isEditing ? "Update Carpool" : "Create Carpool"),
            ),

            // 🔘 Reset/Clear Button
            TextButton.icon(
              onPressed: _resetCarpoolForm,
              icon: Icon(Icons.refresh),
              label: Text("Clear Form"),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          ],          
        ),
      ),
    );
  }
}
