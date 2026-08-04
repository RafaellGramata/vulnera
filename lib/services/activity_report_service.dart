import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_event.dart';

class ActivityReportService {
  Future<List<int>> generateActivityReport({
    required List<AppEvent> events,
    required String rangeLabel,
  }) async {
    final pdf = pw.Document();

    final userEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'Unknown user';
    final generatedDate = DateTime.now();
    final formattedGenerated =
        '${generatedDate.month}/${generatedDate.day}/${generatedDate.year} '
        '${generatedDate.hour}:${generatedDate.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Vulnera Activity Report',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Range: $rangeLabel',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Generated: $formattedGenerated',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Prepared by: $userEmail',
                  style: const pw.TextStyle(fontSize: 10),
                ),
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
          pw.Text(
            '${events.length} event(s) in this range',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          if (events.isEmpty)
            pw.Text(
              'No activity recorded for this range.',
              style: const pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.3),
                1: pw.FlexColumnWidth(1.3),
                2: pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: ['Date', 'By', 'Event']
                      .map(
                        (h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            h,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                ...events.map((event) {
                  final dateStr =
                      '${event.timestamp.month}/${event.timestamp.day}/${event.timestamp.year} '
                      '${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}';
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          dateStr,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          event.actorEmail,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          event.message,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );

    return pdf.save();
  }
}
