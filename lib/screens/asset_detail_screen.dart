import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/vulnerability.dart';
import '../services/vulnerability_service.dart';
import 'add_edit_asset_screen.dart';
import 'add_edit_vulnerability_screen.dart';
import '../services/asset_service.dart';

class AssetDetailScreen extends StatelessWidget {
  final Asset asset;

  const AssetDetailScreen({super.key, required this.asset});

  // gives each severity level a color, so the list is easier to scan visually
  Color _severityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.yellow[700]!;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vulnService = VulnerabilityService();
    final assetService = AssetService();

    return Scaffold(
      appBar: AppBar(
        title: Text(asset.name),
        actions: [
          // edit icon opens the asset edit form, separate from tapping into vulnerabilities
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditAssetScreen(existingAsset: asset),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<Asset>(
            stream: assetService.getAssetById(asset.id),
            builder: (context, snapshot) {
              // while waiting for fresh data, fall back to the asset we were given
              final liveAsset = snapshot.data ?? asset;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(liveAsset.type, style: const TextStyle(fontSize: 16)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Risk Score: ${liveAsset.riskScore.toStringAsFixed(1)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${liveAsset.openIssueCount} open issue${liveAsset.openIssueCount == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          // streambuilder listens to the live list of vulnerabilities for this asset
          Expanded(
            child: StreamBuilder<List<Vulnerability>>(
              stream: vulnService.getVulnerabilitiesForAsset(asset.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No vulnerabilities yet. Tap + to add one.'),
                  );
                }

                final vulnerabilities = snapshot.data!;

                return ListView.builder(
                  itemCount: vulnerabilities.length,
                  itemBuilder: (context, index) {
                    final vuln = vulnerabilities[index];

                    return Dismissible(
                      key: Key(vuln.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        vulnService.deleteVulnerability(vuln.id, asset.id);
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _severityColor(vuln.severity),
                          child: Text(
                            vuln.cvssScore.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(vuln.title),
                        subtitle: Text('${vuln.severity} · ${vuln.status}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditVulnerabilityScreen(
                                assetId: asset.id,
                                existingVulnerability: vuln,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddEditVulnerabilityScreen(assetId: asset.id),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}