import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/asset_service.dart';
import '../services/auth_service.dart';
import '../widgets/theme_toggle_button.dart';
import 'add_edit_asset_screen.dart';
import 'asset_detail_screen.dart';
import 'login_screen.dart';
import 'manage_users_screen.dart';
import 'notification_bell.dart';

class HomeScreen extends StatelessWidget {
  final String role;
  const HomeScreen({super.key, required this.role});

  IconData _assetIcon(String type) {
    switch (type) {
      case 'Server':
        return Icons.dns_outlined;
      case 'Laptop':
        return Icons.laptop_mac_outlined;
      case 'Desktop':
        return Icons.desktop_windows_outlined;
      case 'Network Device':
        return Icons.router_outlined;
      case 'Web Application':
        return Icons.language_outlined;
      default:
        return Icons.devices_other_outlined;
    }
  }

  Color _riskColor(double score) {
    if (score >= 9) return const Color(0xFFDC2626);
    if (score >= 7) return const Color(0xFFEA580C);
    if (score >= 4) return const Color(0xFFD97706);
    return const Color(0xFF059669);
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final assetService = AssetService();
    final canEdit = role == 'Admin' || role == 'Analyst';
    final canDelete = role == 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assets'),
            Text(
              'Security inventory',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          NotificationBell(role: role),
          if (role == 'Admin')
            IconButton(
              icon: const Icon(Icons.manage_accounts_outlined),
              tooltip: 'Manage users',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageUsersScreen(),
                ),
              ),
            ),
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              await authService.logOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Asset>>(
        stream: assetService.getAssets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final assets = snapshot.data ?? [];
          if (assets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 58,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No assets yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      canEdit
                          ? 'Add your first asset or import one from a security scan.'
                          : 'Your security inventory will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: assets.length + 1,
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 0 ? 16 : 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Row(
                  children: [
                    Text(
                      '${assets.length} asset${assets.length == 1 ? '' : 's'} monitored',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Chip(
                      avatar: const Icon(
                        Icons.verified_user_outlined,
                        size: 17,
                      ),
                      label: Text(role),
                    ),
                  ],
                );
              }

              final asset = assets[index - 1];
              final riskColor = _riskColor(asset.riskScore);
              return Dismissible(
                key: Key(asset.id),
                direction: canDelete
                    ? DismissDirection.endToStart
                    : DismissDirection.none,
                background: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 22),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => assetService.deleteAsset(asset.id),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _assetIcon(asset.type),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      asset.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${asset.type}  •  ${asset.openIssueCount} open',
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        asset.riskScore.toStringAsFixed(1),
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AssetDetailScreen(asset: asset, role: role),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditAssetScreen(),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add asset'),
            )
          : null,
    );
  }
}
