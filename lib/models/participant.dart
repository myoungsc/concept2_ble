import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_device_state.dart';
import 'rowing_data.dart';

class Participant {
  final String id;
  final String name;
  final int laneNumber;
  final BluetoothDevice? device;
  final BleConnectionState connectionState;
  final RowingData? latestData;
  final bool isFinished;
  final Duration? finishTime;
  final int reconnectAttempts;

  const Participant({
    required this.id,
    required this.name,
    required this.laneNumber,
    this.device,
    this.connectionState = BleConnectionState.disconnected,
    this.latestData,
    this.isFinished = false,
    this.finishTime,
    this.reconnectAttempts = 0,
  });

  double get currentDistance => latestData?.distanceMeters ?? 0;

  Participant copyWith({
    String? name,
    int? laneNumber,
    BluetoothDevice? device,
    BleConnectionState? connectionState,
    RowingData? latestData,
    bool? isFinished,
    Duration? finishTime,
    int? reconnectAttempts,
  }) {
    return Participant(
      id: id,
      name: name ?? this.name,
      laneNumber: laneNumber ?? this.laneNumber,
      device: device ?? this.device,
      connectionState: connectionState ?? this.connectionState,
      latestData: latestData ?? this.latestData,
      isFinished: isFinished ?? this.isFinished,
      finishTime: finishTime ?? this.finishTime,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }
}
