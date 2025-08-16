import 'dart:io';
import 'package:eli5/screens/discover_screen.dart';
import 'package:eli5/screens/history_screen.dart';
import 'package:eli5/screens/knowledge_screen.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;
  const BottomNavBar({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const DiscoverScreen(),
    const KnowledgeScreen(),
    HistoryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: SizedBox(
        height: kIsWeb ? 70 : Platform.isIOS ? 95 : 90,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.black,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xffFFA775),
          unselectedItemColor: Colors.white,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(FluentIcons.home_12_filled, size: 28), label: ''),
            BottomNavigationBarItem(icon: Icon(FluentIcons.compass_northwest_16_regular, size: 28), label: ''),
            BottomNavigationBarItem(icon: Icon(FluentIcons.data_trending_16_filled, size: 28), label: ''),
            BottomNavigationBarItem(icon: Icon(FluentIcons.library_16_filled, size: 28), label: ''),
          ],
        ),
      ),
    );
  }
}
