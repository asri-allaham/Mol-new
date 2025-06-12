import 'package:Mollni/Dartpages/projectadd%20post%20Contracts/post.dart';
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
    Post(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Color(0xff0F9655),
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'Project',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet),
            label: 'Post',
          ),
        ],
      ),
    );
  }
}
