import 'dart:typed_data';

class ClassificationResult {
  final String label;
  final double confidence;

  ClassificationResult({required this.label, required this.confidence});
}

class ImageClassifier {
  bool get isSupported => false;

  Future<void> load() async {}

  Future<ClassificationResult?> classify(Uint8List bytes) async {
    return null;
  }

  void close() {}
}
