import 'package:easy_localization/easy_localization.dart';

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
        return 'ble_disconnected'.tr();
      case BleConnectionState.scanning:
        return 'ble_scanning'.tr();
      case BleConnectionState.connecting:
        return 'ble_connecting'.tr();
      case BleConnectionState.connected:
        return 'ble_connected'.tr();
      case BleConnectionState.subscribed:
        return 'ble_subscribed'.tr();
      case BleConnectionState.reconnecting:
        return 'ble_reconnecting'.tr();
      case BleConnectionState.failed:
        return 'ble_failed'.tr();
    }
  }

  bool get isActive =>
      this == BleConnectionState.connected ||
      this == BleConnectionState.subscribed;
}
