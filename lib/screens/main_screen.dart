import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // the screen shown for each tab
  final List<Widget> _screens = const [
    HomeScreen(),
    DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // indexedstack keeps both screens alive in the background,
      // so switching tabs doesn't lose scroll position or reload data
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Assets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}