import 'package:flutter/material.dart';
import '../services/network_scan_service.dart';
import '../services/scan_integration_service.dart';
import '../widgets/theme_toggle_button.dart';

class ScanCenterScreen extends StatefulWidget {
  final String role;
  const ScanCenterScreen({super.key, required this.role});

  @override
  State<ScanCenterScreen> createState() => _ScanCenterScreenState();
}

class _ScanCenterScreenState extends State<ScanCenterScreen> {
  final _scanService = NetworkScanService();
  final _integrationService = ScanIntegrationService();

  bool _isScanning = false;
  String _statusMessage = '';
  int _scannedCount = 0;
  int _totalCount = 0;
  Map<String, List<int>>? _lastResults;
  String? _errorMessage;

  bool get _canScan => widget.role == 'Admin' || widget.role == 'Analyst';

  void _handleScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Detecting network...';
      _errorMessage = null;
      _lastResults = null;
      _scannedCount = 0;
      _totalCount = 0;
    });

    final ip = await _scanService.getDeviceIp();
    final subnet = _scanService.getSubnetPrefix(ip);

    if (subnet == null) {
      setState(() {
        _isScanning = false;
        _errorMessage =
            'Could not detect your network. Make sure you are connected to Wi-Fi.';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Scanning $subnet.0/24 for devices...';
    });

    final results = await _scanService.scanNetwork(
      subnet,
      onProgress: (checked, total) {
        setState(() {
          _scannedCount = checked;
          _totalCount = total;
        });
      },
    );

    setState(() {
      _isScanning = false;
      _lastResults = results;
      _statusMessage = results.isEmpty
          ? 'Scan complete. No open ports found.'
          : 'Scan complete. Found ${results.length} device(s) with open ports.';
    });
  }

  void _handleImport() async {
    if (_lastResults == null || _lastResults!.isEmpty) return;

    setState(() {
      _isScanning = true;
      _statusMessage = 'Adding findings to your assets...';
    });

    await _integrationService.importScanResults(_lastResults!);

    setState(() {
      _isScanning = false;
      _lastResults = null;
      _statusMessage = 'Findings added. Check the Assets tab.';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan results imported as assets and vulnerabilities.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network scanner'),
        actions: const [ThemeToggleButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: !_canScan
            ? const Center(
                child: Text(
                  'Viewers do not have permission to run network scans.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scans devices on your local Wi-Fi network for open ports that may indicate security risks.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  if (!_isScanning)
                    FilledButton.icon(
                      onPressed: _handleScan,
                      icon: const Icon(Icons.wifi_find),
                      label: const Text('Scan Network'),
                    ),

                  if (_isScanning) ...[
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    const SizedBox(height: 12),
                    if (_totalCount > 0)
                      LinearProgressIndicator(
                        value: _scannedCount / _totalCount,
                      )
                    else
                      const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    if (_totalCount > 0)
                      Text(
                        '$_scannedCount / $_totalCount addresses checked',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],

                  if (!_isScanning &&
                      _statusMessage.isNotEmpty &&
                      _lastResults == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(_statusMessage),
                    ),

                  if (_lastResults != null && _lastResults!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _lastResults!.length,
                        itemBuilder: (context, index) {
                          final ip = _lastResults!.keys.elementAt(index);
                          final ports = _lastResults![ip]!;
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 7,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.router_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                ip,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                'Open ports  •  ${ports.join(", ")}',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _handleImport,
                      icon: const Icon(Icons.add_task),
                      label: Text(
                        'Add ${_lastResults!.length} Device(s) as Assets',
                      ),
                    ),
                  ],

                  if (_lastResults != null && _lastResults!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(_statusMessage),
                    ),
                ],
              ),
      ),
    );
  }
}
