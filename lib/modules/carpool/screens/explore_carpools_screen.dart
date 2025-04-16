import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart'; // Firestore interaction logic
import 'package:kccarpoolapp/modules/carpool/widgets/carpool_card.dart'; // Existing reusable carpool UI

/// 🔍 Screen to explore carpools created by other families
/// This screen helps the user find joinable carpools that they do not own or already participate in.
class ExploreCarpoolsScreen extends StatefulWidget {
  @override
  _ExploreCarpoolsScreenState createState() => _ExploreCarpoolsScreenState();
}

class _ExploreCarpoolsScreenState extends State<ExploreCarpoolsScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions(); // Firebase abstraction class

  List<Map<String, dynamic>> _carpools = []; // Holds list of external carpools to display
  bool _isLoading = true; // Tracks whether data is being fetched
  String _currentUserId = ""; // Stores logged-in user's UID

  @override
  void initState() {
    super.initState();
    _loadExploreCarpools(); // Load available carpools when screen loads
  }

  /// 🔍 Loads carpools from other families for the Explore screen.
  /// This function performs the following:
  /// 1. Fetch carpools the user can explore (i.e. not created by their family and not already joined)
  /// 2. Enrich each carpool with required display fields for the CarpoolCard:
  ///    - driverName, driverPhoto
  ///    - vehicleMakeModel, vehicleImage
  ///    - resolvedParticipants (full participant info)
  /// 3. Set the enriched list in state for rendering
  Future<void> _loadExploreCarpools() async {
    // Step 1: Show loading indicator while data is being fetched
    setState(() => _isLoading = true);

    try {
      // Step 2: Get the currently logged-in user's UID
      final String userId = _firebaseFunctions.getCurrentUserId() ?? "";

      // Step 3: Fetch carpools from other families that the user hasn't joined
      final List<Map<String, dynamic>> exploreCarpools =
          await _firebaseFunctions.getExploreCarpools();

      // Step 4: Enrich each carpool with the fields expected by CarpoolCard
      final List<Map<String, dynamic>> enrichedCarpools = [];

      for (final carpool in exploreCarpools) {
        // Get vehicle data from Firestore using carpoolVehicleId
        final vehicleData =
            await _firebaseFunctions.getVehicleById(carpool['carpoolVehicleId']);

        // Get driver user data using carpoolDriverId
        final driverData = await _firebaseFunctions.getDriverById(
          driverId: carpool['carpoolDriverId'],
        );

        // Get list of full participant documents based on carpoolParticipants field
        final resolvedParticipants = await _firebaseFunctions.getCarpoolParticipants(
          carpoolDriverId: carpool['carpoolDriverId'],
          participantIds: List<String>.from(carpool['carpoolParticipants'] ?? []),
        );

        // Flatten the required fields so CarpoolCard works correctly
        carpool['driverName'] = driverData?['fullName'] ?? "Unknown Driver";
        carpool['driverPhoto'] = driverData?['profilePhoto'];
        carpool['vehicleMakeModel'] = vehicleData != null
            ? "${vehicleData['vehicleMake']} ${vehicleData['vehicleModel']}"
            : "Unknown Vehicle";
        carpool['vehicleImage'] = vehicleData?['vehicleImage'];
        carpool['resolvedParticipants'] = resolvedParticipants;

        // Add this enriched carpool to the final list
        enrichedCarpools.add(carpool);
      }

      // Step 5: Save the results to the screen's state to trigger UI rebuild
      setState(() {
        _carpools = enrichedCarpools;
        _currentUserId = userId;
      });
    } catch (e) {
      // Step 6: Handle errors (e.g., permission issues or Firestore failures)
      print("Error loading explore carpools: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load carpools")),
      );
    } finally {
      // Step 7: Stop showing the loading spinner
      setState(() => _isLoading = false);
    }
  }


  /// 🚀 Triggered when user taps "Request to Join"
  Future<void> _handleJoinRequest(String carpoolId) async {
    try {
      await _firebaseFunctions.requestToJoinCarpool(carpoolId); // 👈 Calls Firestore function
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Join request sent!")),
      );
      _loadExploreCarpools(); // 🔄 Reload to reflect state change
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send join request.")),
      );
    }
  }

  /// 🛑 Triggered when user taps "Cancel Request"
  Future<void> _handleCancelRequest(String carpoolId) async {
    try {
      await _firebaseFunctions.cancelJoinRequest(carpoolId); // 🔧 (to be implemented later)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request cancelled.")),
      );
      _loadExploreCarpools(); // 🔄 Reload
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to cancel request.")),
      );
    }
  }

  /// 🔁 Builds dynamic button based on whether the user has requested to join already
  Widget _buildActionButton(Map<String, dynamic> carpool) {
    final List<dynamic> requestedUsers = carpool['requestedUserIds'] ?? [];

    final bool alreadyRequested = requestedUsers.contains(_currentUserId);

    return ElevatedButton.icon(
      icon: Icon(alreadyRequested ? Icons.cancel : Icons.group_add),
      label: Text(alreadyRequested ? "Cancel Request" : "Request to Join"),
      onPressed: () {
        alreadyRequested
            ? _handleCancelRequest(carpool['carpoolId'])
            : _handleJoinRequest(carpool['carpoolId']);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Explore Carpools")),

      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // 🌀 Loading Spinner
          : _carpools.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text("No Carpools Available", style: TextStyle(fontSize: 20)),
                      SizedBox(height: 8),
                      Text("Try again later or adjust your filters."),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadExploreCarpools, // 🔁 Pull to refresh support
                  child: ListView.builder(
                    itemCount: _carpools.length,
                    itemBuilder: (context, index) {
                      final carpool = _carpools[index];

                      return Column(
                        children: [
                          CarpoolCard(
                            carpool: carpool,
                            onDelete: (_) {}, // 🔒 No delete allowed in Explore screen
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildActionButton(carpool), // 🎯 Main "Join/Cancel" button
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}
