import 'package:eli5/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';


class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ELI5", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Box
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Explain...",
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              tabs: const [
                Tab(text: "Like I’m 5"),
                Tab(text: "Like I’m 15"),
                Tab(text: "Like I’m an Adult"),
              ],
            ),

            const SizedBox(height: 12),

            // Main content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExplanationText(
                    "Imagine you have a big box of toys, and you want to find your favorite one, a shiny red car. "
                    "Searching is like looking through the box to find that car. You look at each toy until you find "
                    "the one you want. On the computer, searching is the same, but instead of toys, you’re looking "
                    "for information, like pictures of cats or the answer to a question. The computer looks through "
                    "all the information it has until it finds what you’re looking for."
                  ),
                  _buildExplanationText("Like I’m 15 explanation here..."),
                  _buildExplanationText("Like I’m an Adult explanation here..."),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.bookmark_border, "Save"),
                _buildActionButton(Icons.refresh, "Regenerate"),
                _buildActionButton(Icons.share, "Share"),
              ],
            ),
          ],
        ),
      ),

      // Reusable Bottom Navigation Bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          // TODO: Add navigation logic here
        },
      ),
    );
  }

  Widget _buildExplanationText(String text) {
    return SingleChildScrollView(
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, height: 1.4),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[200],
          child: Icon(icon, color: Colors.black),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
