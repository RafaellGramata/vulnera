import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import '../services/user_service.dart';
import '../models/app_user.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    // fetch the current user's role once here, at the top level,
    // so every screen below can use it without each one re-fetching separately
    return StreamBuilder<AppUser?>(
      stream: userService.getCurrentUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // default to 'Viewer' if something's wrong or missing, since that's
        // the safest fallback - better to under-permission than over-permission
        final role = snapshot.data?.role ?? 'Viewer';

        return _MainTabs(role: role);
      },
    );
  }
}

class _MainTabs extends StatefulWidget {
  final String role;
  const _MainTabs({required this.role});

  @override
  State<_MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<_MainTabs> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(role: widget.role),
      const DashboardScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Assets'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        ],
      ),
    );
  }
}