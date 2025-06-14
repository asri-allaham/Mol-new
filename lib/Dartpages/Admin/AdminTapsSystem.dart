import 'package:Mollni/Dartpages/Admin/Contracts.dart';
import 'package:Mollni/Dartpages/Admin/Adminacceptance.dart';
import 'package:Mollni/Dartpages/Admin/Reports.dart';
import 'package:flutter/material.dart';

class Admintapssystem extends StatefulWidget {
  Admintapssystem(
      List<Map<String, dynamic>> projects, List<Map<String, dynamic>> posts);

  @override
  TapsSystem createState() => TapsSystem();
}

class TapsSystem extends State<Admintapssystem> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    DashBoard(),
    Adminacceptance(),
    ContractsManage(),
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
            icon: Icon(Icons.report),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_sharp),
            label: 'Admin acceptance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_sharp),
            label: 'Contracts  managing',
          ),
        ],
      ),
    );
  }
}
