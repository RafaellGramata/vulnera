import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/asset.dart';
import '../models/vulnerability.dart';
import 'asset_service.dart';
import 'vulnerability_service.dart';

class PdfReportService {
  final AssetService _assetService = AssetService();
  final VulnerabilityService _vulnService = VulnerabilityService();

  // maps severity text to a pdf-compatible color, matching the app's chart colors
  PdfColor _severityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return PdfColors.red;
      case 'High':
        return PdfColors.orange;
      case 'Medium':
        return PdfColors.amber700;
      default:
        return PdfColors.green;
    }
  }

  // builds the full pdf document and returns the raw bytes,
  // which the calling screen can then share, save, or print
  Future<List<int>> generateReport() async {
    final pdf = pw.Document();

    // grab a one-time snapshot of assets (not a live stream, since a pdf is a fixed snapshot in time)
    final assets = await _assetService.getAssets().first;

    // for each asset, grab its vulnerabilities too
    final Map<String, List<Vulnerability>> vulnsByAsset = {};
    for (final asset in assets) {
      final vulns =
          await _vulnService.getVulnerabilitiesForAsset(asset.id).first;
      vulnsByAsset[asset.id] = vulns;
    }

    // calculate overall severity counts across all open vulnerabilities, for the summary section
    final severityCounts = {'Critical': 0, 'High': 0, 'Medium': 0, 'Low': 0};
    int totalOpen = 0;
    for (final vulns in vulnsByAsset.values) {
      for (final v in vulns) {
        if (v.status == 'Resolved') continue;
        severityCounts[v.severity] = (severityCounts[v.severity] ?? 0) + 1;
        totalOpen++;
      }
    }

    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown user';
    final generatedDate = DateTime.now();
    final formattedDate =
        '${generatedDate.month}/${generatedDate.day}/${generatedDate.year} '
        '${generatedDate.hour}:${generatedDate.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        // this runs on every page, so the header repeats automatically on page breaks
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Vulnera Security Assessment Report',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Generated: $formattedDate', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Prepared by: $userEmail', style: const pw.TextStyle(fontSize: 10)),
                pw.Divider(thickness: 1),
              ],
            );
          }
          return pw.SizedBox();
        },
        footer: (context) {
          return pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          );
        },
        build: (context) => [
          // summary section
          pw.Text('Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Total Assets: ${assets.length}')),
              pw.Expanded(child: pw.Text('Total Open Vulnerabilities: $totalOpen')),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: ['Severity', 'Open Count']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ))
                    .toList(),
              ),
              ...severityCounts.entries.map((entry) {
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 10,
                            height: 10,
                            color: _severityColor(entry.key),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Text(entry.key),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(entry.value.toString()),
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 24),

          // per-asset breakdown
          pw.Text('Asset Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),

          ...assets.map((asset) {
            final vulns = vulnsByAsset[asset.id] ?? [];

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    asset.name,
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '${asset.type} · Risk Score: ${asset.riskScore.toStringAsFixed(1)} · ${asset.openIssueCount} open issue(s)',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 6),

                  if (vulns.isEmpty)
                    pw.Text(
                      'No vulnerabilities recorded for this asset.',
                      style: const pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                    )
                  else
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey400),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(3),
                        1: pw.FlexColumnWidth(1.5),
                        2: pw.FlexColumnWidth(1),
                        3: pw.FlexColumnWidth(1.5),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                          children: ['Title', 'Severity', 'CVSS', 'Status']
                              .map((h) => pw.Padding(
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  ))
                              .toList(),
                        ),
                        ...vulns.map((v) {
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(v.title, style: const pw.TextStyle(fontSize: 10)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(
                                  v.severity,
                                  style: pw.TextStyle(fontSize: 10, color: _severityColor(v.severity)),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(v.cvssScore.toStringAsFixed(1), style: const pw.TextStyle(fontSize: 10)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(v.status, style: const pw.TextStyle(fontSize: 10)),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    return pdf.save();
  }
}