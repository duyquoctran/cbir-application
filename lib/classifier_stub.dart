import 'dart:typed_data';

import 'domain/models/classification_result.dart';

class ImageClassifier {
  bool get isSupported => false;

  Future<void> load() async {}

  Future<ClassificationResult?> classify(Uint8List bytes) async {
    return null;
  }

  void close() {}
}
