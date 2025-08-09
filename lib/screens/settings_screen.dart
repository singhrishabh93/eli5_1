import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(title: Text("Appearance")),
          ListTile(title: Text("Theme"), subtitle: Text("System")),
          SwitchListTile(
            title: Text("Push Notifications"),
            value: true, // Update based on user settings
            onChanged: (value) {},
          ),
          ListTile(title: Text("Manage Account")),
          ListTile(title: Text("Log Out")),
        ],
      ),
    );
  }
}