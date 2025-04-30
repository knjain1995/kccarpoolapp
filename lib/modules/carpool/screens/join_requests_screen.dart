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

                      return Card(
                        margin: EdgeInsets.all(12),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🚌 Carpool name
                              Text(
                                carpool['carpoolName'] ?? "Unnamed Carpool",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 12),

                              // 🔁 Loop over all requesters for this carpool
                              ...requesters.map((user) => ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: user['profilePhoto'] != null && user['profilePhoto'].toString().isNotEmpty
                                        ? FileImage(File(user['profilePhoto']))
                                        : null,
                                      child: (user['profilePhoto'] == null || user['profilePhoto'].toString().isEmpty)
                                        ? Icon(Icons.person)
                                        : null,
                                    ),
                                    title: Text(user['fullName']),
                                    subtitle: Text("Relation: ${user['relationToChild']}"),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.check, color: Colors.green),
                                          onPressed: () {
                                            if (user['userId'] != null && user['requestId'] != null && user['memberUserIds'] != null) {
                                              _approveRequest(
                                                carpoolId: carpool['carpoolId'],
                                                requesterId: user['userId'],
                                                requestId: user['requestId'],
                                                memberUserIds: List<String>.from(user['memberUserIds']),
                                              );
                                            } else {
                                              print("❗ Missing fields in join request: $user");
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text("Incomplete join request data. Cannot approve.")),
                                              );
                                            }
                                          },
                                          tooltip: "Approve",
                                        ),
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
                                    ),
                                  )),
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
