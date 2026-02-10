import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/models/app_image.dart';

double _diffFromBytes(Map<String, dynamic> args) {
  final queryBytes = args["query"] as Uint8List?;
  final targetBytes = args["target"] as Uint8List?;
  final size = args["size"] as int? ?? 300;

  if (queryBytes == null || targetBytes == null) return 100;

  final queryImage = img.decodeImage(queryBytes);
  final targetImage = img.decodeImage(targetBytes);
  if (queryImage == null || targetImage == null) return 100;

  final queryResized = img.copyResize(queryImage, width: size, height: size);
  final targetResized = img.copyResize(targetImage, width: size, height: size);

  final width = min(queryResized.width, targetResized.width);
  final height = min(queryResized.height, targetResized.height);
  double diff = 0;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixelA = queryResized.getPixel(x, y);
      final pixelB = targetResized.getPixel(x, y);
      diff += (pixelA.r - pixelB.r).abs();
      diff += (pixelA.g - pixelB.g).abs();
      diff += (pixelA.b - pixelB.b).abs();
    }
  }

  final maxDiff = width * height * 3 * 255;
  return (diff / maxDiff) * 100;
}

class SimilarityService {
  final LinkedHashMap<String, Uint8List> _imageCache = LinkedHashMap();
  final int _cacheLimit;
  final int _concurrency;

  SimilarityService({int cacheLimit = 30, int concurrency = 3})
      : _cacheLimit = cacheLimit,
        _concurrency = concurrency;

  void clearCache() {
    _imageCache.clear();
  }

  Future<List<double>> computeSimilarities({
    required Uint8List queryBytes,
    required List<AppImage> images,
    required void Function(int completed, int total) onProgress,
  }) async {
    if (images.isEmpty) return <double>[];

    final diffs = List<double>.filled(images.length, 100);
    final queue = List<int>.generate(images.length, (i) => i);
    final concurrency = min(_concurrency, images.length);
    var completed = 0;

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final i = queue.removeLast();
        final url = images[i].url;
        if (url.isEmpty) {
          diffs[i] = 100;
        } else {
          try {
            final bytes = await _getImageBytes(url);
            if (bytes == null) {
              diffs[i] = 100;
            } else {
              final diff = await compute(_diffFromBytes, {
                "query": queryBytes,
                "target": bytes,
                "size": 300,
              });
              diffs[i] = diff;
            }
          } catch (_) {
            diffs[i] = 100;
          }
        }

        completed++;
        onProgress(completed, images.length);
      }
    }

    await Future.wait(List.generate(concurrency, (_) => worker()));
    return diffs;
  }

  Future<Uint8List?> _getImageBytes(String url) async {
    final resolvedUrl = await _resolveUrl(url);
    final cached = _imageCache[resolvedUrl];
    if (cached != null) {
      _imageCache.remove(resolvedUrl);
      _imageCache[resolvedUrl] = cached;
      return cached;
    }

    final uri = Uri.tryParse(resolvedUrl) ??
        Uri.parse(Uri.encodeFull(resolvedUrl));
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final bytes = response.bodyBytes;
    _imageCache[resolvedUrl] = bytes;
    if (_imageCache.length > _cacheLimit) {
      _imageCache.remove(_imageCache.keys.first);
    }
    return bytes;
  }

  Future<String> _resolveUrl(String rawUrl) async {
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    if (rawUrl.startsWith('gs://')) {
      return FirebaseStorage.instance.refFromURL(rawUrl).getDownloadURL();
    }
    return FirebaseStorage.instance.ref().child(rawUrl).getDownloadURL();
  }
}
