// 📄 Filename: carpool_list_screen.dart
// 📂 Location: lib/modules/carpool/screens/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    _loadCarpools();
  }

  /// Fetches carpools created by the user
  Future<void> _loadCarpools() async {
    try {
      List<Map<String, dynamic>> carpoolData = await _firebaseFunctions.getCarpools();
      setState(() {
        _carpools = carpoolData;
      });
    } catch (e) {
      print("Error loading carpools: $e");
    }
  }

  /// Deletes the carpool after confirmation
  Future<void> _deleteCarpool(String carpoolId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Carpool"),
        content: Text("Are you sure you want to delete this carpool?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm) {
      await _firebaseFunctions.deleteCarpool(carpoolId);
      _loadCarpools();
    }
  }

  /// Builds each carpool card with all necessary info
  Widget _buildCarpoolCard(Map<String, dynamic> carpool) {
    String carpoolName = carpool['carpoolName'] ?? "Unnamed";
    String routeStart = carpool['carpoolRouteStart'] ?? "-";
    String routeEnd = carpool['carpoolRouteEnd'] ?? "-";
    String status = carpool['carpoolStatus'] ?? "Unknown";
    int capacity = carpool['carpoolCapacity'] ?? 0;
    int availableSeats = capacity; // We’ll calculate later

    String driverId = carpool['carpoolDriverId'] ?? "";
    String carpoolId = carpool['carpoolId'] ?? "";
    String vehicleId = carpool['carpoolVehicleId'] ?? "";

    Timestamp dateTimestamp = carpool['carpoolDate'];
    Timestamp timeTimestamp = carpool['carpoolTime'];
    String formattedDate = DateFormat("dd MMM yyyy").format(dateTimestamp.toDate());
    String formattedTime = DateFormat("hh:mm a").format(timeTimestamp.toDate());

    return FutureBuilder<Map<String, dynamic>?>(
      future: _firebaseFunctions.getUserById(driverId),
      builder: (context, snapshot) {
        final driverData = snapshot.data;
        String driverName = driverData?['fullName'] ?? "Unknown";

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Top Row: Carpool Name & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(carpoolName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == "Available" ? Colors.green[100] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status, style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // 🔹 Route Info
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[700]),
                    SizedBox(width: 6),
                    Text("$routeStart → $routeEnd", style: TextStyle(fontSize: 14)),
                  ],
                ),

                SizedBox(height: 6),

                // 🔹 Driver Info
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Colors.grey[700]),
                    SizedBox(width: 6),
                    Text("Driver: $driverName", style: TextStyle(fontSize: 14)),
                  ],
                ),

                SizedBox(height: 6),

                // 🔹 Date & Time
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 6),
                    Text("Date: $formattedDate,", style: TextStyle(fontSize: 14)),
                    SizedBox(width: 4),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 4),
                    Text("Time: $formattedTime", style: TextStyle(fontSize: 14)),
                  ],
                ),

                SizedBox(height: 10),

                // 🔹 Vehicle Info, Available Seats & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_car_filled, color: Colors.blue[700]),
                        SizedBox(width: 6),
                        Text("Seats: $availableSeats/$capacity", style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange),
                          onPressed: () {
                            // TODO: Handle edit navigation
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCarpool(carpoolId),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Carpools")),
      body: _carpools.isEmpty
          ? Center(child: Text("No carpools found."))
          : ListView.builder(
              itemCount: _carpools.length,
              itemBuilder: (context, index) {
                return _buildCarpoolCard(_carpools[index]);
              },
            ),
    );
  }
}
