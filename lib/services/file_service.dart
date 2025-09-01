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
    pw.MemoryImage? worstFrameImage;
    if (report.worstFramePath != null) {
      final imageBytes = await File(report.worstFramePath!).readAsBytes();
      worstFrameImage = pw.MemoryImage(imageBytes);
      await File(report.worstFramePath!).delete();
    }
    pdf.addPage(
      pw.MultiPage( // Use MultiPage to prevent overflow
        build: (context) => [
          pw.Text("Road Distress Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),

          // Summary Section
          pw.Text("Summary", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text("Date: ${DateTime.now().toLocal().toString().split(' ')[0]}"),
          pw.Text("Video: ${report.videoPath.split('/').last}"),
          if (report.position != null) ...[
            pw.Text("Latitude: ${report.position!.latitude}"),
            pw.Text("Longitude: ${report.position!.longitude}"),
          ],
          pw.SizedBox(height: 10),
          pw.Text("Final Assessment: ${report.detectionResult ?? 'N/A'}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 20),
          
          // --- NEW: Quantification Section ---
          pw.Text("Quantification Details", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          if (report.quantification != null && report.quantification!.isNotEmpty)
            pw.Table.fromTextArray(
              headers: ['Distress Type', 'Pixel Count'],
              data: report.quantification!.entries
                .where((e) => e.key.toLowerCase() != 'background' && e.value > 0)
                .map((e) => [e.key, e.value.toString()])
                .toList(),
            )
          else
            pw.Text("No distress pixels were detected."),
          pw.SizedBox(height: 20),

          // --- NEW: Image Evidence Section ---
          if (worstFrameImage != null) ...[
            pw.Text("Visual Evidence", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Container(
              height: 300,
              child: pw.Image(worstFrameImage),
            ),
          ]
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf");
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