import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      extendBodyBehindAppBar: true, // ✅ This is important
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0), // ✅ Fully transparent
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent, // ✅ Prevent Material overlay tint
        title: Text(
          "Library",
          style: GoogleFonts.mulish(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xffFFFFFF),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.add_16_filled, color: Color(0xffFFFFFF)),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Image.asset("assets/bg2.png",
              fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          Padding(
            padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top),
            child: ListView.separated(
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
                    ),
          ),]
      )
    );
  }
}
