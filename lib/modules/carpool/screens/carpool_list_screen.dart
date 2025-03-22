import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';

/// ✅ Carpool Listing Screen - Displays all carpools created by the user.
class CarpoolListScreen extends StatefulWidget {
  @override
  _CarpoolListScreenState createState() => _CarpoolListScreenState();
}

class _CarpoolListScreenState extends State<CarpoolListScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();
  List<Map<String, dynamic>> _carpools = [];
  List<Map<String, dynamic>> _adults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCarpools();
  }

  /// 🔄 Fetch carpools and adult family members (including account owner)
  Future<void> _loadCarpools() async {
    setState(() => _isLoading = true);

    var carpools = await _firebaseFunctions.getCarpools();
    var userData = await _firebaseFunctions.getUserData();
    var family = await _firebaseFunctions.getFamilyMembers();

    _adults = family.where((f) => f['isAdult'] == true).toList();

    if (userData != null) {
      _adults.insert(0, {
        "id": userData["id"],
        "fullName": userData["fullName"],
        "profilePhoto": userData["profilePhoto"],
      });
    }

    setState(() {
      _carpools = carpools;
      _isLoading = false;
    });
  }

  /// 🔍 Get driver's full name using driver ID
  String _getDriverName(String driverId) {
    var driver = _adults.firstWhere((a) => a['id'] == driverId, orElse: () => {});
    return driver['fullName'] ?? "Unknown";
  }

  /// 🖼️ Get driver photo (local path)
  String? _getDriverPhoto(String driverId) {
    var driver = _adults.firstWhere((a) => a['id'] == driverId, orElse: () => {});
    return driver['profilePhoto'];
  }

  /// 🧩 Builds a single carpool card
  Widget _buildCarpoolCard(Map<String, dynamic> carpool) {
    String driverName = _getDriverName(carpool['carpoolDriverId']);
    String? driverPhoto = _getDriverPhoto(carpool['carpoolDriverId']);
    String start = carpool['carpoolRouteStart'];
    String end = carpool['carpoolRouteEnd'];

    DateTime date = (carpool['carpoolDate'] as Timestamp).toDate();
    DateTime time = (carpool['carpoolTime'] as Timestamp).toDate();

    String formattedDate = DateFormat('dd MMM yyyy').format(date);
    String formattedTime = DateFormat('hh:mm a').format(time);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: driverPhoto != null ? FileImage(File(driverPhoto)) : null,
          radius: 24,
          child: driverPhoto == null ? Icon(Icons.person) : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.green),
                  SizedBox(width: 5),
                  Expanded(child: Text(start, overflow: TextOverflow.ellipsis)),
                  Icon(Icons.arrow_forward, size: 16),
                  Expanded(child: Text(end, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Driver: $driverName"),
            Text("Date: $formattedDate, Time: $formattedTime"),
            SizedBox(height: 4),
          ],
        ),
        trailing: Column(
          children: [
            IconButton(
              icon: Icon(Icons.edit, size: 20),
              onPressed: () {
                // TODO: Hook up to Edit Carpool
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () {
                // TODO: Hook up to Delete Carpool
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Carpools")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _carpools.isEmpty
              ? Center(child: Text("No carpools found."))
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: _carpools.length,
                  itemBuilder: (context, index) {
                    return _buildCarpoolCard(_carpools[index]);
                  },
                ),
    );
  }
}
