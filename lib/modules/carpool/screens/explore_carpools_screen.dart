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

  /// 🔄 Loads carpools from Firestore, along with the user's join request status and flags.
  Future<void> _loadExploreCarpools() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      final userId = currentUser.uid;
      final requestIdPattern = "_$userId";

      final carpoolsQuery = await FirebaseFirestore.instance
          .collection("carpools")
          .where("carpoolOwnerId", isNotEqualTo: userId) // exclude own carpools
          .get();

      final List<Map<String, dynamic>> result = [];

      for (var doc in carpoolsQuery.docs) {
        final carpool = doc.data();
        carpool['carpoolId'] = doc.id;

        final requestId = "${doc.id}_$userId";
        final joinRequestSnap = await FirebaseFirestore.instance
            .collection("joinRequests")
            .doc(requestId)
            .get();

        // Default to "not requested"
        carpool['joinRequestStatus'] = null;
        carpool['approvedRequestId'] = null;
        carpool['isCancelled'] = false;
        carpool['isReconsiderationRequested'] = false;

        if (joinRequestSnap.exists) {
          final data = joinRequestSnap.data()!;
          final status = data['status'];
          carpool['joinRequestStatus'] = status;

          if (status == 'approved') {
            carpool['approvedRequestId'] = requestId;
          }
        }

        // 🔍 Check if the requestId is in cancelled or reconsideration arrays
        final cancelledIds = List<String>.from(carpool['cancelledRequestIds'] ?? []);
        final reconsiderationIds = List<String>.from(carpool['reconsiderationRequestIds'] ?? []);

        if (cancelledIds.contains(requestId)) {
          carpool['isCancelled'] = true;
        }

        if (reconsiderationIds.contains(requestId)) {
          carpool['isReconsiderationRequested'] = true;
        }

        result.add(carpool);
      }

      setState(() {
        _carpools = result;
      });
    } catch (e) {
      print("Error loading explore carpools: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load carpools.")),
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


  /// 🧠 Determines which action button to show based on the user's request status with this carpool.
  Widget _buildActionButton(Map<String, dynamic> carpool) {
    final String? status = carpool['joinRequestStatus'];
    final bool isCancelled = carpool['isCancelled'] == true;
    final bool isReconsiderationRequested = carpool['isReconsiderationRequested'] == true;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // ✅ Approved — show Cancel Participation
    if (status == "approved") {
      return ElevatedButton.icon(
        icon: Icon(Icons.close),
        label: Text("Cancel Participation"),
        onPressed: () {
          final requestId = carpool['approvedRequestId'];

          if (requestId != null && currentUserId != null) {
            _showCancelParticipationDialog(
              carpoolId: carpool['carpoolId'],
              requesterId: currentUserId,
              requestId: requestId,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Missing request or user ID")),
            );
          }
        },
      );
    }

    // 🔁 Reconsideration already requested — disable button
    if (status == "reconsideration_requested" || isReconsiderationRequested) {
      return ElevatedButton.icon(
        icon: Icon(Icons.hourglass_top),
        label: Text("Reconsideration Sent"),
        onPressed: null, // ❌ Disabled
      );
    }

    // ❌ Request was cancelled — disable button
    if (status == "cancelled" || isCancelled) {
      return ElevatedButton.icon(
        icon: Icon(Icons.cancel),
        label: Text("Request Cancelled"),
        onPressed: null, // ❌ Disabled
      );
    }

    // ⏳ Pending — show Cancel Request
    if (status == "pending") {
      return ElevatedButton.icon(
        icon: Icon(Icons.cancel),
        label: Text("Cancel Request"),
        onPressed: () => _handleCancelRequest(carpool['carpoolId']),
      );
    }

    // ⛔ Denied — show Request Reconsideration
    if (status == "denied") {
      return ElevatedButton.icon(
        icon: Icon(Icons.refresh),
        label: Text("Request Reconsideration"),
        onPressed: () => FirebaseFunctions().requestReconsideration(carpool['carpoolId']),
      );
    }

    // 🤝 No request exists — show Request to Join
    return ElevatedButton.icon(
      icon: Icon(Icons.group_add),
      label: Text("Request to Join"),
      onPressed: () => _handleJoinRequest(carpool['carpoolId']),
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

  /// ❌ Shows the cancel participation confirmation dialog and performs the cancellation.
  /// Now supports updated backend method that requires memberUserIds.
  Future<void> _showCancelParticipationDialog({
    required String carpoolId,
    required String requesterId,
    required String requestId,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cancel Participation"),
        content: Text("Are you sure you want to cancel your participation in this carpool?"),
        actions: [
          TextButton(
            child: Text("No"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text("Yes"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 🔍 Step 1: Fetch the join request to extract memberUserIds
      final doc = await FirebaseFirestore.instance
          .collection("joinRequests")
          .doc(requestId)
          .get();

      if (!doc.exists || !(doc.data()?['memberUserIds'] is List)) {
        throw Exception("Unable to fetch members from join request.");
      }

      final List<String> memberUserIds =
          List<String>.from(doc.data()?['memberUserIds'] ?? []);

      // 🔧 Step 2: Call cancel method with all required fields
      await FirebaseFunctions().cancelApprovedJoinRequest(
        carpoolId: carpoolId,
        requestId: requestId,
        memberUserIds: memberUserIds,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Participation cancelled.")),
      );

      // 🔁 Optional refresh
      _loadExploreCarpools?.call();
    } catch (e) {
      print("Error cancelling participation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to cancel participation.")),
      );
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