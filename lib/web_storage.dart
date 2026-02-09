import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class FireStorageService extends ChangeNotifier {
  FireStorageService._();
  FireStorageService();

  static Future<String> loadFromStorage(
      BuildContext context, String image) async {
    return FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}
