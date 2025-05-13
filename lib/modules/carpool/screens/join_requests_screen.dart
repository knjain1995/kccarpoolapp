import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart'; // Your Firestore abstraction
import 'package:kccarpoolapp/core/routes.dart'; // For navigation

/// 📥 Screen to show all incoming join requests for carpools owned by the current user.
class JoinRequestsScreen extends StatefulWidget {
  @override
  _JoinRequestsScreenState createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();

  List<Map<String, dynamic>> _carpoolsWithRequests = []; // Each map contains carpool data + requesters
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJoinRequests(); // Fetch data when the screen loads
  }

  /// 🔄 Loads all join requests for carpools owned by the current user
  Future<void> _loadJoinRequests() async {
    setState(() => _isLoading = true);

    try {
      final List<Map<String, dynamic>> results = await _firebaseFunctions.getJoinRequestsForOwner();

      setState(() {
        _carpoolsWithRequests = results;
      });
    } catch (e) {
      print("Failed to load join requests: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading join requests")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🛡️ Called when the carpool owner approves a join request
  /// 🎯 Updated _approveRequest method
  Future<void> _approveRequest({
    required String carpoolId,
    required String requesterId,
    required String requestId,
    required List<String> memberUserIds,
  }) async {
    try {
      await _firebaseFunctions.approveJoinRequest(
        carpoolId: carpoolId,
        requesterId: requesterId,
        requestId: requestId,
        memberUserIds: memberUserIds,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request approved!')),
      );

      _loadJoinRequests(); // 🔁 Refresh join requests
    } catch (e) {
      print('Error approving request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve request.')),
      );
    }
  }

  /// ❌ Updated _denyRequest method
  Future<void> _denyRequest({
    required String carpoolId,
    required String requesterId,
    required String requestId,
  }) async {
    try {
      await _firebaseFunctions.denyJoinRequest(
        carpoolId: carpoolId,
        requesterId: requesterId,
        requestId: requestId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request denied.')),
      );

      _loadJoinRequests(); // 🔄 Refresh join requests
    } catch (e) {
      print('Error denying request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to deny request.')),
      );
    }
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
                  // 🔘 Radio buttons for predefined reasons
                  ...predefinedReasons.map((reason) => RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) => setState(() {
                          selectedReason = value;
                        }),
                      )),

                  // ✍️ Optional custom reason
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
              onPressed: () => Navigator.of(context).pop(), // ❌ Cancel
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
      await _cancelApprovedRequest(
        carpoolId: carpoolId,
        requesterId: requesterId,
        requestId: requestId,
        reason: result,
      );
    }
  }

  /// 🔁 Cancels an approved join request
  Future<void> _cancelApprovedRequest({
    required String carpoolId,
    required String requesterId,
    required String requestId,
    required String reason,
  }) async {
    try {
      await _firebaseFunctions.cancelApprovedJoinRequest(
        carpoolId: carpoolId,
        requesterId: requesterId,
        requestId: requestId,
        reason: reason,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Participation cancelled.")),
      );

      _loadJoinRequests(); // 🔄 Refresh screen
    } catch (e) {
      print("Error cancelling participation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to cancel participation.")),
      );
    }
  }



  /// 🔧 This helper method builds a single list tile for a user who has requested to join a carpool.
  /// It changes its trailing buttons based on the request status.
  /// 
  /// Parameters:
  /// - `user`: the user map (from Firestore)
  /// - `carpool`: the carpool map this user wants to join
  /// - `showApproveDeny`: whether to show ✅ Approve / ❌ Deny buttons (for 'pending' status)
  /// - `showCancel`: whether to show ❌ Cancel button (for 'approved' status)
  /// - `showReconsider`: whether to show 🔁 Request Reconsideration button (for 'denied' status)
  Widget _buildUserTile(
    dynamic user,
    Map<String, dynamic> carpool, {
    bool showApproveDeny = false,
    bool showCancel = false,
    bool showReconsider = false,
  }) {
    return ListTile(
      // 👤 Show profile photo or fallback icon
      leading: CircleAvatar(
        backgroundImage: user['profilePhoto'] != null && user['profilePhoto'].toString().isNotEmpty
            ? FileImage(File(user['profilePhoto']))
            : null,
        child: (user['profilePhoto'] == null || user['profilePhoto'].toString().isEmpty)
            ? Icon(Icons.person)
            : null,
      ),

      // 📛 Display user's full name
      title: Text(user['fullName']),

      // 👪 Show relation to child (stored in user profile)
      subtitle: Text("Relation: ${user['relationToChild']}"),

      // 🎯 Buttons (Approve, Deny, Cancel, Reconsider) depending on status
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showApproveDeny) ...[
            // ✅ Approve Button
            IconButton(
              icon: Icon(Icons.check, color: Colors.green),
              onPressed: () {
                _approveRequest(
                  carpoolId: carpool['carpoolId'],
                  requesterId: user['userId'],
                  requestId: user['requestId'],
                  memberUserIds: List<String>.from(user['memberUserIds']),
                );
              },
              tooltip: "Approve",
            ),
            // ❌ Deny Button
            IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () {
                _denyRequest(
                  carpoolId: carpool['carpoolId'],
                  requesterId: user['userId'],
                  requestId: user['requestId'],
                );
              },
              tooltip: "Deny",
            ),
          ],
          if (showCancel)
                // ❌ Cancel Participation Button (for approved requests)
            IconButton(
              icon: Icon(Icons.cancel, color: Colors.orange),
              onPressed: () {
                // 🚧 To be implemented in Enhancement 3
                _showCancelParticipationDialog(
                  carpoolId: carpool['carpoolId'],
                  requesterId: user['userId'],
                  requestId: user['requestId'],
                );
              },
              tooltip: "Cancel Participation",
            ),
          if (showReconsider)
            // 🔁 Request Reconsideration Button (for denied requests)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.blue),
              onPressed: () {
                _reconsiderRequest(
                  carpoolId: carpool['carpoolId'],
                  requesterId: user['userId'],
                  requestId: user['requestId'],
                  memberUserIds: List<String>.from(user['memberUserIds']),
                );
              },
              tooltip: "Request Reconsideration",
            ),
        ],
      ),
    );
  }

  /// 🔁 Called when the carpool owner re-approves a previously denied request.
  Future<void> _reconsiderRequest({
    required String carpoolId,
    required String requesterId,
    required String requestId,
    required List<String> memberUserIds,
  }) async {
    try {
      await _firebaseFunctions.reconsiderJoinRequest(
        carpoolId: carpoolId,
        requesterId: requesterId,
        requestId: requestId,
        memberUserIds: memberUserIds,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request reconsidered and approved.')),
      );

      _loadJoinRequests(); // 🔄 Refresh join requests screen
    } catch (e) {
      print('Error reconsidering request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reconsider request.')),
      );
    }
  }


 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Join Requests")),

      body: _isLoading
          ? Center(child: CircularProgressIndicator())

          : _carpoolsWithRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text("No Join Requests", style: TextStyle(fontSize: 20)),
                    ],
                  ),
                )

              : RefreshIndicator(
                  onRefresh: _loadJoinRequests,
                  child: ListView.builder(
                    itemCount: _carpoolsWithRequests.length,
                    itemBuilder: (context, index) {
                      final carpool = _carpoolsWithRequests[index];
                      final List<dynamic> requesters = carpool['joinRequestUsers'] ?? [];

                      // Split users by request status
                      final pendingUsers = requesters.where((u) => u['status'] == 'pending').toList();
                      final approvedUsers = requesters.where((u) => u['status'] == 'approved').toList();
                      final deniedUsers = requesters.where((u) => u['status'] == 'denied').toList();
                      final reconsiderationUsers = requesters.where((u) => u['status'] == 'reconsideration_requested').toList();

                      return Card(
                        margin: EdgeInsets.all(12),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // ✅ Pending Section
                              if (pendingUsers.isNotEmpty) ...[
                                Text("📥 Pending Requests", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Text(
                                  carpool['carpoolName'] ?? "Unnamed Carpool",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                ...pendingUsers.map((user) =>
                                  _buildUserTile(user, carpool, showApproveDeny: true)),
                              ],

                              // ✅ Approved Section
                              if (approvedUsers.isNotEmpty) ...[
                                SizedBox(height: 12),
                                Text("✅ Approved Requests", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Text(
                                  carpool['carpoolName'] ?? "Unnamed Carpool",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                ...approvedUsers.map((user) =>
                                  _buildUserTile(user, carpool, showCancel: true)),
                              ],

                              // ✅ Denied Section
                              if (deniedUsers.isNotEmpty) ...[
                                SizedBox(height: 12),
                                Text("⛔ Denied Requests", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Text(
                                  carpool['carpoolName'] ?? "Unnamed Carpool",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                ...deniedUsers.map((user) =>
                                  _buildUserTile(user, carpool, showReconsider: true)),
                              ],

                              // 🔁 Reconsideration Requests Section
                              if (reconsiderationUsers.isNotEmpty) ...[
                                Text("🔁 Reconsideration Requests",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ...reconsiderationUsers.map((user) =>
                                  _buildUserTile(user, carpool, showApproveDeny: true)
                                ),
                                SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
