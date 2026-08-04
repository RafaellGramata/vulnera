import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import '../widgets/theme_toggle_button.dart';

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
      appBar: AppBar(
        title: const Text('Manage users'),
        actions: const [ThemeToggleButton()],
      ),
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

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = users[index];

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: _roleColor(user.role),
                    child: Text(
                      user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    user.email,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('Access level: ${user.role}'),
                  trailing: DropdownButton<String>(
                    value: user.role,
                    underline: const SizedBox.shrink(),
                    items: _roles.map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (newRole) async {
                      if (newRole == null || newRole == user.role) return;

                      try {
                        await userService.updateUserRole(user.uid, newRole);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${user.email} is now $newRole'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to update role. Admin access required.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
