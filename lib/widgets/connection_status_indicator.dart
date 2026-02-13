import 'package:flutter/material.dart';

import '../models/ble_device_state.dart';
import '../theme/app_theme.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  final BleConnectionState state;

  const ConnectionStatusIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, color: _color, size: 14),
        const SizedBox(width: 6),
        Text(
          state.label,
          style: OlympicTextStyles.body(fontSize: 12, color: _color),
        ),
      ],
    );
  }

  IconData get _icon {
    switch (state) {
      case BleConnectionState.disconnected:
      case BleConnectionState.failed:
        return Icons.bluetooth_disabled;
      case BleConnectionState.scanning:
      case BleConnectionState.connecting:
      case BleConnectionState.reconnecting:
        return Icons.bluetooth_searching;
      case BleConnectionState.connected:
      case BleConnectionState.subscribed:
        return Icons.bluetooth_connected;
    }
  }

  Color get _color {
    switch (state) {
      case BleConnectionState.disconnected:
        return OlympicColors.gray500;
      case BleConnectionState.scanning:
      case BleConnectionState.connecting:
      case BleConnectionState.reconnecting:
        return OlympicColors.redOlympic;
      case BleConnectionState.connected:
        return OlympicColors.statusRowing;
      case BleConnectionState.subscribed:
        return OlympicColors.statusFinished;
      case BleConnectionState.failed:
        return OlympicColors.redOlympic;
    }
  }
}
