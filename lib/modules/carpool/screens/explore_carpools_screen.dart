import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

        // 🔍 Store request status if it exists
        if (requestSnapshot.exists) {
          final data = requestSnapshot.data() as Map<String, dynamic>;
          carpool['joinRequestStatus'] = data['status']; // Store status
          carpool['approvedRequestId'] = data['status'] == 'approved' ? requestId : null; // ✅ Store requestId only if approved
        } else {
          carpool['joinRequestStatus'] = null;
          carpool['approvedRequestId'] = null;
        }

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
    final String? status = carpool['joinRequestStatus'];

    if (status == "approved") {
      return ElevatedButton.icon(
        icon: Icon(Icons.close),
        label: Text("Cancel Participation"),
        onPressed: () {
          final requestId = carpool['approvedRequestId'];
          final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

          if (requestId != null && currentUserId != null) {
            _showCancelParticipationDialog(
              carpoolId: carpool['carpoolId'],
              requesterId: currentUserId,
              requestId: requestId,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Cannot cancel: missing request ID or user ID")),
            );
          }
        },
      );
    } else if (status == "denied") {
    // ❌ Request was denied – user can now request reconsideration
    return ElevatedButton.icon(
      icon: Icon(Icons.refresh),
      label: Text("Request Reconsideration"),
      onPressed: () async {
        try {
          // 👤 Get the current user ID
          final currentUser = FirebaseAuth.instance.currentUser;
          final userId = currentUser?.uid;

          if (userId == null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("User not signed in."),
            ));
            return;
          }

          // 📄 Step 1: Fetch the old denied request document
          final requestId = "${carpool['carpoolId']}_$userId";

          final doc = await FirebaseFirestore.instance
              .collection('joinRequests')
              .doc(requestId)
              .get();

          if (!doc.exists) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Previous request not found."),
            ));
            return;
          }

          final requestData = doc.data()!;
          final List<String> memberUserIds =
              List<String>.from(requestData['memberUserIds'] ?? []);
          final String familyId = requestData['familyId'] ?? "";

          // ✅ Step 2: Call new backend method that safely deletes the old request
          // and creates a new one with the same members
          await FirebaseFunctions().reRequestDeniedJoin(
            carpoolId: carpool['carpoolId'],
            oldRequestId: requestId,
            requesterId: userId,
            memberUserIds: memberUserIds,
            familyId: familyId,
          );

          // 🎉 Notify success
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Re-request sent!"),
          ));

          // 🔄 Refresh the UI to show updated status
          _loadExploreCarpools();
        } catch (e) {
          print("❌ Error during re-request: $e");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Failed to send re-request."),
          ));
        }
      },
    );
  } else if (status == "pending") {
      // ⏳ Waiting for approval
      return ElevatedButton.icon(
        icon: Icon(Icons.cancel),
        label: Text("Cancel Request"),
        onPressed: () => _handleCancelRequest(carpool['carpoolId']),
      );
    } else {
      // 🤝 No request made
      return ElevatedButton.icon(
        icon: Icon(Icons.group_add),
        label: Text("Request to Join"),
        onPressed: () => _handleJoinRequest(carpool['carpoolId']),
      );
    }
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

  /// 🗨️ Shows a dialog for the user to cancel participation in an approved carpool.
  /// Allows selecting a predefined reason or entering a custom one.
  Future<void> _showCancelParticipationDialog({
    required String carpoolId,
    required String requesterId,
    required String requestId,
  }) async {
    final List<String> predefinedReasons = [
      "Change of plans",
      "Duplicate request",
      "No longer needed",
    ];

    String? selectedReason;
    TextEditingController customReasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Cancel Participation"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...predefinedReasons.map((reason) => RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) => setState(() {
                          selectedReason = value;
                        }),
                      )),
                  TextField(
                    controller: customReasonController,
                    decoration: InputDecoration(
                      labelText: "Other reason (optional)",
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close"),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = selectedReason?.isNotEmpty == true
                    ? selectedReason!
                    : customReasonController.text.trim();
                Navigator.of(context).pop(reason);
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _firebaseFunctions.cancelApprovedJoinRequest(
        carpoolId: carpoolId,
        requesterId: requesterId,
        requestId: requestId,
        reason: result,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Participation cancelled.")),
      );

      _loadExploreCarpools(); // Refresh the UI
    }
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
