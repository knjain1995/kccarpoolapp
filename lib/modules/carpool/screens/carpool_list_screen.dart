// 📂 Location: lib/modules/carpool/screens/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';

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
    _loadCarpools(); // 🔄 Load all carpools when screen opens
  }

  /// Fetches carpool data and driver info
  Future<void> _loadCarpools() async {
    List<Map<String, dynamic>> carpools = await _firebaseFunctions.getCarpools();

    // 🔄 For each carpool, fetch driver info and attach to carpool map
    for (var carpool in carpools) {
      String driverId = carpool['carpoolDriverId'];

      Map<String, dynamic>? driverData = await _firebaseFunctions.getUserById(driverId);

      carpool['driverName'] = driverData?['fullName'] ?? "Unknown";
      carpool['driverPhoto'] = driverData?['profilePhoto']; // Can be null
    }

    setState(() {
      _carpools = carpools;
    });
  }

  /// Deletes a carpool by its ID
  Future<void> _deleteCarpool(String carpoolId) async {
    await _firebaseFunctions.deleteCarpool(carpoolId);
    _loadCarpools(); // 🔁 Reload list after deletion
  }

  /// Builds a card for each carpool
  Widget _buildCarpoolCard(Map<String, dynamic> carpool) {
    DateTime date = carpool['carpoolDate'].toDate();
    DateTime time = carpool['carpoolTime'].toDate();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          children: [
            // 👤 Driver photo or fallback icon
            CircleAvatar(
              radius: 24,
              backgroundImage: carpool['driverPhoto'] != null
                  ? FileImage(File(carpool['driverPhoto']))
                  : null,
              child: carpool['driverPhoto'] == null ? Icon(Icons.person) : null,
            ),
            SizedBox(width: 12),

            // 📝 Carpool Details (name, route, driver, date, time)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🚌 Route line
                  Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: Colors.green),
                      SizedBox(width: 4),
                      Text(carpool['carpoolRouteStart'], style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, size: 18),
                      SizedBox(width: 6),
                      Text(carpool['carpoolRouteEnd'], style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 4),

                  Text("Driver: ${carpool['driverName']}"),
                  Text("Date: ${_formatDate(date)}, Time: ${_formatTime(time)}"),
                ],
              ),
            ),

            // ✏️ Edit & Delete Icons
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.black54),
                  onPressed: () {
                    // TODO: Implement Edit Screen
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
      ),
    );
  }

  /// Helper: Format date
  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')} "
        "${_monthName(date.month)} ${date.year}";
  }

  /// Helper: Format time
  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  /// Helper: Month name
  String _monthName(int month) {
    const List<String> months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Carpools")),
      body: ListView.builder(
        itemCount: _carpools.length,
        itemBuilder: (context, index) {
          return _buildCarpoolCard(_carpools[index]);
        },
      ),
    );
  }
}
