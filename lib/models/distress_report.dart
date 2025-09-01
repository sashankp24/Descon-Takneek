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

  Map<String, int>? quantification;

  String? worstFramePath;

  DistressReport({
    required this.videoPath,
    this.thumbnailPath,
    this.reportPath,
    this.position,
    this.detectionResult,
    this.status = ReportStatus.complete,
    this.quantification,
    this.worstFramePath,
  });
}