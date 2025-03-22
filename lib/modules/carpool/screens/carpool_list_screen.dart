// 📁 Filename: carpool_list_screen.dart
// 📂 Location: lib/modules/carpool/screens/
// 📌 Purpose: Lists all carpools created by the currently logged-in user

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CarpoolListScreen extends StatefulWidget {
  @override
  _CarpoolListScreenState createState() => _CarpoolListScreenState();
}

class _CarpoolListScreenState extends State<CarpoolListScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();

  List<Map<String, dynamic>> _carpools = []; // Stores all created carpools
  bool _isLoading = true; // Controls loading state

  @override
  void initState() {
    super.initState();
    _fetchCarpools(); // Fetch carpools on screen load
  }

  /// Fetches all carpools created by the logged-in user
  Future<void> _fetchCarpools() async {
    try {
      List<Map<String, dynamic>> result = await _firebaseFunctions.getCarpools();
      setState(() {
        _carpools = result;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching carpools: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load carpools.")));
    }
  }

  /// Deletes a carpool with confirmation
  Future<void> _deleteCarpool(String carpoolId) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Carpool"),
        content: Text("Are you sure you want to delete this carpool?"),
        actions: [
          TextButton(child: Text("Cancel"), onPressed: () => Navigator.pop(context, false)),
          TextButton(child: Text("Delete", style: TextStyle(color: Colors.red)), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firebaseFunctions.deleteCarpool(carpoolId);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Carpool deleted.")));
        _fetchCarpools(); // Refresh list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete carpool.")));
      }
    }
  }

  /// Converts Firestore Timestamp to readable date string
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  /// Converts Firestore Timestamp to readable time string
  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  /// Builds each carpool card
  Widget _buildCarpoolCard(Map<String, dynamic> carpool) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔸 Carpool Name & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(carpool["carpoolName"], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(_formatDate(carpool["carpoolDate"]), style: TextStyle(fontSize: 14)),
              ],
            ),
            SizedBox(height: 8),

            /// 🔸 Time and Route
            Text("Time: ${_formatTime(carpool["carpoolTime"])}"),
            Text("Route: From ${carpool["carpoolRouteStart"]} to ${carpool["carpoolRouteEnd"]}"),
            SizedBox(height: 8),

            /// 🔸 Driver & Seats
            Text("Driver ID: ${carpool["carpoolDriverId"]}"), // You can replace with driver name if needed
            Text("Available Seats: ${carpool["carpoolCapacity"]}"),
            SizedBox(height: 12),

            /// 🔸 Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.edit),
                  label: Text("Edit"),
                  onPressed: () {
                    // TODO: Implement Edit Screen
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Edit not implemented yet.")));
                  },
                ),
                SizedBox(width: 10),
                OutlinedButton.icon(
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text("Delete", style: TextStyle(color: Colors.red)),
                  onPressed: () => _deleteCarpool(carpool["id"]),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Carpools")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _carpools.isEmpty
              ? Center(child: Text("No carpools created yet."))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _carpools.length,
                  itemBuilder: (context, index) => _buildCarpoolCard(_carpools[index]),
                ),
    );
  }
}
