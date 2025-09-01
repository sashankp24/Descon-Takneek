// lib/screens/home_page.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_frame_extractor/video_frame_extractor.dart';

import '../models/distress_report.dart';
import '../services/file_service.dart';
import '../services/location_service.dart';
import '../services/ml_service.dart';
import '../services/video_service.dart';
import '../widgets/action_buttons.dart';
import '../widgets/report_list_item.dart';
import '../utils/app_constants.dart';

Future<String> _createOverlayImage({
  required String framePath,
  required List<List<List<int>>> predictionMask, // The 256x256 mask
  required String tempDirPath,
  required String defectName,
  required MLService mlService,
}) async {
  final frameBytes = await File(framePath).readAsBytes();
  final resizedFrame = image_lib.decodeImage(frameBytes)!; // Use the original frame directly

  final colors = {
    "Pothole": image_lib.ColorRgba8(255, 0, 0, 128), // Red with 50% transparency
    "Crack": image_lib.ColorRgba8(0, 255, 0, 128),   // Green with 50% transparency
    "Rutting": image_lib.ColorRgba8(0, 0, 255, 128), // Blue with 50% transparency
    "Ravelling": image_lib.ColorRgba8(255, 255, 0, 128), // Yellow with 50% transparency
  };

  // Draw the colored pixels directly onto the frame
  for (int y = 0; y < 256; y++) {
    for (int x = 0; x < 256; x++) {
      final classIndex = predictionMask[y][x][0];
      final className = mlService.getLabelForIndex(classIndex);
      // Only draw if it's a defect (not Background)
      if (className != null && className != "Background") {
        image_lib.drawPixel(resizedFrame, x, y, colors[className]!);
      }
    }
  }

  final overlayPath = '$tempDirPath/keyframe_${defectName}.png';
  await File(overlayPath).writeAsBytes(image_lib.encodePng(resizedFrame));
  return overlayPath;
}

class _IsolateParams {
  final List<String> framePaths;
  final String tempDirPath;
  final Uint8List modelData;
  final String labelsData;

  _IsolateParams(
      this.framePaths, this.modelData, this.labelsData, this.tempDirPath);
}

Future<Map<String, dynamic>> _analyzeVideoInIsolate(
    _IsolateParams params) async {
  final mlService = MLService();
  final isModelLoaded = mlService.loadFromBuffer(
      modelBuffer: params.modelData, labelsData: params.labelsData);
  if (!isModelLoaded) throw Exception('Failed to load model in isolate.');

  // --- Analysis Variables ---
  final Map<String, double> totalPixelPercentages = {};
  final Map<String, Map<String, dynamic>> keyFrames =
      {}; // { "Pothole": {"percentage": 0.5, "path": "..."} }

  int framesProcessed = 0;

  for (final String framePath in params.framePaths) {
    framesProcessed++;
    final frameFile = File(framePath);
    final imageBytes = await frameFile.readAsBytes();
    final image = image_lib.decodeImage(imageBytes);

    if (image != null) {
      final analysisResult = mlService.analyzeImage(image);
      if (analysisResult == null) continue;

      final pixelCounts = analysisResult['quantification'] as Map<String, int>;
      final predictionMask =
          analysisResult['mask'] as List<List<List<int>>>; // Get the raw mask

      pixelCounts.forEach((label, count) {
        if (label.toLowerCase() != 'background') {
          double percentage = (count / (256 * 256)) * 100;
          totalPixelPercentages[label] =
              (totalPixelPercentages[label] ?? 0) + percentage;

          // Check if this is the best frame for this defect
          if (percentage > (keyFrames[label]?['percentage'] ?? 0)) {
            keyFrames[label] = {
              'percentage': percentage,
              'path': framePath,
              'mask': predictionMask
            };
          }
        }
      });
    }
  }

  // --- Finalize Results ---
  final Map<String, double> averagePercentages = {};
  totalPixelPercentages.forEach((label, totalPercentage) {
    averagePercentages[label] = totalPercentage / framesProcessed;
  });

  String finalAssessment = "No significant distress detected";
  double maxAvgPercentage = 0.01; // Threshold to be considered significant
  averagePercentages.forEach((label, avg) {
    if (avg > maxAvgPercentage) {
      maxAvgPercentage = avg;
      finalAssessment = label;
    }
  });

  // Create overlay images for the identified key frames
  final Map<String, String> keyFramePaths = {};
  for (var entry in keyFrames.entries) {
    final label = entry.key;
    final data = entry.value;
    final overlayPath = await _createOverlayImage(
      framePath: data['path'],
      predictionMask: data['mask'],
      tempDirPath: params.tempDirPath,
      defectName: label,
      mlService: mlService,
    );
    keyFramePaths[label] = overlayPath;
  }

  // Clean up original frames that are not key frames
  final usedPaths = keyFrames.values.map((d) => d['path'] as String).toSet();
  for (final framePath in params.framePaths) {
    if (!usedPaths.contains(framePath)) {
      await File(framePath).delete();
    }
  }

  return {
    'final_assessment': finalAssessment,
    'average_percentages': averagePercentages,
    'key_frame_paths': keyFramePaths,
  };
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FileService _fileService = FileService();
  final LocationService _locationService = LocationService();
  final VideoService _videoService = VideoService();

  final List<DistressReport> _reports = [];
  bool _isModelReady = false;
  bool _isProcessing = false;

  Uint8List? _modelData;
  String? _labelsData;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final modelBytes =
          await rootBundle.load('assets/road_distress_float.tflite');
      _modelData = modelBytes.buffer.asUint8List();
      _labelsData = await rootBundle.loadString('assets/labels.txt');

      if (mounted && _modelData != null && _labelsData != null) {
        setState(() {
          _isModelReady = true;
        });
      }
    } catch (e) {
      _showErrorSnackbar("Critical error: Could not load ML model assets.");
    }
  }

  Future<void> _pickAndProcessVideo(ImageSource source) async {
    setState(() => _isProcessing = true);

    final videoFile = await _videoService.pickVideo(source);
    if (videoFile == null) {
      setState(() => _isProcessing = false);
      return;
    }

    final thumbnailPath = await _videoService.generateThumbnail(videoFile.path);
    final position = await _locationService.getCurrentLocation();

    final initialReport = DistressReport(
      videoPath: videoFile.path,
      thumbnailPath: thumbnailPath,
      position: position,
      status: ReportStatus.processing,
    );

    setState(() {
      _reports.add(initialReport);
      _isProcessing = false;
    });

    try {
      final analysisResult = await _analyzeVideo(videoFile.path);

      final finalAssessment = analysisResult['final_assessment'] as String;
      final averagePercentages =
          analysisResult['average_percentages'] as Map<String, double>;
      final keyFramePaths =
          analysisResult['key_frame_paths'] as Map<String, String>;

      // 3. Create the final report object with the new detailed data.
      final finalReport = DistressReport(
        videoPath: videoFile.path,
        thumbnailPath: thumbnailPath,
        position: position,
        finalAssessment: finalAssessment,
        averagePercentages: averagePercentages,
        keyFramePaths: keyFramePaths,
        status: ReportStatus.complete,
      );

      // 4. Generate the PDF report using the rich data.
      final reportPath = await _fileService.generateReport(finalReport);

      // 5. Find the initial report in our list and update it with the final data.
      final reportIndex =
          _reports.indexWhere((r) => r.videoPath == videoFile.path);
      if (reportIndex != -1 && mounted) {
        setState(() {
          final reportToUpdate = _reports[reportIndex];
          reportToUpdate.reportPath = reportPath;
          reportToUpdate.finalAssessment = finalAssessment;
          reportToUpdate.averagePercentages = averagePercentages;
          reportToUpdate.keyFramePaths = keyFramePaths;
          reportToUpdate.status = ReportStatus.complete;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to process video: ${e.toString()}');
      print(e);
      if (mounted) {
        setState(() {
          _reports.removeWhere((r) => r.videoPath == videoFile.path);
        });
      }
    }
  }

  Future<Map<String, dynamic>> _analyzeVideo(String videoPath) async {
    final Directory tempDir = await getTemporaryDirectory();
    final List<String> framePaths = await VideoFrameExtractor.fromFile(
      video: File(videoPath),
      destinationDirectoryPath: tempDir.path,
      imagesCount: 15,
    );
    return await compute(_analyzeVideoInIsolate,
        _IsolateParams(framePaths, _modelData!, _labelsData!, tempDir.path));
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.appTitle,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu_book, color: Colors.black),
            onSelected: (value) {
              if (value == "guide") {
                _fileService.openAssetFile("assets/guide.pdf", "guide.pdf");
              } else if (value == "docs") {
                _fileService.openAssetFile(
                    "assets/documentation.pdf", "documentation.pdf");
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "guide", child: Text("Open Guide")),
              const PopupMenuItem(
                  value: "docs", child: Text("Open Documentation")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Row
          Container(
            color: Colors.black12,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: const Row(
              children: [
                Expanded(
                    child: Center(
                        child: Text("Saved Videos",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)))),
                Expanded(
                    child: Center(
                        child: Text("Saved Reports",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)))),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: _reports.isEmpty
                ? const Center(
                    child: Text('No videos processed yet.',
                        style: TextStyle(fontSize: 16, color: Colors.grey)))
                : ListView.builder(
                    itemCount: _reports.length,
                    itemBuilder: (ctx, i) => ReportListItem(
                      report: _reports[i],
                      fileService: _fileService,
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: ActionButtons(
        isEnabled: _isModelReady && !_isProcessing,
        onPickFromCamera: () => _pickAndProcessVideo(ImageSource.camera),
        onPickFromGallery: () => _pickAndProcessVideo(ImageSource.gallery),
      ),
    );
  }
}
