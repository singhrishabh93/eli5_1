import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Favorites")),
      body: ListView(
        children: [
          ListTile(title: Text("Task Breakdown")),
          ListTile(title: Text("Decision Making")),
          ListTile(title: Text("Brainstorming")),
          ListTile(title: Text("Problem Solving")),
          ListTile(title: Text("Prioritization Matrix")),
        ],
      ),
    );
  }
}