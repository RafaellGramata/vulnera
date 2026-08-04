import '../services/asset_service.dart';
import '../services/vulnerability_service.dart';
import '../models/website_finding.dart';

class WebsiteScanIntegrationService {
  final AssetService _assetService = AssetService();
  final VulnerabilityService _vulnService = VulnerabilityService();

  Future<void> importFindings(String url, List<WebsiteFinding> findings) async {
    // clean up the url into a shorter display name for the asset
    var displayName = url.trim();
    displayName = displayName
        .replaceAll('https://', '')
        .replaceAll('http://', '');
    if (displayName.endsWith('/')) {
      displayName = displayName.substring(0, displayName.length - 1);
    }

    final assetId = await _assetService.addAssetAndReturnId(
      displayName,
      'Web Application',
    );

    for (final finding in findings) {
      await _vulnService.addVulnerability(
        assetId: assetId,
        title: finding.title,
        description: finding.description,
        severity: finding.severity,
        cvssScore: finding.cvssScore,
        status: 'Open',
        notes: 'Auto-detected by Website Security Scanner.',
      );
    }
  }
}
