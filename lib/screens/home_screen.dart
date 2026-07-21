import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/asset_service.dart';
import '../models/asset.dart';
import 'login_screen.dart';
import 'add_edit_asset_screen.dart';
import 'asset_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final assetService = AssetService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vulnera'),
        actions: [
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

              // dismissible lets us swipe the item left to delete it
              return Dismissible(
                key: Key(asset.id),
                direction: DismissDirection.endToStart,
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
                        builder: (context) => AssetDetailScreen(asset: asset),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditAssetScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}