import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

/// A service to handle all on-device ONNX model inference.
/// This class encapsulates the logic for loading the model, preprocessing images,
/// running inference, and post-processing the results to return a prediction.
class OnnxService {
  OrtSession? _ortSession;
  List<dynamic>? _classNames;

  /// Initializes the service by loading the ONNX model and class labels from assets.
  /// This should be called once, ideally when the application starts, to ensure
  /// the model is ready for inference without repeated loading.
  Future<void> initialize() async {
    final assetPath = 'assets/models/MobileNetV3-AutoAugment_bs32_lr1em03.onnx';
    final classNamesPath = 'assets/models/imagenet-simple-labels.json';
    _ortSession = await OnnxRuntime().createSessionFromAsset(assetPath);

    final String classNamesJson = await rootBundle.loadString(classNamesPath);
    _classNames = jsonDecode(classNamesJson);
    print("ONNX Service Initialized Successfully.");
  }

  /// Takes image bytes, processes them through the ONNX model, and returns a prediction string.
  Future<String> runInference(Uint8List imageBytes) async {
    if (_ortSession == null || _classNames == null) {
      throw Exception(
        "ONNX Service is not initialized. Call initialize() first.",
      );
    }

    // 1. Image Preprocessing
    // Decodes, resizes, and normalizes the image to the format required by the model.
    final img.Image? cachedImage = img.decodeImage(imageBytes);
    if (cachedImage == null) throw Exception("Failed to decode image.");

    final resizedImage = img.copyResize(cachedImage, width: 224, height: 224);
    final inputData = Float32List(1 * 3 * 224 * 224);
    final means = [0.485, 0.456, 0.406];
    final stds = [0.229, 0.224, 0.225];
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resizedImage.getPixel(x, y);
        inputData[y * 224 + x] = (pixel.r / 255.0 - means[0]) / stds[0];
        inputData[224 * 224 + y * 224 + x] =
            (pixel.g / 255.0 - means[1]) / stds[1];
        inputData[2 * 224 * 224 + y * 224 + x] =
            (pixel.b / 255.0 - means[2]) / stds[2];
      }
    }

    // 2. Run Model Inference
    // Feeds the processed image data into the ONNX session to get the model's output scores.
    final inputName = _ortSession!.inputNames.first;
    final outputName = _ortSession!.outputNames.first;
    final inputTensor = await OrtValue.fromList(inputData, [1, 3, 224, 224]);
    final outputs = await _ortSession!.run({inputName: inputTensor});
    final scores =
        (await outputs[outputName]!.asFlattenedList()).cast<double>();
    await inputTensor.dispose();

    // 3. Post-process Results
    // Applies a softmax function to the output scores to get probabilities and
    // finds the class with the highest probability.
    final probabilities = _applySoftmax(scores);
    final maxIndex = probabilities.indexOf(probabilities.reduce(math.max));

    final String topPrediction =
        (maxIndex < _classNames!.length)
            ? _classNames![maxIndex]
            : 'Unrecognized';

    return topPrediction;
  }

  /// Helper function to apply softmax to the model's output logits.
  /// This converts the raw scores into a probability distribution.
  List<double> _applySoftmax(List<double> logits) {
    double maxLogit = logits.reduce(math.max);
    List<double> expValues =
        logits.map((logit) => math.exp(logit - maxLogit)).toList();
    double sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((exp) => exp / sumExp).toList();
  }
}
