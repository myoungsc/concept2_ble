import 'package:flutter_test/flutter_test.dart';
import 'package:concept2_ble/models/rowing_data.dart';

void main() {
  group('RowingData', () {
    test('기본값이 올바르게 초기화된다', () {
      final data = RowingData(timestamp: DateTime(2026, 2, 7));

      expect(data.distanceMeters, 0);
      expect(data.elapsedTime, Duration.zero);
      expect(data.strokeRate, 0);
      expect(data.watts, 0);
      expect(data.heartRate, 0);
      expect(data.pace500m, 0);
    });

    test('copyWith가 올바르게 작동한다', () {
      final data = RowingData(
        distanceMeters: 100,
        elapsedTime: const Duration(seconds: 30),
        strokeRate: 28,
        timestamp: DateTime(2026, 2, 7),
      );

      final updated = data.copyWith(distanceMeters: 200, watts: 150);

      expect(updated.distanceMeters, 200);
      expect(updated.watts, 150);
      expect(updated.strokeRate, 28); // 변경되지 않은 값 유지
      expect(updated.elapsedTime, const Duration(seconds: 30));
    });

    test('formattedElapsedTime이 올바른 형식을 반환한다', () {
      final data = RowingData(
        elapsedTime: const Duration(minutes: 3, seconds: 45, milliseconds: 700),
        timestamp: DateTime(2026, 2, 7),
      );

      expect(data.formattedElapsedTime, '3:45.7');
    });

    test('formattedElapsedTime 0초일 때 올바르다', () {
      final data = RowingData(timestamp: DateTime(2026, 2, 7));
      expect(data.formattedElapsedTime, '0:00.0');
    });

    test('formattedPace가 올바른 형식을 반환한다', () {
      final data = RowingData(
        pace500m: 120, // 2분 00초
        timestamp: DateTime(2026, 2, 7),
      );

      expect(data.formattedPace, '2:00');
    });

    test('pace가 0일 때 대시를 반환한다', () {
      final data = RowingData(timestamp: DateTime(2026, 2, 7));
      expect(data.formattedPace, '-:--');
    });
  });
}
