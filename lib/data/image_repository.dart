import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/models/app_image.dart';

class ImageRepository {
  final FirebaseFirestore _firestore;

  ImageRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<AppImage>> fetchImages(String collectionName) async {
    final snapshot = await _firestore.collection(collectionName).get();
    final images = <AppImage>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = (data['name'] as String?) ?? 'Unknown';
      final rawUrl = (data['url'] as String?) ?? '';
      if (rawUrl.isEmpty) continue;
      final url = await _resolveUrl(rawUrl);
      images.add(AppImage(name: name, url: url));
    }
    return images;
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
