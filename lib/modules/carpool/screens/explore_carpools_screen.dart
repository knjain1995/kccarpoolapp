import 'package:cloud_firestore/cloud_firestore.dart';
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

  // 📌 Keeps track of carpools for which the current user has sent a join request
  Set<String> _requestedCarpools = {};

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
  /// 🔍 Loads carpools created by other families and enriches each for display.
  /// Adds a flag `hasRequested` by checking the flat joinRequests collection.
  Future<void> _loadExploreCarpools() async {
    // Step 1: Show loading spinner
    setState(() => _isLoading = true);

    try {
      final String userId = _firebaseFunctions.getCurrentUserId() ?? "";
      final List<Map<String, dynamic>> exploreCarpools =
          await _firebaseFunctions.getExploreCarpools();

      final List<Map<String, dynamic>> enrichedCarpools = [];

      for (final carpool in exploreCarpools) {
        // Step 2: Enrich carpool with vehicle info
        final vehicleData =
            await _firebaseFunctions.getVehicleById(carpool['carpoolVehicleId']);

        // Step 3: Enrich carpool with driver info
        final driverData = await _firebaseFunctions.getDriverById(
          driverId: carpool['carpoolDriverId'],
        );

        // Step 4: Resolve carpoolParticipants for display
        final resolvedParticipants = await _firebaseFunctions.getCarpoolParticipants(
          carpoolDriverId: carpool['carpoolDriverId'],
          participantIds: List<String>.from(carpool['carpoolParticipants'] ?? []),
        );

        // Step 5: Populate required fields for CarpoolCard widget
        carpool['driverName'] = driverData?['fullName'] ?? "Unknown Driver";
        carpool['driverPhoto'] = driverData?['profilePhoto'];
        carpool['vehicleMakeModel'] = vehicleData != null
            ? "${vehicleData['vehicleMake']} ${vehicleData['vehicleModel']}"
            : "Unknown Vehicle";
        carpool['vehicleImage'] = vehicleData?['vehicleImage'];
        carpool['resolvedParticipants'] = resolvedParticipants;

        // ✅ NEW: Step 6 — Check if this user has already requested to join this carpool
        final String requestId = '${carpool['carpoolId']}_$userId';
        final DocumentSnapshot requestSnapshot = await FirebaseFirestore.instance
            .collection('joinRequests')
            .doc(requestId)
            .get();

        carpool['hasRequested'] = requestSnapshot.exists;

        // Step 7: Add the enriched carpool to the final list
        enrichedCarpools.add(carpool);
      }

      // Step 8: Save data to state and stop loading
      setState(() {
        _carpools = enrichedCarpools;
        _currentUserId = userId;
      });
    } catch (e) {
      print("Error loading explore carpools: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load carpools")),
      );
    } finally {
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
        await _firebaseFunctions.requestToJoinCarpoolFlat(
          carpoolId: carpoolId,
          memberUserIds: selectedMemberIds, // from family selection dialog
        );

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
  /// 🎯 Renders the "Request to Join" / "Cancel Request" button for each carpool.
  Widget _buildActionButton(Map<String, dynamic> carpool) {
    // ✅ New logic: flag comes from Firestore lookup done in `_loadExploreCarpools`
    final bool alreadyRequested = carpool['hasRequested'] == true;

    return ElevatedButton.icon(
      icon: Icon(alreadyRequested ? Icons.cancel : Icons.group_add),
      label: Text(alreadyRequested ? "Cancel Request" : "Request to Join"),
      onPressed: () {
        alreadyRequested
            ? _handleCancelRequest(carpool['carpoolId']) // 🔁 cancel
            : _handleJoinRequest(carpool['carpoolId']);  // ➕ send
      },
    );
  }


  /// Loads join request states for the current user across all explore carpools
  Future<void> _loadRequestedCarpools() async {
    final String? currentUserId = _firebaseFunctions.getCurrentUserId();
    if (currentUserId == null) return;

    final List<String> carpoolIds = _carpools.map((c) => c['carpoolId'] as String).toList();
    final Set<String> requested = {};

    for (final carpoolId in carpoolIds) {
      bool hasRequested = await _firebaseFunctions.hasUserRequestedJoin(carpoolId);
      if (hasRequested) {
        requested.add(carpoolId);
      }
    }

    setState(() {
      _requestedCarpools = requested;
    });
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
