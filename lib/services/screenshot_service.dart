import 'dart:typed_data';

import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

class ScreenshotService {
  ScreenshotService._();

  static Future<void> captureAndSave(
    ScreenshotController controller,
  ) async {
    final Uint8List? imageBytes = await controller.capture(
      delay: const Duration(milliseconds: 100),
      pixelRatio: 2.0,
    );

    if (imageBytes == null) {
      throw Exception('스크린샷 캡쳐 실패');
    }

    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd_HH-mm');
    final fileName = 'Concept2_Race_${formatter.format(now)}';

    final result = await ImageGallerySaverPlus.saveImage(
      imageBytes,
      quality: 100,
      name: fileName,
    );

    if (result == null || (result is Map && result['isSuccess'] != true)) {
      throw Exception('사진첩 저장 실패');
    }
  }
}
