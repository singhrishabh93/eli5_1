import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  final List<Map<String, String>> historyItems = [
    {
      "title": "Operating System",
      "subtitle": "A system of rules that govern the behavior of a computer."
    },
    {
      "title": "Internet",
      "subtitle":
          "A network of interconnected computers that communicate using a standard..."
    },
    {
      "title": "JavaScript",
      "subtitle": "A programming language used for web development."
    },
    {
      "title": "Database",
      "subtitle": "A method for organizing and storing data."
    },
    {
      "title": "Compilation",
      "subtitle":
          "A process of converting code into machine-readable format."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
      ),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(vertical: 10),
        itemCount: historyItems.length,
        separatorBuilder: (_, __) => SizedBox(height: 4),
        itemBuilder: (context, index) {
          final item = historyItems[index];
          return ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.history, color: Colors.black54),
            ),
            title: Text(
              item["title"]!,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              item["subtitle"]!,
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      )
    );
  }
}
