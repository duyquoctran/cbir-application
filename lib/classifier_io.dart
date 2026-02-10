import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'classifier_stub.dart';

class ImageClassifier {
  late final Interpreter _interpreter;
  late final List<String> _labels;

  bool get isSupported => true;

  Future<void> load() async {
    _interpreter = await Interpreter.fromAsset('b1_aug.tflite');
    final labelsData = await rootBundle.loadString('assets/labels.txt');
    _labels = labelsData
        .split('\n')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();
  }

  Future<ClassificationResult?> classify(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final inputTensor = _interpreter.getInputTensor(0);
    final inputShape = inputTensor.shape;
    final inputHeight = inputShape[1];
    final inputWidth = inputShape[2];

    final resized =
        img.copyResize(decoded, width: inputWidth, height: inputHeight);

    final inputSize = inputHeight * inputWidth * 3;
    final input = Float32List(inputSize);
    var index = 0;

    for (var y = 0; y < inputHeight; y++) {
      for (var x = 0; x < inputWidth; x++) {
        final pixel = resized.getPixel(x, y);
        input[index++] = (pixel.r - 127.5) / 127.5;
        input[index++] = (pixel.g - 127.5) / 127.5;
        input[index++] = (pixel.b - 127.5) / 127.5;
      }
    }

    final outputTensor = _interpreter.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    final outputSize = outputShape.reduce((a, b) => a * b);
    final output = List.filled(outputSize, 0.0).reshape(outputShape);

    _interpreter.run(input.reshape([1, inputHeight, inputWidth, 3]), output);

    final scores = (output[0] as List).cast<double>();
    var topIndex = 0;
    var topScore = scores.isNotEmpty ? scores[0] : 0.0;

    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > topScore) {
        topScore = scores[i];
        topIndex = i;
      }
    }

    final label = (topIndex < _labels.length) ? _labels[topIndex] : 'unknown';

    return ClassificationResult(label: label, confidence: topScore);
  }

  void close() {
    _interpreter.close();
  }
}
