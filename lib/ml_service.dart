import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart'; // for debugPrint

class MLService {
  Interpreter? _interpreter;
  List<String> labels = [];

  /// Load model and labels
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('road_distress.tflite');
      debugPrint("✅ Model loaded successfully");
      await _loadLabels();
    } catch (e) {
      debugPrint("❌ Failed to load model: $e");
    }
  }

  Future<void> _loadLabels() async {
    final raw = await rootBundle.loadString('assets/labels.txt');
    labels = raw.split('\n').map((e) => e.trim()).toList();
    debugPrint("✅ Labels loaded: $labels");
  }

  /// Run inference on input data
  String runModel(List<double> input) {
    if (_interpreter == null) {
      throw Exception("Interpreter not initialized");
    }

    // Adjust shape to match your model
    var inputTensor = [input];
    var output = List.filled(labels.length, 0).reshape([1, labels.length]);

    _interpreter!.run(inputTensor, output);

    // Get class with highest probability
    int maxIndex = 0;
    double maxProb = output[0][0].toDouble();
    for (int i = 1; i < labels.length; i++) {
      if (output[0][i] > maxProb) {
        maxProb = output[0][i].toDouble();
        maxIndex = i;
      }
    }

    return labels[maxIndex];
  }
}
