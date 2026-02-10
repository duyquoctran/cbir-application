import 'dart:typed_data';
import 'dart:convert';
import 'dart:js_util' as js_util;

import 'domain/models/classification_result.dart';

class ImageClassifier {
  bool get isSupported => true;

  Future<void> load() async {}

  Future<ClassificationResult?> classify(Uint8List bytes) async {
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    final result = await js_util.promiseToFuture<Object?>(
      js_util.callMethod(
        js_util.globalThis,
        'tfliteClassify',
        [dataUrl],
      ),
    );

    if (result == null) return null;
    final map = js_util.dartify(result);
    if (map is! Map) return null;

    final label = map['label'] as String?;
    final confidence = map['confidence'];
    if (label == null || confidence is! num) return null;

    return ClassificationResult(label: label, confidence: confidence.toDouble());
  }

  void close() {}
}
