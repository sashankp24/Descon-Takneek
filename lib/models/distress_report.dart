// lib/models/distress_report.dart
import 'dart:io';
import 'package:geolocator/geolocator.dart';

enum ReportStatus { processing, complete }

class DistressReport {
  final String videoPath;
  final String? thumbnailPath;
  String? reportPath;
  final Position? position;
  String? detectionResult;
  ReportStatus status;
  String? finalAssessment;

  Map<String, int>? quantification;

  Map<String, double>? averagePercentages;
  Map<String, String>? keyFramePaths;

  String? worstFramePath;

  DistressReport({
    required this.videoPath,
    this.thumbnailPath,
    this.reportPath,
    this.position,
    this.status = ReportStatus.complete,
    this.finalAssessment,
    this.averagePercentages,
    this.keyFramePaths,
  });
}
