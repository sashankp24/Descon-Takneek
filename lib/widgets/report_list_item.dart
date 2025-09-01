// lib/widgets/report_list_item.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/distress_report.dart';
import '../screens/video_player_screen.dart';
import '../services/file_service.dart';

class ReportListItem extends StatelessWidget {
  final DistressReport report;
  final FileService fileService;

  const ReportListItem(
      {super.key, required this.report, required this.fileService});

  void _showReportOptions(BuildContext context, String reportPath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Report Options"),
        content: const Text("What would you like to do with this report?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              fileService.openFile(reportPath);
            },
            child: const Text("View"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              fileService.shareFile(reportPath);
            },
            child: const Text("Share"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Row(
            children: [
              // Video Thumbnail
              Expanded(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VideoPlayerScreen(videoPath: report.videoPath),
                        ),
                      ),
                      child: report.thumbnailPath != null
                          ? Image.file(
                              File(report.thumbnailPath!),
                              height: 100,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.videocam, size: 64),
                    ),
                    if (report.position != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "GPS: ${report.position!.latitude.toStringAsFixed(4)}, ${report.position!.longitude.toStringAsFixed(4)}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              // Report Info
              Expanded(
                child: Center(
                  child: report.status == ReportStatus.processing
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(
                              "Building report...",
                              style: TextStyle(
                                  fontSize: 14, fontStyle: FontStyle.italic),
                            ),
                          ],
                        )
                      : report.reportPath != null
                          ? ListTile(
                              leading: const Icon(Icons.picture_as_pdf,
                                  color: Colors.red),
                              title: Text(
                                report.reportPath!.split("/").last,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _showReportOptions(
                                  context, report.reportPath!),
                            )
                          : const Text(
                              // Fallback for any errors
                              "Report failed",
                              style: TextStyle(fontSize: 14, color: Colors.red),
                            ),
                ),
              ),
            ],
          ),
        ),
        const Divider(thickness: 1),
      ],
    );
  }
}
