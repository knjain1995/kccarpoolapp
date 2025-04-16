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

  /// 📦 Approves a join request
  Future<void> _approveRequest(String carpoolId, String userId) async {
    try {
      await _firebaseFunctions.approveJoinRequest(carpoolId, userId);
      _loadJoinRequests(); // Refresh
    } catch (e) {
      final message = e.toString().contains("full")
          ? "This carpool is already at full capacity."
          : "Failed to approve request.";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// 🛑 Denies a join request
  Future<void> _denyRequest(String carpoolId, String userId) async {
    try {
      await _firebaseFunctions.denyJoinRequest(carpoolId, userId);
      _loadJoinRequests(); // Refresh the list
    } catch (e) {
      print("Denial failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to deny request")),
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
                                      backgroundImage: user['profilePhoto'] != null
                                          ? NetworkImage(user['profilePhoto'])
                                          : null,
                                      child: user['profilePhoto'] == null
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
                                          onPressed: () => _approveRequest(
                                              carpool['carpoolId'], user['userId']),
                                          tooltip: "Approve",
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.close, color: Colors.red),
                                          onPressed: () => _denyRequest(
                                              carpool['carpoolId'], user['userId']),
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
