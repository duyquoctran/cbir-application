import 'dart:typed_data';

import '../classifier.dart';
import '../domain/models/classification_result.dart';

class ClassifierRepository {
  final ImageClassifier _classifier;

  ClassifierRepository({ImageClassifier? classifier})
      : _classifier = classifier ?? ImageClassifier();

  bool get isSupported => _classifier.isSupported;

  Future<void> load() => _classifier.load();

  Future<ClassificationResult?> classify(Uint8List bytes) {
    return _classifier.classify(bytes);
  }

  void close() {
    if (_classifier.isSupported) {
      _classifier.close();
    }
  }
}
