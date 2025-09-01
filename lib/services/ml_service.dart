import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class MLService {
  Interpreter? _interpreter;
  List<String> _labels = [];

  static const int _inputSize = 256;

  String? getLabelForIndex(int index) {
    if (index >= 0 && index < _labels.length) {
      return _labels[index];
    }
    return null;
  }

  Future<bool> loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/road_distress_float.tflite');
      _interpreter!.allocateTensors();

      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels =
          labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      if (_interpreter != null && _labels.isNotEmpty) {
        print("Model and labels loaded successfully.");
        return true;
      }
      return false;
    } catch (e) {
      print("Failed to load model or labels: $e");
      return false;
    }
  }

  bool loadFromBuffer(
      {required Uint8List modelBuffer, required String labelsData}) {
    try {
      _interpreter = Interpreter.fromBuffer(modelBuffer);
      _interpreter!.allocateTensors();
      _labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return _interpreter != null && _labels.isNotEmpty;
    } catch (e) {
      print("Failed to load model from buffer: $e");
      return false;
    }
  }

  Float32List _preprocess(img.Image image) {
    final resizedImage =
        img.copyResize(image, width: _inputSize, height: _inputSize);

    final imageBytes = Float32List(_inputSize * _inputSize * 3);

    int pixelIndex = 0;
    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);

        imageBytes[pixelIndex++] = pixel.r / 255.0;
        imageBytes[pixelIndex++] = pixel.g / 255.0;
        imageBytes[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return imageBytes;
  }

  Map<String, dynamic>? analyzeImage(img.Image image) {
    if (_interpreter == null || _labels.isEmpty) return null;

    final inputTensor =
        _preprocess(image).reshape([1, _inputSize, _inputSize, 3]);
    final outputShape = [1, _inputSize, _inputSize, _labels.length];
    final outputBuffer =
        List.generate(outputShape.reduce((a, b) => a * b), (_) => 0.0)
            .reshape(outputShape);

    _interpreter!.run(inputTensor, outputBuffer);

    final Map<String, int> classCounts = {for (var label in _labels) label: 0};
    final outputList = outputBuffer[0];

    // --- NEW: Create a simple integer mask for the overlay function ---
    final predictionMask =
        List.generate(_inputSize, (_) => List.generate(_inputSize, (_) => [0]));

    const double confidenceThreshold = 0.5;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        int dominantClassIndex = 0;
        double maxScore = -1.0;
        for (int c = 0; c < _labels.length; c++) {
          final score = outputList[y][x][c];
          if (score > maxScore) {
            maxScore = score;
            dominantClassIndex = c;
          }
        }

        if (maxScore < confidenceThreshold) {
          dominantClassIndex = 0;
        }

        final label = _labels[dominantClassIndex];
        classCounts[label] = (classCounts[label] ?? 0) + 1;
        predictionMask[y][x][0] = dominantClassIndex;
      }
    }

    return {'quantification': classCounts, 'mask': predictionMask};
  }
}
