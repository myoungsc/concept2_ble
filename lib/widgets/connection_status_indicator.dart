import 'package:flutter/material.dart';

import '../models/ble_device_state.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  final BleConnectionState state;

  const ConnectionStatusIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _icon,
          color: _color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          state.label,
          style: TextStyle(color: _color, fontSize: 12),
        ),
      ],
    );
  }

  IconData get _icon {
    switch (state) {
      case BleConnectionState.disconnected:
        return Icons.bluetooth_disabled;
      case BleConnectionState.scanning:
        return Icons.bluetooth_searching;
      case BleConnectionState.connecting:
        return Icons.bluetooth_searching;
      case BleConnectionState.connected:
        return Icons.bluetooth_connected;
      case BleConnectionState.subscribed:
        return Icons.bluetooth_connected;
      case BleConnectionState.reconnecting:
        return Icons.bluetooth_searching;
      case BleConnectionState.failed:
        return Icons.bluetooth_disabled;
    }
  }

  Color get _color {
    switch (state) {
      case BleConnectionState.disconnected:
        return Colors.grey;
      case BleConnectionState.scanning:
        return Colors.orange;
      case BleConnectionState.connecting:
        return Colors.orange;
      case BleConnectionState.connected:
        return Colors.blue;
      case BleConnectionState.subscribed:
        return Colors.green;
      case BleConnectionState.reconnecting:
        return Colors.orange;
      case BleConnectionState.failed:
        return Colors.red;
    }
  }
}
