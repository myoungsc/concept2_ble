import 'package:flutter_test/flutter_test.dart';
import 'package:concept2_ble/models/ble_device_state.dart';

void main() {
  group('BleConnectionState', () {
    test('모든 상태에 한글 라벨이 있다', () {
      for (final state in BleConnectionState.values) {
        expect(state.label, isNotEmpty);
      }
    });

    test('라벨이 올바른 번역 키를 사용한다', () {
      // 테스트 환경에서 .tr()은 키 자체를 반환
      expect(BleConnectionState.disconnected.label, 'ble_disconnected');
      expect(BleConnectionState.scanning.label, 'ble_scanning');
      expect(BleConnectionState.connecting.label, 'ble_connecting');
      expect(BleConnectionState.connected.label, 'ble_connected');
      expect(BleConnectionState.subscribed.label, 'ble_subscribed');
      expect(BleConnectionState.reconnecting.label, 'ble_reconnecting');
      expect(BleConnectionState.failed.label, 'ble_failed');
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
