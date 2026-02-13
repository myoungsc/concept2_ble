import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:concept2_ble/services/screenshot_service.dart';

void main() {
  group('ScreenshotService.compressToMaxSize', () {
    late Uint8List smallPng;
    late Uint8List largePng;

    setUp(() {
      // 작은 이미지 (100x100) - 1MB 이하
      final smallImage = img.Image(width: 100, height: 100);
      img.fill(smallImage, color: img.ColorRgb8(255, 0, 0));
      smallPng = Uint8List.fromList(img.encodePng(smallImage));

      // 큰 이미지 (2000x2000, 다양한 색상) - PNG 크기가 클 수 있음
      final largeImage = img.Image(width: 2000, height: 2000);
      for (int y = 0; y < 2000; y++) {
        for (int x = 0; x < 2000; x++) {
          largeImage.setPixelRgb(x, y, x % 256, y % 256, (x + y) % 256);
        }
      }
      largePng = Uint8List.fromList(img.encodePng(largeImage));
    });

    test('작은 이미지는 JPEG로 변환되어 반환된다', () {
      final result = ScreenshotService.compressToMaxSize(
        smallPng,
        1024 * 1024,
      );

      expect(result, isNotNull);
      expect(result.lengthInBytes, lessThanOrEqualTo(1024 * 1024));
      // JPEG 매직 바이트 확인 (0xFF 0xD8)
      expect(result[0], equals(0xFF));
      expect(result[1], equals(0xD8));
    });

    test('큰 이미지는 1MB 이하로 압축된다', () {
      final result = ScreenshotService.compressToMaxSize(
        largePng,
        1024 * 1024,
      );

      expect(result.lengthInBytes, lessThanOrEqualTo(1024 * 1024));
      // JPEG 매직 바이트 확인
      expect(result[0], equals(0xFF));
      expect(result[1], equals(0xD8));
    });

    test('maxSizeBytes를 작게 설정하면 quality가 낮아져 더 작은 파일이 반환된다', () {
      final resultLarge = ScreenshotService.compressToMaxSize(
        smallPng,
        1024 * 1024, // 1MB
      );

      final resultSmall = ScreenshotService.compressToMaxSize(
        smallPng,
        1024, // 1KB
      );

      expect(resultSmall.lengthInBytes, lessThanOrEqualTo(resultLarge.lengthInBytes));
    });

    test('잘못된 PNG 데이터는 예외를 던진다', () {
      final invalidData = Uint8List.fromList([0, 1, 2, 3, 4]);

      expect(
        () => ScreenshotService.compressToMaxSize(invalidData, 1024 * 1024),
        throwsException,
      );
    });
  });

  group('PhotoPermissionStatus', () {
    test('granted와 denied 두 가지 상태가 존재한다', () {
      expect(PhotoPermissionStatus.values.length, equals(2));
      expect(PhotoPermissionStatus.values,
          contains(PhotoPermissionStatus.granted));
      expect(PhotoPermissionStatus.values,
          contains(PhotoPermissionStatus.denied));
    });
  });
}
