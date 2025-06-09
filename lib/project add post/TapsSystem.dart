import 'package:flutter/material.dart';
import 'ProjectAdd.dart';

class BottomTabs extends StatefulWidget {
  @override
  TapsSystem createState() => TapsSystem();
}

class TapsSystem extends State<BottomTabs> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    ProjectAdd(),
    Center(child: Text("Home Page")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}
