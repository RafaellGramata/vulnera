import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/asset_service.dart';
import '../services/dashboard_service.dart';
import '../models/asset.dart';
import 'package:printing/printing.dart';
import '../services/pdf_report_service.dart';
import 'dart:typed_data';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // gives each severity level a consistent color across the whole app
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

  // figures out which color bucket a risk score falls into for the bar chart
  String _severityBucketForScore(double score) {
    if (score >= 9.0) return 'Critical';
    if (score >= 7.0) return 'High';
    if (score >= 4.0) return 'Medium';
    return 'Low';
  }

  void _handleExportPdf(BuildContext context) async {
    // show a quick loading indicator while the pdf builds
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final pdfService = PdfReportService();
    final pdfBytes = await pdfService.generateReport();

    if (context.mounted) {
      Navigator.pop(context); // close the loading dialog
    }

    // opens the native share/print sheet so the user can save or send the pdf
    await Printing.sharePdf(bytes: Uint8List.fromList(pdfBytes), filename: 'vulnera-report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final assetService = AssetService();
    final dashboardService = DashboardService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF Report',
            onPressed: () => _handleExportPdf(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Asset>>(
        stream: assetService.getAssets(),
        builder: (context, assetSnapshot) {
          if (assetSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final assets = assetSnapshot.data ?? [];

          if (assets.isEmpty) {
            return const Center(
              child: Text('Add some assets to see your dashboard.'),
            );
          }

          final assetIds = assets.map((a) => a.id).toList();

          return StreamBuilder<Map<String, int>>(
            stream: dashboardService.getSeverityCounts(assetIds),
            builder: (context, severitySnapshot) {
              final severityCounts = severitySnapshot.data ??
                  {'Critical': 0, 'High': 0, 'Medium': 0, 'Low': 0};

              final totalOpenVulns =
                  severityCounts.values.fold(0, (sum, count) => sum + count);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Open Vulnerabilities by Severity',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    if (totalOpenVulns == 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No open vulnerabilities right now. Nice work!'),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            sections: severityCounts.entries
                                .where((entry) => entry.value > 0)
                                .map((entry) {
                              return PieChartSectionData(
                                color: _severityColor(entry.key),
                                value: entry.value.toDouble(),
                                title: '${entry.key}\n${entry.value}',
                                radius: 80,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),
                    const Text(
                      'Risk Score by Asset',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 250,
                      child: BarChart(
                        BarChartData(
                          maxY: 10,
                          barGroups: List.generate(assets.length, (index) {
                            final asset = assets[index];
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: asset.riskScore,
                                  color: _severityColor(
                                    _severityBucketForScore(asset.riskScore),
                                  ),
                                  width: 20,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= assets.length) {
                                    return const SizedBox.shrink();
                                  }
                                  // shorten long asset names so they fit under the bar
                                  final name = assets[index].name;
                                  final shortName = name.length > 8
                                      ? '${name.substring(0, 8)}…'
                                      : name;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      shortName,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: true, drawVerticalLine: false),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}