import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImagePickerService{
  final _imagePicker = ImagePicker();

  Future<Uint8List?> pickImageBytes() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 400,
      maxHeight: 400,
    );

    if (pickedFile == null) return null;

    final path = pickedFile.path;

    return File(path).readAsBytesSync();
  }
}