import 'package:flutter/material.dart';

/// HomeScreen - Placeholder for the main app after login.
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Center(
        child: Text("Welcome to the Home Screen!"),
      ),
    );
  }
}
