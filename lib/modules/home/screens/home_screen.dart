import 'package:flutter/material.dart';
import 'package:kccarpoolapp/core/routes.dart';
import 'package:kccarpoolapp/services/auth_service.dart'; // Import AuthService

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
            /// Logout button in the app bar
            IconButton(
              icon: Icon(Icons.logout),
              // onPressed: () async {
              //   await AuthService().logout();
              //   Navigator.of(context).pushReplacementNamed('/login'); // Move navigation here
              // },
              onPressed: () {
                AuthService().logout();
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              },
              tooltip: "Logout",
            ),
          ],
        ),
        body: Center(
          child: Text("Welcome to the Home Screen!"),
        ),
      ),
    );
  }
}



//  /// Logout button in the app bar
//             IconButton(
//               icon: Icon(Icons.logout),
//               onPressed: () => AuthService().logout(context), // Use AuthService
//               tooltip: "Logout",
//             ),