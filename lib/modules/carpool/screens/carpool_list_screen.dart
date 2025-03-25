import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';
import 'package:intl/intl.dart';

class CarpoolListScreen extends StatefulWidget {
  @override
  _CarpoolListScreenState createState() => _CarpoolListScreenState();
}

class _CarpoolListScreenState extends State<CarpoolListScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();
  List<Map<String, dynamic>> _carpools = [];

  @override
  void initState() {
    super.initState();
    _loadCarpools(); // 🔹 Fetch user's carpools on screen load
  }

  /// Loads carpools created by the logged-in user
  Future<void> _loadCarpools() async {
    List<Map<String, dynamic>> rawCarpools = await _firebaseFunctions.getCarpools();

    // 🔄 Fetch driver & vehicle info for each carpool
    List<Map<String, dynamic>> enrichedCarpools = [];

    for (var carpool in rawCarpools) {
      // 🔸 Fetch Driver Info
      final driverData = await _firebaseFunctions.getDriverById(
        driverId: carpool["carpoolDriverId"],
        carpoolOwnerId: carpool["carpoolOwnerId"],
      );
      carpool['driverName'] = driverData?['fullName'] ?? "Unknown";
      carpool['driverPhoto'] = driverData?['profilePhoto'];

      // 🔸 Fetch Vehicle Info
      var vehicleData = await _firebaseFunctions.getVehicleById(carpool['carpoolVehicleId']);
      carpool['vehicleMakeModel'] = vehicleData != null
          ? "${vehicleData['vehicleMake']} ${vehicleData['vehicleModel']}"
          : "Unknown Vehicle";
      carpool['vehicleImage'] = vehicleData?['vehicleImage'];

      enrichedCarpools.add(carpool);
    }

    setState(() {
      _carpools = enrichedCarpools;
    });
  }

  /// Deletes a carpool by ID
  Future<void> _deleteCarpool(String carpoolId) async {
    await _firebaseFunctions.deleteCarpool(carpoolId);
    _loadCarpools(); // 🔁 Refresh list after deletion
  }

  /// 🔹 Builds each carpool card
  Widget _buildCarpoolCard(Map<String, dynamic> carpool) {
    DateTime carpoolDate = (carpool['carpoolDate'] as Timestamp).toDate();
    DateTime carpoolTime = (carpool['carpoolTime'] as Timestamp).toDate();

    String formattedDate = DateFormat('dd MMM yyyy').format(carpoolDate);
    String formattedTime = DateFormat('hh:mm a').format(carpoolTime);

    // 👇 Get total capacity and participants from the carpool document
    final int capacity = carpool['carpoolCapacity'] ?? 0;
    final List<dynamic> participants = carpool['carpoolParticipants'] ?? [];
    final int availableSeats = capacity - participants.length;

    // 👇 Determine carpool status
    final String status = availableSeats == 0 ? "Full" : "Available";
    final Color statusColor = status == "Full" ? Colors.red : Colors.green;

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Top Row: Carpool Name + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(carpool['carpoolName'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(carpool['carpoolStatus']),
                ),
              ],
            ),
            SizedBox(height: 8),

            // 🔹 Route Info
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.grey[700]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "${carpool['carpoolRouteStart']} → ${carpool['carpoolRouteEnd']}",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            // 🔹 Driver Info
            Row(
              children: [
                carpool['driverPhoto'] != null
                    ? CircleAvatar(
                        backgroundImage: FileImage(File(carpool['driverPhoto'])),
                        radius: 14,
                      )
                    : Icon(Icons.person, size: 20),
                SizedBox(width: 6),
                Text("Driver: ${carpool['driverName']}", style: TextStyle(fontSize: 14)),
              ],
            ),

            // 🔹 Date & Time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
                SizedBox(width: 4),
                Text("Date: $formattedDate,"),
                SizedBox(width: 6),
                Icon(Icons.access_time, size: 18, color: Colors.grey[700]),
                SizedBox(width: 4),
                Text("Time: $formattedTime"),
              ],
            ),

            // 🔹 Vehicle Info + Available Seats + Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🔹 Vehicle info
                Row(
                  children: [
                    carpool['vehicleImage'] != null
                        ? Image.file(
                            File(carpool['vehicleImage']),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.directions_car, size: 30, color: Colors.blue),
                    SizedBox(width: 6),
                    Text(carpool['vehicleMakeModel']),
                  ],
                ),

                // 🔹 Seats + Actions
                Row(
                  children: [
                    Text(
                      "Seats: $availableSeats/$capacity",
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.orange),
                      onPressed: () {
                        // 🚧 Future: Navigate to edit screen
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCarpool(carpool['carpoolId']),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Builds the full screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Carpools")),
      body: _carpools.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _carpools.length,
              itemBuilder: (context, index) => _buildCarpoolCard(_carpools[index]),
            ),
    );
  }
}
