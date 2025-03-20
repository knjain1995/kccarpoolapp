// Filename: home_screen.dart  Location: lib/modules/home/screens/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/core/routes.dart';
import 'package:kccarpoolapp/services/auth_service.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart'; // Import AuthService

/// HomeScreen - Main screen after user logs in.
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope( // Prevents back navigation
      onWillPop: () async => false, // Disable back button on Android
      child: Scaffold(
        appBar: AppBar(
          title: Text("Home"),
          automaticallyImplyLeading: false, // Removes back button
          actions: [
            /// Profile button to navigate to the profile screen
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.profile);
              },
              tooltip: "Profile",
            ),

            /// Logout button in the app bar
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                AuthService().logout(context);
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              },
              tooltip: "Logout",
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Create Carpool Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.createCarpool);
                },
                icon: Icon(Icons.add_circle_outline),
                label: Text("Create Carpool"),
              ),

              ElevatedButton(
  onPressed: () async {
    try {
      await FirebaseFunctions().createCarpool(
        carpoolName: "School Pickup",
        carpoolRouteStart: "Home",
        carpoolRouteEnd: "ABC School",
        carpoolDate: Timestamp.now(),
        carpoolTime: Timestamp.now(),
        carpoolVehicleId: "xyz987",
        carpoolOwnerId: "user123",
        carpoolDriverId: "user456",
        carpoolCapacity: 4,
        carpoolReturnTrip: false,
      );
      print("Carpool added successfully!");
    } catch (e) {
      print("Error: $e");
    }
  },
  child: Text("Test Create Carpool"),
),
            ],
          ),
        ),
      ),
    ); // ✅ Corrected closing brackets
  }
}



//  /// Logout button in the app bar
//             IconButton(
//               icon: Icon(Icons.logout),
//               onPressed: () => AuthService().logout(context), // Use AuthService
//               tooltip: "Logout",
//             ),