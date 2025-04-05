import 'package:flutter/material.dart';
import 'package:kccarpoolapp/core/routes.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';
import 'package:kccarpoolapp/modules/carpool/widgets/carpool_card.dart';


class CarpoolListScreen extends StatefulWidget {
  @override
  _CarpoolListScreenState createState() => _CarpoolListScreenState();
}

class _CarpoolListScreenState extends State<CarpoolListScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();
  List<Map<String, dynamic>> _carpools = [];
  bool _isLoading = false; // 🌀 Indicates whether we are fetching carpools

  @override
  void initState() {
    super.initState();
    _loadCarpools(); // 🔹 Fetch user's carpools on screen load
  }

  /// Loads carpools created by the logged-in user
  Future<void> _loadCarpools() async {
    setState(() => _isLoading = true); // 🌀 Start loading spinner

    List<Map<String, dynamic>> rawCarpools = await _firebaseFunctions.getCarpools();

    // 🔄 Fetch driver & vehicle info for each carpool
    List<Map<String, dynamic>> enrichedCarpools = [];

    for (var carpool in rawCarpools) {
      // 🔸 Fetch Driver Info
      final driverData = await _firebaseFunctions.getDriverById(
        driverId: carpool["carpoolDriverId"],
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
        carpoolDriverId: carpool['carpoolDriverId'],
        participantIds: participantIds,
      );
      carpool['resolvedParticipants'] = resolvedParticipants;

      enrichedCarpools.add(carpool);
    }

    setState(() {
      _carpools = enrichedCarpools;
      _isLoading = false; // ✅ Stop spinner after data is loaded
    });
  }

  /// Deletes a carpool by ID
  Future<void> _deleteCarpool(String carpoolId) async {
    setState(() => _isLoading = true); // 🌀 Show loading during deletion

    try {
      await _firebaseFunctions.deleteCarpool(carpoolId);
      await _loadCarpools(); // 🔁 Refresh list after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Carpool deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting carpool: $e")),
      );
    } finally {
      setState(() => _isLoading = false); // ✅ Stop spinner
    }
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

  body: _isLoading
    ? Center(child: CircularProgressIndicator()) // 🌀 Show spinner
    : _carpools.isEmpty
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
        : RefreshIndicator(
        onRefresh: _loadCarpools, // 🔁 Pull to refresh
        child: ListView.builder(
          itemCount: _carpools.length,
          itemBuilder: (context, index) {
            return CarpoolCard(
              carpool: _carpools[index], // 🔹 Send carpool data
              onDelete: _deleteCarpool,  // 🔹 Pass delete handler from your screen
            );
          },
        ),
      ),
    );
  }
}
