// lib/services/file_service.dart
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/distress_report.dart';

class FileService {
  Future<String> generateReport(DistressReport report) async {
    final pdf = pw.Document();

    final List<pw.Widget> keyFrameWidgets = [];
    if (report.keyFramePaths != null) {
      for (var entry in report.keyFramePaths!.entries) {
        final label = entry.key;
        final path = entry.value;
        final imageBytes = await File(path).readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        keyFrameWidgets.add(pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Container(height: 250, child: pw.Image(image)),
              pw.SizedBox(height: 15),
            ]));
        await File(path).delete(); // Clean up the key frame
      }
    }

    pdf.addPage(
      pw.MultiPage(
        header: (context) => pw.Text("Road Distress Report",
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        build: (context) => [
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),

          // Summary Section
          pw.Text("Summary",
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text("Date: ${DateTime.now().toLocal().toString().split(' ')[0]}"),
          if (report.position != null)
            pw.Text(
                "GPS: ${report.position!.latitude.toStringAsFixed(4)}, ${report.position!.longitude.toStringAsFixed(4)}"),
          pw.SizedBox(height: 10),
          pw.Text("Final Assessment: ${report.finalAssessment ?? 'N/A'}",
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 20),

          // Quantification Section
          pw.Text("Overall Distress Presence",
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          if (report.averagePercentages != null &&
              report.averagePercentages!.entries.any((e) => e.value > 0))
            pw.Table.fromTextArray(
              headers: ['Distress Type', 'Average Presence in Video'],
              data: report.averagePercentages!.entries
                  .where(
                      (e) => e.value > 0.01) // Only show significant findings
                  .map((e) => [e.key, "${e.value.toStringAsFixed(2)}%"])
                  .toList(),
            )
          else
            pw.Text("No significant distress was detected."),
          pw.SizedBox(height: 20),

          // Key Frame Evidence Section
          if (keyFrameWidgets.isNotEmpty) ...[
            pw.NewPage(),
            pw.Text("Visual Evidence (Key Frames)",
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...keyFrameWidgets,
          ]
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file =
        File("${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<void> openFile(String path) async {
    await OpenFilex.open(path);
  }

  Future<void> shareFile(String path) async {
    await Share.shareXFiles([XFile(path)], text: "Road Distress Report");
  }

  Future<void> openAssetFile(String assetPath, String filename) async {
    final bytes = await rootBundle.load(assetPath);
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$filename");
    await file.writeAsBytes(bytes.buffer.asUint8List());
    await OpenFilex.open(file.path);
  }
}
