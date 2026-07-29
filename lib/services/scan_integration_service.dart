import '../services/asset_service.dart';
import '../services/vulnerability_service.dart';
import 'port_severity_mapper.dart';

class ScanIntegrationService {
  final AssetService _assetService = AssetService();
  final VulnerabilityService _vulnService = VulnerabilityService();

  // takes raw scan results (ip -> list of open ports) and turns them
  // into real assets and vulnerabilities, reusing the exact same
  // services every other part of the app uses to write data
  Future<void> importScanResults(Map<String, List<int>> scanResults) async {
    for (final entry in scanResults.entries) {
      final ip = entry.key;
      final openPorts = entry.value;

      // create a new asset for this discovered device -
      // named after its ip since we don't have a hostname
      final assetId = await _assetService.addAssetAndReturnId(
        'Device $ip',
        'Network Device',
      );

      // for each open port found on this device, create a matching
      // vulnerability using the severity mapping we already built
      for (final port in openPorts) {
        final finding = PortSeverityMapper.findingForPort(port);

        await _vulnService.addVulnerability(
          assetId: assetId,
          title: finding.title,
          description: finding.description,
          severity: finding.severity,
          cvssScore: finding.cvssScore,
          status: 'Open',
          notes: 'Auto-detected by Network Scanner on $ip.',
        );
      }
    }
  }
}