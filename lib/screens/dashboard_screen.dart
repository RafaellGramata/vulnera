import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/asset.dart';
import '../services/asset_service.dart';
import '../services/dashboard_service.dart';
import '../services/pdf_report_service.dart';
import '../widgets/theme_toggle_button.dart';
import 'scan_center_screen.dart';
import 'website_scan_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String role;
  const DashboardScreen({super.key, required this.role});

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return const Color(0xFFDC2626);
      case 'High':
        return const Color(0xFFEA580C);
      case 'Medium':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF059669);
    }
  }

  String _severityBucketForScore(double score) {
    if (score >= 9.0) return 'Critical';
    if (score >= 7.0) return 'High';
    if (score >= 4.0) return 'Medium';
    return 'Low';
  }

  Future<void> _handleExportPdf(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    final pdfBytes = await PdfReportService().generateReport();
    if (context.mounted) Navigator.pop(context);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(pdfBytes),
      filename: 'vulnera-report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetService = AssetService();
    final dashboardService = DashboardService();
    final canScan = role == 'Admin' || role == 'Analyst';

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard'),
            Text(
              'Risk overview',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF report',
            onPressed: () => _handleExportPdf(context),
          ),
          const ThemeToggleButton(),
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
              child: Text('Add assets to populate your risk dashboard.'),
            );
          }

          return StreamBuilder<Map<String, int>>(
            stream: dashboardService.getSeverityCounts(
              assets.map((asset) => asset.id).toList(),
            ),
            builder: (context, severitySnapshot) {
              final counts =
                  severitySnapshot.data ??
                  {'Critical': 0, 'High': 0, 'Medium': 0, 'Low': 0};
              final totalOpen = counts.values.fold(
                0,
                (sum, count) => sum + count,
              );
              final highestRisk = assets.fold<double>(
                0,
                (highest, asset) =>
                    asset.riskScore > highest ? asset.riskScore : highest,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'Assets',
                            value: '${assets.length}',
                            icon: Icons.devices_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricCard(
                            label: 'Open findings',
                            value: '$totalOpen',
                            icon: Icons.bug_report_outlined,
                            color: _severityColor(
                              totalOpen > 0 ? 'High' : 'Low',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricCard(
                            label: 'Top risk',
                            value: highestRisk.toStringAsFixed(1),
                            icon: Icons.shield_outlined,
                            color: _severityColor(
                              _severityBucketForScore(highestRisk),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (canScan) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Security tools',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ToolButton(
                              icon: Icons.wifi_find_rounded,
                              title: 'Network scan',
                              subtitle: 'Discover open ports',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ScanCenterScreen(role: role),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ToolButton(
                              icon: Icons.language_rounded,
                              title: 'Website scan',
                              subtitle: 'Review security headers',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      WebsiteScanScreen(role: role),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    _ChartCard(
                      title: 'Open vulnerabilities',
                      subtitle: 'Current findings grouped by severity',
                      child: totalOpen == 0
                          ? const SizedBox(
                              height: 180,
                              child: Center(
                                child: Text(
                                  'No open vulnerabilities. Nice work!',
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 230,
                              child: PieChart(
                                PieChartData(
                                  sections: counts.entries
                                      .where((entry) => entry.value > 0)
                                      .map(
                                        (entry) => PieChartSectionData(
                                          color: _severityColor(entry.key),
                                          value: entry.value.toDouble(),
                                          title: '${entry.key}\n${entry.value}',
                                          radius: 76,
                                          titleStyle: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 34,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _ChartCard(
                      title: 'Risk by asset',
                      subtitle:
                          'Highest active CVSS score • Tap or hover over a bar for asset details',
                      child: SizedBox(
                        height: 260,
                        child: BarChart(
                          BarChartData(
                            maxY: 10,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipRoundedRadius: 10,
                                tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                maxContentWidth: 220,
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                getTooltipColor: (_) => Theme.of(
                                  context,
                                ).colorScheme.inverseSurface,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  if (group.x < 0 || group.x >= assets.length) {
                                    return null;
                                  }
                                  final textColor = Theme.of(
                                    context,
                                  ).colorScheme.onInverseSurface;
                                  return BarTooltipItem(
                                    '${assets[group.x].name}\n',
                                    TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            'Risk score ${rod.toY.toStringAsFixed(1)}',
                                        style: TextStyle(
                                          color: textColor.withValues(
                                            alpha: 0.82,
                                          ),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            barGroups: List.generate(
                              assets.length,
                              (index) => BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: assets[index].riskScore,
                                    color: _severityColor(
                                      _severityBucketForScore(
                                        assets[index].riskScore,
                                      ),
                                    ),
                                    width: 18,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: false,
                                  reservedSize: 38,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= assets.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final name = assets[index].name;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text(
                                        name.length > 8
                                            ? '${name.substring(0, 8)}…'
                                            : name,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(
                              show: true,
                              drawVerticalLine: false,
                            ),
                          ),
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ToolButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}
