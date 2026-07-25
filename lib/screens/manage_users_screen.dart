import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  final List<String> _roles = const ['Admin', 'Analyst', 'Viewer'];

  Color _roleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.red;
      case 'Analyst':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: StreamBuilder<List<AppUser>>(
        stream: userService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _roleColor(user.role),
                  child: Text(
                    user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user.email),
                // dropdown lets an admin change this user's role directly
                trailing: DropdownButton<String>(
                  value: user.role,
                  items: _roles.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (newRole) async {
                    if (newRole == null || newRole == user.role) return;

                    try {
                      await userService.updateUserRole(user.uid, newRole);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${user.email} is now $newRole')),
                        );
                      }
                    } catch (e) {
                      // this will happen if firestore rules reject the update -
                      // e.g. if the current logged in user somehow isn't actually an admin
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to update role. Admin access required.')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}