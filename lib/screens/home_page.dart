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

class _IsolateParams {
  final List<String> framePaths;
  final Uint8List modelData;
  final String labelsData;

  _IsolateParams(this.framePaths, this.modelData, this.labelsData);
}

Future<Map<String, dynamic>> _analyzeVideoInIsolate(_IsolateParams params) async {
  final mlService = MLService();
  final isModelLoaded = await mlService.loadFromBuffer(
      modelBuffer: params.modelData, labelsData: params.labelsData);

  if (!isModelLoaded) {
    throw Exception('Failed to load ML model in the background isolate.');
  }

  Map<String, int> totalQuantification = {};
  int maxDistressPixels = 0;
  String? worstFramePath;

  for (final String framePath in params.framePaths) {
    final frameFile = File(framePath);
    final imageBytes = await frameFile.readAsBytes();
    final image = image_lib.decodeImage(imageBytes);

    if (image != null) {
      // AnalyzeImage now needs to return the full pixel count map.
      final analysisResult = mlService.analyzeImage(image);
      final pixelCounts = analysisResult['quantification'] as Map<String, int>;
      
      int currentFrameDistressPixels = 0;
      pixelCounts.forEach((key, value) {
        totalQuantification[key] = (totalQuantification[key] ?? 0) + value;
        if (key.toLowerCase() != 'background') {
          currentFrameDistressPixels += value;
        }
      });

      if (currentFrameDistressPixels > maxDistressPixels) {
        maxDistressPixels = currentFrameDistressPixels;
        worstFramePath = framePath;
      } else {
        // Delete non-worst frames immediately to save space.
        await frameFile.delete();
      }
    }
  }

  // Determine the final result.
  String finalDetection = "No distress detected";
  int maxCount = 0;
  totalQuantification.forEach((key, value) {
    if (key.toLowerCase() != 'background' && value > maxCount) {
      maxCount = value;
      finalDetection = key;
    }
  });

  return {
    'final_detection': finalDetection,
    'quantification': totalQuantification,
    'worst_frame_path': worstFramePath,
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

      final detectionResult = analysisResult['final_detection'] as String;
      final quantification = analysisResult['quantification'] as Map<String, int>;
      final worstFramePath = analysisResult['worst_frame_path'] as String?;

      final finalReport = DistressReport(
        videoPath: videoFile.path,
        thumbnailPath: thumbnailPath,
        position: position,
        detectionResult: detectionResult,
        quantification: quantification,
        worstFramePath: worstFramePath, // Pass the new data
        status: ReportStatus.complete,
      );

      final reportPath = await _fileService.generateReport(finalReport);
      
      final reportIndex = _reports.indexWhere((r) => r.videoPath == videoFile.path);
      if (reportIndex != -1 && mounted) {
        setState(() {
          _reports[reportIndex]
            ..reportPath = reportPath
            ..detectionResult = detectionResult
            ..quantification = quantification
            ..worstFramePath = worstFramePath
            ..status = ReportStatus.complete;
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
        _IsolateParams(framePaths, _modelData!, _labelsData!));
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
