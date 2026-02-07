enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  subscribed,
  reconnecting,
  failed,
}

extension BleConnectionStateX on BleConnectionState {
  String get label {
    switch (this) {
      case BleConnectionState.disconnected:
        return '연결 안됨';
      case BleConnectionState.scanning:
        return '스캔 중…';
      case BleConnectionState.connecting:
        return '연결 중…';
      case BleConnectionState.connected:
        return '연결 완료';
      case BleConnectionState.subscribed:
        return '데이터 수신 중';
      case BleConnectionState.reconnecting:
        return '연결 끊김 (재연결 중)';
      case BleConnectionState.failed:
        return '연결 실패';
    }
  }

  bool get isActive =>
      this == BleConnectionState.connected ||
      this == BleConnectionState.subscribed;
}
