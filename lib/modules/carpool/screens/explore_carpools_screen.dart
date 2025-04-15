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

  /// 🔄 Loads all carpools that the user can request to join
  Future<void> _loadExploreCarpools() async {
    setState(() => _isLoading = true); // 🌀 Show loading spinner

    try {
      // 🔹 Fetch available carpools (based on familyId + participation exclusion)
      final List<Map<String, dynamic>> carpools = await _firebaseFunctions.getExploreCarpools();

      // 🔹 Fetch current user's UID for later use in button state
      final String userId = _firebaseFunctions.getCurrentUserId() ?? "";

      setState(() {
        _carpools = carpools;
        _currentUserId = userId;
      });
    } catch (e) {
      print("Error loading explore carpools: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load carpools. Please try again.")),
      );
    } finally {
      setState(() => _isLoading = false); // ✅ Stop loading
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
