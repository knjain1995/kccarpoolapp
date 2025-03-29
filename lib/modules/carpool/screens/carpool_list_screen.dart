import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/core/routes.dart';
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

      // Inside the for-loop that enriches each carpool:
      final List<String> participantIds = List<String>.from(carpool['carpoolParticipants'] ?? []);
      final List<Map<String, dynamic>> resolvedParticipants =
          await _firebaseFunctions.getCarpoolParticipants(
        carpoolOwnerId: carpool['carpoolOwnerId'],
        carpoolDriverId: carpool['carpoolDriverId'],
        participantIds: participantIds,
      );
      carpool['resolvedParticipants'] = resolvedParticipants;

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

    // 📅 Format: Mon, 28 Mar • 8:00 AM
    String formattedDateTime = DateFormat('E, dd MMM • h:mm a').format(DateTime(
      carpoolDate.year,
      carpoolDate.month,
      carpoolDate.day,
      carpoolTime.hour,
      carpoolTime.minute,
    ));

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
           // 🔹 Top Row: Carpool Name + Status + Optional Return Trip Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(carpool['carpoolName'],
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

                    if (carpool['carpoolReturnTrip'] == true)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text("↩ Return Trip",
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor)),
                ),
              ],
            ),
            SizedBox(height: 8),

            // 🔹 Route Info
            // 🔄 Better Route Formatting with Icons
            // 🚗 Compact Route Display
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  carpool['carpoolRouteStart'] ?? "",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 16, color: Colors.black54),
                SizedBox(width: 6),
                Text(
                  carpool['carpoolRouteEnd'] ?? "",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(width: 6),
                Icon(Icons.flag, size: 14, color: Colors.red),
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

            if (carpool.containsKey('resolvedParticipants'))
              Text("Participants:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              _buildParticipantAvatars(List<Map<String, dynamic>>.from(carpool['resolvedParticipants'])),


            // 🔹 Date & Time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
                SizedBox(width: 4),
                Text(formattedDateTime, style: TextStyle(fontSize: 14)),
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
                        Navigator.pushNamed(
                          context,
                          AppRoutes.createCarpool,
                          arguments: {
                            "carpoolData": carpool, // 🔄 Send full carpool document for editing
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        bool confirmed = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Confirm Deletion"),
                              content: Text("Are you sure you want to delete this carpool? This action cannot be undone."),
                              actions: [
                                TextButton(
                                  child: Text("Cancel"),
                                  onPressed: () => Navigator.of(context).pop(false),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: Text("Delete"),
                                  onPressed: () => Navigator.of(context).pop(true),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmed == true) {
                          try {
                            await _deleteCarpool(carpool['carpoolId']);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Carpool deleted successfully")),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error deleting carpool: $e")),
                            );
                          }
                        }
                      },
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

    /// 👥 Displays participant avatars (excluding the driver)
  Widget _buildParticipantAvatars(List<Map<String, dynamic>> participants) {
    if (participants.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        children: [
          Icon(Icons.group, size: 20, color: Colors.grey[700]),
          SizedBox(width: 8),
          ...participants.map((p) {
            String name = p['fullName'] ?? 'Unknown';
            String? photo = p['profilePhoto'];

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: photo != null && photo.isNotEmpty
                        ? FileImage(File(photo))
                        : null,
                    child: (photo == null || photo.isEmpty)
                        ? Icon(Icons.person, size: 16)
                        : null,
                  ),
                  SizedBox(height: 2),
                  Text(
                    name.split(' ').first,
                    style: TextStyle(fontSize: 10),
                  )
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }


  /// 🔹 Builds the full screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Carpools")),
      
      // 🪄 Sticky Create Button (FloatingActionButton)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createCarpool);
        },
        child: Icon(Icons.add),
        tooltip: "Create Carpool",
      ),

      body: _carpools.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text("No Carpools Yet!",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    "Start by creating your first carpool.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _carpools.length,
              itemBuilder: (context, index) {
                return _buildCarpoolCard(_carpools[index]);
              },
            ),
    );
  }
}
