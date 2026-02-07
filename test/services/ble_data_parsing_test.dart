import 'package:flutter_test/flutter_test.dart';
import 'package:concept2_ble/services/concept2_ble_service.dart';

void main() {
  group('PM5 BLE 데이터 파싱', () {
    test('General Status 데이터를 올바르게 파싱한다', () {
      // Simulated PM5 General Status characteristic data (19 bytes)
      // elapsed time: 12345 (0.01s) = 123.45s = 2m 3.45s
      // distance: 5000 (0.1m) = 500.0m
      // stroke rate: 28
      final bytes = List<int>.filled(19, 0);
      // elapsed time (little-endian, 3 bytes): 12345 = 0x3039
      bytes[0] = 0x39; // low
      bytes[1] = 0x30; // mid
      bytes[2] = 0x00; // high
      // distance (little-endian, 3 bytes): 5000 = 0x1388
      bytes[3] = 0x88; // low
      bytes[4] = 0x13; // mid
      bytes[5] = 0x00; // high
      // stroke rate
      bytes[10] = 28;

      final data = Concept2BleService.parseGeneralStatus(bytes);

      // 12345 * 10ms = 123450ms = 123.45s
      expect(data.elapsedTime.inMilliseconds, 123450);
      // 5000 / 10 = 500.0m
      expect(data.distanceMeters, 500.0);
      expect(data.strokeRate, 28);
    });

    test('데이터가 19바이트 미만이면 기본값을 반환한다', () {
      final data = Concept2BleService.parseGeneralStatus([0, 1, 2]);

      expect(data.distanceMeters, 0);
      expect(data.strokeRate, 0);
    });

    test('빈 데이터는 기본값을 반환한다', () {
      final data = Concept2BleService.parseGeneralStatus([]);

      expect(data.distanceMeters, 0);
      expect(data.elapsedTime, Duration.zero);
    });

    test('최대값 거리를 올바르게 파싱한다', () {
      // distance: 100000 (0.1m) = 10000.0m (max distance)
      // 100000 = 0x0186A0
      final bytes = List<int>.filled(19, 0);
      bytes[3] = 0xA0;
      bytes[4] = 0x86;
      bytes[5] = 0x01;

      final data = Concept2BleService.parseGeneralStatus(bytes);
      expect(data.distanceMeters, 10000.0);
    });

    test('경과 시간이 올바르게 변환된다', () {
      // 60000 centiseconds = 600 seconds = 10 minutes
      // 60000 = 0x00EA60
      final bytes = List<int>.filled(19, 0);
      bytes[0] = 0x60;
      bytes[1] = 0xEA;
      bytes[2] = 0x00;

      final data = Concept2BleService.parseGeneralStatus(bytes);
      expect(data.elapsedTime.inMinutes, 10);
      expect(data.elapsedTime.inSeconds, 600);
    });
  });
}
