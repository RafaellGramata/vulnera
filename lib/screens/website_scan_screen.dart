import 'package:flutter/material.dart';
import '../services/website_scan_service.dart';
import '../services/website_scan_integration_service.dart';
import '../models/website_finding.dart';
import '../widgets/theme_toggle_button.dart';

class WebsiteScanScreen extends StatefulWidget {
  final String role;
  const WebsiteScanScreen({super.key, required this.role});

  @override
  State<WebsiteScanScreen> createState() => _WebsiteScanScreenState();
}

class _WebsiteScanScreenState extends State<WebsiteScanScreen> {
  final _urlController = TextEditingController();
  final _scanService = WebsiteScanService();
  final _integrationService = WebsiteScanIntegrationService();

  bool _isScanning = false;
  List<WebsiteFinding>? _lastFindings;
  String? _errorMessage;

  bool get _canScan => widget.role == 'Admin' || widget.role == 'Analyst';

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

  void _handleScan() async {
    if (_urlController.text.trim().isEmpty) return;

    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _lastFindings = null;
    });

    try {
      final findings = await _scanService.scanUrl(_urlController.text.trim());
      setState(() {
        _isScanning = false;
        _lastFindings = findings;
      });
    } on WebsiteScanException catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = e.message;
      });
    }
  }

  void _handleImport() async {
    if (_lastFindings == null) return;

    setState(() {
      _isScanning = true;
    });

    await _integrationService.importFindings(
      _urlController.text.trim(),
      _lastFindings!,
    );

    setState(() {
      _isScanning = false;
      _lastFindings = null;
      _urlController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Findings added as an asset and vulnerabilities.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Website scanner'),
        actions: const [ThemeToggleButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: !_canScan
            ? const Center(
                child: Text(
                  'Viewers do not have permission to run website scans.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Checks a website for missing security headers and HTTPS enforcement.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          readOnly: _isScanning,
                          decoration: const InputDecoration(
                            labelText: 'Website URL (e.g. example.com)',
                            prefixIcon: Icon(Icons.link_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isScanning
                          ? const CircularProgressIndicator()
                          : FilledButton(
                              onPressed: _handleScan,
                              child: const Text('Scan'),
                            ),
                    ],
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (_lastFindings != null) ...[
                    Text(
                      _lastFindings!.isEmpty
                          ? 'No issues found — all checks passed.'
                          : '${_lastFindings!.length} finding(s):',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _lastFindings!.length,
                        itemBuilder: (context, index) {
                          final finding = _lastFindings![index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _severityColor(
                                  finding.severity,
                                ),
                                child: Text(
                                  finding.cvssScore.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              title: Text(finding.title),
                              subtitle: Text(finding.description),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
                    if (_lastFindings!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: FilledButton.icon(
                          onPressed: _handleImport,
                          icon: const Icon(Icons.add_task),
                          label: const Text('Add as Asset'),
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}
