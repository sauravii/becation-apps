import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';

// Service media/device-IO: file picker + image cropper.
class MediaService {
  static const int maxPhotoBytes = 5 * 1024 * 1024; // 5 MB

  static Future<File?> pickProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final path = result.files.single.path;
    if (path == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust Profile Photo',
          toolbarColor: const Color(0xFF6F5AAA),
          toolbarWidgetColor: const Color(0xFFFFFFFF),
          activeControlsWidgetColor: const Color(0xFF6F5AAA),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: true,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'Adjust Profile Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
      ],
    );
    if (cropped == null) return null; // user cancel di cropper

    final file = File(cropped.path);
    if (await file.length() > maxPhotoBytes) {
      throw MediaException('Photo exceeds 5 MB');
    }
    return file;
  }

  static Future<void> deleteTemp(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (e, st) {
      debugPrint('[MediaService] deleteTemp failed: $e\n$st');
    }
  }
}

// Error media yang sudah dinormalisasi — page map [message] ke snackbar.
class MediaException implements Exception {
  final String message;

  MediaException(this.message);

  @override
  String toString() => 'MediaException: $message';
}
