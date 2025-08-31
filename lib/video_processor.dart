import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class VideoProcessor {
  Interpreter? _interpreter;
  static const int IMG_WIDTH = 256;
  static const int IMG_HEIGHT = 256;
  static const int NUM_CLASSES = 5;
  static const List<String> CLASS_NAMES = [
    "Background", "Pothole", "Crack", "Rutting", "Ravelling"
  ];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/road_distress_model.tflite');
      print('✅ TFLite model loaded successfully');
    } catch (e) {
      print('❌ Error loading TFLite model: $e');
    }
  }

  List<List<List<List<double>>>> preprocessImage(img.Image image) {
    img.Image resizedImage = img.copyResize(image, width: IMG_WIDTH, height: IMG_HEIGHT);

    var input = List.generate(
      1,
      (_) => List.generate(
        IMG_HEIGHT,
        (y) => List.generate(IMG_WIDTH, (x) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < IMG_HEIGHT; y++) {
      for (int x = 0; x < IMG_WIDTH; x++) {
        var pixel = resizedImage.getPixel(x, y);
    input[0][y][x][0] = pixel.r / 255.0;
    input[0][y][x][1] = pixel.g / 255.0;
    input[0][y][x][2] = pixel.b / 255.0;
      }
    }
    return input;
  }

  List<List<List<double>>> runInference(List<List<List<List<double>>>> input) {
    if (_interpreter == null) throw Exception("Interpreter not initialized");
    var output = List.generate(
      1,
      (_) => List.generate(
        IMG_HEIGHT,
        (y) => List.generate(IMG_WIDTH, (x) => List.filled(NUM_CLASSES, 0.0)),
      ),
    );
    _interpreter!.run(input, output);
    return output[0];
  }

  Map<String, int> getPixelCounts(List<List<List<double>>> outputMask) {
    Map<String, int> counts = {for (var name in CLASS_NAMES) name: 0};
    for (int y = 0; y < IMG_HEIGHT; y++) {
      for (int x = 0; x < IMG_WIDTH; x++) {
        var pixelProbabilities = outputMask[y][x];
        int maxIndex = 0;
        double maxValue = 0.0;
        for (int i = 0; i < NUM_CLASSES; i++) {
          if (pixelProbabilities[i] > maxValue) {
            maxValue = pixelProbabilities[i];
            maxIndex = i;
          }
        }
        counts[CLASS_NAMES[maxIndex]] = (counts[CLASS_NAMES[maxIndex]] ?? 0) + 1;
      }
    }
    return counts;
  }
}
