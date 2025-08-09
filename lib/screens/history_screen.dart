import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("History")),
      body: ListView(
        children: [
          ListTile(title: Text("Operating System")),
          ListTile(title: Text("Internet")),
          ListTile(title: Text("JavaScript")),
          ListTile(title: Text("Database")),
          ListTile(title: Text("Compilation")),
        ],
      ),
    );
  }
}