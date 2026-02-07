import 'package:flutter_test/flutter_test.dart';
import 'package:concept2_ble/models/ble_device_state.dart';

void main() {
  group('BleConnectionState', () {
    test('모든 상태에 한글 라벨이 있다', () {
      for (final state in BleConnectionState.values) {
        expect(state.label, isNotEmpty);
      }
    });

    test('라벨이 올바르다', () {
      expect(BleConnectionState.disconnected.label, '연결 안됨');
      expect(BleConnectionState.scanning.label, '스캔 중…');
      expect(BleConnectionState.connecting.label, '연결 중…');
      expect(BleConnectionState.connected.label, '연결 완료');
      expect(BleConnectionState.subscribed.label, '데이터 수신 중');
      expect(BleConnectionState.reconnecting.label, '연결 끊김 (재연결 중)');
      expect(BleConnectionState.failed.label, '연결 실패');
    });

    test('isActive가 connected와 subscribed에서만 true이다', () {
      expect(BleConnectionState.connected.isActive, isTrue);
      expect(BleConnectionState.subscribed.isActive, isTrue);
      expect(BleConnectionState.disconnected.isActive, isFalse);
      expect(BleConnectionState.scanning.isActive, isFalse);
      expect(BleConnectionState.connecting.isActive, isFalse);
      expect(BleConnectionState.reconnecting.isActive, isFalse);
      expect(BleConnectionState.failed.isActive, isFalse);
    });
  });
}
