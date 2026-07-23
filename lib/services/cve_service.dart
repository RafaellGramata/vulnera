import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_keys.dart';

// this class holds the pieces of cve data we care about,
// separate from our Vulnerability model since this is raw data from NVD
class CveResult {
  final String description;
  final double cvssScore;
  final String severity;

  CveResult({
    required this.description,
    required this.cvssScore,
    required this.severity,
  });
}

class CveService {
  static const String _baseUrl =
      'https://services.nvd.nist.gov/rest/json/cves/2.0';

  // if we got an api key from nvd, paste it here between the quotes
  // leave it empty ('') if we don't have one yet
  static const String _apiKey = nvdApiKey;

  // looks up a single cve by id, like "CVE-2021-44228"
  // returns null if it wasn't found or something went wrong
  Future<CveResult?> lookupCve(String cveId) async {
    final trimmedId = cveId.trim().toUpperCase();

    final url = Uri.parse('$_baseUrl?cveId=$trimmedId');

    // headers can include our api key, if we have one
    final headers = <String, String>{};
    if (_apiKey.isNotEmpty) {
      headers['apiKey'] = _apiKey;
    }

    // temporary debug lines
    print('Requesting URL: $url');
    print('API key length: ${_apiKey.length}');
    print('Headers: $headers');

    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      // temporary debug line - tells us exactly what went wrong
      print('NVD lookup failed. Status: ${response.statusCode}, Body: ${response.body}');
      return null;
    }

    final data = jsonDecode(response.body);
    final vulnerabilities = data['vulnerabilities'] as List;

    if (vulnerabilities.isEmpty) {
      // the cve id doesn't exist in nvd's database
      return null;
    }

    final cve = vulnerabilities[0]['cve'];

    // grab the english description
    final descriptions = cve['descriptions'] as List;
    final englishDescription = descriptions.firstWhere(
          (d) => d['lang'] == 'en',
      orElse: () => {'value': 'No description available.'},
    );

    // try to get cvss v3.1 data first, since it's the most modern standard
    // some older cves only have v3.0 or v2, so we check those next as fallback
    double cvssScore = 0.0;
    String severity = 'Low';

    final metrics = cve['metrics'] as Map<String, dynamic>? ?? {};

    if (metrics.containsKey('cvssMetricV31')) {
      final cvssData = metrics['cvssMetricV31'][0]['cvssData'];
      cvssScore = (cvssData['baseScore'] ?? 0).toDouble();
      severity = _capitalizeSeverity(cvssData['baseSeverity']);
    } else if (metrics.containsKey('cvssMetricV30')) {
      final cvssData = metrics['cvssMetricV30'][0]['cvssData'];
      cvssScore = (cvssData['baseScore'] ?? 0).toDouble();
      severity = _capitalizeSeverity(cvssData['baseSeverity']);
    } else if (metrics.containsKey('cvssMetricV2')) {
      final cvssData = metrics['cvssMetricV2'][0]['cvssData'];
      cvssScore = (cvssData['baseScore'] ?? 0).toDouble();
      // cvss v2 doesn't include a severity label, so we estimate it from the score
      severity = _estimateSeverityFromScore(cvssScore);
    }
    // if none of the above exist, this cve has no cvss data at all,
    // so we just leave it at the defaults (0.0, Low)

    return CveResult(
      description: englishDescription['value'],
      cvssScore: cvssScore,
      severity: severity,
    );
  }

  // nvd returns severity in all caps, like "CRITICAL" - we just clean that up
  String _capitalizeSeverity(String? severity) {
    if (severity == null || severity.isEmpty) return 'Low';
    return severity[0].toUpperCase() + severity.substring(1).toLowerCase();
  }

  // only used for old cvss v2 entries, which don't include a severity label directly
  String _estimateSeverityFromScore(double score) {
    if (score >= 9.0) return 'Critical';
    if (score >= 7.0) return 'High';
    if (score >= 4.0) return 'Medium';
    return 'Low';
  }
}