// 📌 Filename: carpool_card.dart
// 📂 Location: lib/modules/carpool/widgets

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kccarpoolapp/core/routes.dart';

/// 🔹 CarpoolCard displays one carpool item in the list.
/// It receives carpool data and handles navigation/edit/delete logic.
class CarpoolCard extends StatelessWidget {
  final Map<String, dynamic> carpool;
  final Function(String carpoolId) onDelete;

  const CarpoolCard({
    Key? key,
    required this.carpool,
    required this.onDelete,
  }) : super(key: key);

  /// 🔹 Displays avatars & names of participants (excluding driver)
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

  @override
  Widget build(BuildContext context) {
    DateTime carpoolDate = (carpool['carpoolDate'] as Timestamp).toDate();
    DateTime carpoolTime = (carpool['carpoolTime'] as Timestamp).toDate();

    String formattedDateTime = DateFormat('E, dd MMM • h:mm a').format(
      DateTime(
        carpoolDate.year,
        carpoolDate.month,
        carpoolDate.day,
        carpoolTime.hour,
        carpoolTime.minute,
      ),
    );

    final int capacity = carpool['carpoolCapacity'] ?? 0;
    final List<dynamic> participants = carpool['carpoolParticipants'] ?? [];
    final int availableSeats = capacity - participants.length;
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
            // 🔹 Carpool Title + Return Tag + Status
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
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: Colors.green),
                SizedBox(width: 6),
                Text(carpool['carpoolRouteStart'] ?? "", style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 16, color: Colors.black54),
                SizedBox(width: 6),
                Text(carpool['carpoolRouteEnd'] ?? "", style: TextStyle(fontWeight: FontWeight.w500)),
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

            // 🔹 Participants
            if (carpool.containsKey('resolvedParticipants'))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Participants:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  _buildParticipantAvatars(List<Map<String, dynamic>>.from(carpool['resolvedParticipants'])),
                ],
              ),

            // 🔹 Date & Time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
                SizedBox(width: 4),
                Text(formattedDateTime, style: TextStyle(fontSize: 14)),
              ],
            ),

            // 🔹 Vehicle Info + Seats + Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Row(
                  children: [
                    Text("Seats: $availableSeats/$capacity", style: TextStyle(fontSize: 14)),
                    SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.orange),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.createCarpool,
                          arguments: {"carpoolData": carpool},
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        bool confirmed = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text("Confirm Deletion"),
                            content: Text("Are you sure you want to delete this carpool?"),
                            actions: [
                              TextButton(
                                child: Text("Cancel"),
                                onPressed: () => Navigator.of(context).pop(false),
                              ),
                              ElevatedButton(
                                child: Text("Delete"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.of(context).pop(true),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          onDelete(carpool['carpoolId']);
                        }
                      },
                    )
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
