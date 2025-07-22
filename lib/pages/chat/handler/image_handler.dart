import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ImageHandler {
  final ImagePicker _picker = ImagePicker();

  Future<Uint8List?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

}