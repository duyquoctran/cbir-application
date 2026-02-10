import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class PickedImage {
  final Uint8List bytes;
  final File? file;

  const PickedImage({required this.bytes, required this.file});
}

class ImagePickerService {
  final ImagePicker _picker;

  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<PickedImage?> pick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final file = kIsWeb ? null : File(picked.path);
    return PickedImage(bytes: bytes, file: file);
  }
}
