import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/asset_service.dart';
import '../models/asset.dart';
import 'login_screen.dart';
import 'add_edit_asset_screen.dart';
import 'asset_detail_screen.dart';
import 'manage_users_screen.dart';

class HomeScreen extends StatelessWidget {
  final String role;
  const HomeScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final assetService = AssetService();
    final canEdit = role == 'Admin' || role == 'Analyst';
    final canDelete = role == 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vulnera'),
        actions: [
          // only admins see this - lets them promote/demote other users
          if (role == 'Admin')
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              tooltip: 'Manage Users',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageUsersScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
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
      // streambuilder listens to the live list of assets and rebuilds when it changes
      body: StreamBuilder<List<Asset>>(
        stream: assetService.getAssets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No assets yet. Tap + to add one.'));
          }

          final assets = snapshot.data!;

          return ListView.builder(
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];

              // dismissible lets us swipe the item left to delete it -
              // only admins are allowed to delete, so we disable the swipe
              // direction entirely for everyone else
              return Dismissible(
                key: Key(asset.id),
                direction: canDelete ? DismissDirection.endToStart : DismissDirection.none,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  assetService.deleteAsset(asset.id);
                },
                child: ListTile(
                  title: Text(asset.name),
                  subtitle: Text(
                    '${asset.type} · Risk Score: ${asset.riskScore.toStringAsFixed(1)} · ${asset.openIssueCount} open',
                  ),
                  onTap: () {
                    // tapping an asset opens its detail screen with the vulnerability list
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssetDetailScreen(asset: asset, role: role),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      // only admins and analysts can add new assets - viewers don't see this button at all
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEditAssetScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}