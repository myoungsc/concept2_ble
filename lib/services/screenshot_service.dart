import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';

enum PhotoPermissionStatus { granted, denied }

class ScreenshotService {
  ScreenshotService._();

  static const int _maxSizeBytes = 1024 * 1024; // 1MB

  static Future<PhotoPermissionStatus> checkAndRequestPermission() async {
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (hasAccess) return PhotoPermissionStatus.granted;

    final granted = await Gal.requestAccess(toAlbum: true);
    return granted
        ? PhotoPermissionStatus.granted
        : PhotoPermissionStatus.denied;
  }

  static Future<void> captureAndSave(
    ScreenshotController controller,
  ) async {
    final Uint8List? imageBytes = await controller.capture(
      delay: const Duration(milliseconds: 100),
      pixelRatio: 2.0,
    );

    if (imageBytes == null) {
      throw Exception('capture_failed'.tr());
    }

    final compressedBytes = compressToMaxSize(imageBytes, _maxSizeBytes);

    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd_HH-mm');
    final fileName = 'Concept2_Race_${formatter.format(now)}.jpg';

    await Gal.putImageBytes(compressedBytes, name: fileName);
  }

  static Uint8List compressToMaxSize(Uint8List pngBytes, int maxSizeBytes) {
    final image = img.decodePng(pngBytes);
    if (image == null) {
      throw Exception('decode_failed'.tr());
    }

    int quality = 90;
    Uint8List jpegBytes =
        Uint8List.fromList(img.encodeJpg(image, quality: quality));

    while (jpegBytes.lengthInBytes > maxSizeBytes && quality > 10) {
      quality -= 10;
      jpegBytes = Uint8List.fromList(img.encodeJpg(image, quality: quality));
    }

    return jpegBytes;
  }
}
