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
    _loadExploreCarpools(); // Load available carpools wfrequestToJoinCarpoolhen screen loads
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

  /// 🔄 Fetches the current user's family members (excluding self)
  Future<List<Map<String, dynamic>>> _fetchFamilyMembers() async {
    try {
      return await FirebaseFunctions().getFamilyMembersByIds(includePrimaryUser: false);
    } catch (e) {
      print("Error fetching family members: $e");
      return [];
    }
  }

  /// 🚀 Triggered when user taps "Request to Join"
    Future<void> _handleJoinRequest(String carpoolId) async {
    try {
      // Step 1: Fetch the family members (excluding self)
      final members = await _firebaseFunctions.getFamilyMembersByIds(includePrimaryUser: false);

      final currentUserId = _firebaseFunctions.getCurrentUserId();
      final currentUserData = await _firebaseFunctions.getUserData();

      if (currentUserId != null) {
        members.insert(0, {
          'id': currentUserId,
          'fullName': currentUserData?['fullName'] ?? 'You',
        });
      }

      if (members.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No family members available to join this carpool")),
        );
        return;
      }

      final Set<String> selected = {};

      // Step 2: Show family member selection dialog
      final List<String>? selectedMemberIds = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Select Family Members"),
            content: SizedBox(
              width: double.maxFinite,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return ListView(
                    shrinkWrap: true,
                    children: members.map((member) {
                      final memberId = member["id"];
                      final name = member["fullName"];
                      return CheckboxListTile(
                        title: Text(name),
                        value: selected.contains(memberId),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selected.add(memberId);
                            } else {
                              selected.remove(memberId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, selected.toList()),
                  child: Text("Submit")),
            ],
          );
        },
      );

      // Step 3: Submit the join request
      if (selectedMemberIds != null && selectedMemberIds.isNotEmpty) {
        await _firebaseFunctions.requestToJoinCarpool(carpoolId, selectedMemberIds);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Join request sent!")),
        );

        _loadExploreCarpools(); // 🔄 Refresh to update button state
      }
    } catch (e) {
      print("Error in join request: $e");
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
    // final List<dynamic> requestedUsers = carpool['requestedUserIds'] ?? [];
    // final bool alreadyRequested = requestedUsers.contains(_currentUserId);
    final Map<String, dynamic> requestedUsers = carpool['requestedUsers'] ?? {};
    final bool alreadyRequested = requestedUsers.containsKey(_currentUserId);

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
