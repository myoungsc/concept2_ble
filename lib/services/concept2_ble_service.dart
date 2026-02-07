import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/ble_device_state.dart';
import '../models/rowing_data.dart';
import '../utils/concept2_constants.dart';

class Concept2BleService {
  final Map<String, StreamSubscription> _connectionSubscriptions = {};
  final Map<String, StreamSubscription> _dataSubscriptions = {};
  final Map<String, Timer> _reconnectTimers = {};
  final Map<String, Timer> _dataTimeoutTimers = {};
  final Map<String, int> _reconnectAttempts = {};

  final _connectionStateController =
      StreamController<MapEntry<String, BleConnectionState>>.broadcast();
  final _rowingDataController =
      StreamController<MapEntry<String, RowingData>>.broadcast();

  Stream<MapEntry<String, BleConnectionState>> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<MapEntry<String, RowingData>> get rowingDataStream =>
      _rowingDataController.stream;

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    await FlutterBluePlus.startScan(
      timeout: timeout,
      withServices: [Concept2Constants.rowingService],
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  Future<void> connectDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.str;
    _reconnectAttempts[deviceId] = 0;

    _emitState(deviceId, BleConnectionState.connecting);

    _connectionSubscriptions[deviceId]?.cancel();
    _connectionSubscriptions[deviceId] =
        device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _handleDisconnection(device);
      }
    });

    try {
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 15));
      _emitState(deviceId, BleConnectionState.connected);
      await _subscribeToCharacteristics(device);
    } catch (e) {
      _emitState(deviceId, BleConnectionState.failed);
    }
  }

  Future<void> _subscribeToCharacteristics(BluetoothDevice device) async {
    final deviceId = device.remoteId.str;

    try {
      final services = await device.discoverServices();
      final rowingService = services.firstWhere(
        (s) => s.serviceUuid == Concept2Constants.rowingService,
        orElse: () => throw Exception('Rowing service not found'),
      );

      // Subscribe to General Status
      final generalStatus = rowingService.characteristics.firstWhere(
        (c) => c.characteristicUuid == Concept2Constants.generalStatusChar,
        orElse: () => throw Exception('General status char not found'),
      );
      await generalStatus.setNotifyValue(true);

      // Optionally subscribe to Additional Status 1
      BluetoothCharacteristic? additionalStatus1;
      try {
        additionalStatus1 = rowingService.characteristics.firstWhere(
          (c) => c.characteristicUuid == Concept2Constants.additionalStatus1Char,
        );
        await additionalStatus1.setNotifyValue(true);
      } catch (_) {}

      // Optionally subscribe to Additional Status 2
      BluetoothCharacteristic? additionalStatus2;
      try {
        additionalStatus2 = rowingService.characteristics.firstWhere(
          (c) => c.characteristicUuid == Concept2Constants.additionalStatus2Char,
        );
        await additionalStatus2.setNotifyValue(true);
      } catch (_) {}

      _emitState(deviceId, BleConnectionState.subscribed);
      _reconnectAttempts[deviceId] = 0;

      // Listen to data from characteristics
      generalStatus.onValueReceived.listen((value) {
        _handleGeneralStatus(deviceId, value);
        _resetDataTimeout(device);
      });

      additionalStatus1?.onValueReceived.listen((value) {
        _handleAdditionalStatus1(deviceId, value);
      });

      additionalStatus2?.onValueReceived.listen((value) {
        _handleAdditionalStatus2(deviceId, value);
      });

      _startDataTimeout(device);
    } catch (e) {
      _emitState(deviceId, BleConnectionState.connected);
      // Retry subscription after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (_connectionSubscriptions.containsKey(deviceId)) {
          _subscribeToCharacteristics(device);
        }
      });
    }
  }

  // Accumulated data per device for merging characteristics
  final Map<String, RowingData> _latestData = {};

  void _handleGeneralStatus(String deviceId, List<int> value) {
    if (value.length < 19) return;

    final bytes = Uint8List.fromList(value);
    final elapsedTimeCs =
        bytes[0] | (bytes[1] << 8) | (bytes[2] << 16); // 0.01s
    final distanceTenths =
        bytes[3] | (bytes[4] << 8) | (bytes[5] << 16); // 0.1m
    final strokeRate = bytes[10];

    final data = (_latestData[deviceId] ?? RowingData(timestamp: DateTime.now()))
        .copyWith(
      elapsedTime: Duration(milliseconds: elapsedTimeCs * 10),
      distanceMeters: distanceTenths / 10.0,
      strokeRate: strokeRate,
      timestamp: DateTime.now(),
    );

    _latestData[deviceId] = data;
    _rowingDataController.add(MapEntry(deviceId, data));
  }

  void _handleAdditionalStatus1(String deviceId, List<int> value) {
    if (value.length < 11) return;

    final bytes = Uint8List.fromList(value);
    final strokeRate = bytes[5];
    final heartRate = bytes[6];
    final currentPaceCs = bytes[7] | (bytes[8] << 8); // 0.01s per 500m

    final data = (_latestData[deviceId] ?? RowingData(timestamp: DateTime.now()))
        .copyWith(
      strokeRate: strokeRate,
      heartRate: heartRate,
      pace500m: currentPaceCs / 100.0,
      timestamp: DateTime.now(),
    );

    _latestData[deviceId] = data;
    _rowingDataController.add(MapEntry(deviceId, data));
  }

  void _handleAdditionalStatus2(String deviceId, List<int> value) {
    if (value.length < 6) return;

    final bytes = Uint8List.fromList(value);
    final avgPower = bytes[4] | (bytes[5] << 8); // watts

    final data = (_latestData[deviceId] ?? RowingData(timestamp: DateTime.now()))
        .copyWith(
      watts: avgPower,
      timestamp: DateTime.now(),
    );

    _latestData[deviceId] = data;
    _rowingDataController.add(MapEntry(deviceId, data));
  }

  void _handleDisconnection(BluetoothDevice device) {
    final deviceId = device.remoteId.str;
    final attempts = _reconnectAttempts[deviceId] ?? 0;

    if (attempts >= _maxTotalAttempts()) {
      _emitState(deviceId, BleConnectionState.failed);
      return;
    }

    _emitState(deviceId, BleConnectionState.reconnecting);
    _reconnectAttempts[deviceId] = attempts + 1;

    final delay = _getReconnectDelay(attempts);
    _reconnectTimers[deviceId]?.cancel();
    _reconnectTimers[deviceId] = Timer(delay, () {
      _attemptReconnect(device);
    });
  }

  Duration _getReconnectDelay(int attempt) {
    if (attempt < Concept2Constants.maxImmediateRetries) {
      return const Duration(milliseconds: 500);
    }
    final backoffSeconds = min(
      pow(2, attempt - Concept2Constants.maxImmediateRetries).toInt(),
      Concept2Constants.maxReconnectTimeSeconds,
    );
    return Duration(seconds: backoffSeconds);
  }

  int _maxTotalAttempts() {
    // ~60 seconds worth of attempts
    return Concept2Constants.maxImmediateRetries + 6;
  }

  Future<void> _attemptReconnect(BluetoothDevice device) async {
    final deviceId = device.remoteId.str;
    try {
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 10));
      _emitState(deviceId, BleConnectionState.connected);
      await _subscribeToCharacteristics(device);
    } catch (_) {
      _handleDisconnection(device);
    }
  }

  void _startDataTimeout(BluetoothDevice device) {
    final deviceId = device.remoteId.str;
    _dataTimeoutTimers[deviceId]?.cancel();
    _dataTimeoutTimers[deviceId] = Timer(
      Concept2Constants.dataTimeoutDuration,
      () => _handleDataTimeout(device),
    );
  }

  void _resetDataTimeout(BluetoothDevice device) {
    _startDataTimeout(device);
  }

  void _handleDataTimeout(BluetoothDevice device) {
    // If connected but no data, try resubscribing
    _subscribeToCharacteristics(device);
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    final id = device.remoteId.str;
    _cleanup(id);
    try {
      await device.disconnect();
    } catch (_) {}
    _emitState(id, BleConnectionState.disconnected);
  }

  void _cleanup(String deviceId) {
    _connectionSubscriptions[deviceId]?.cancel();
    _connectionSubscriptions.remove(deviceId);
    _dataSubscriptions[deviceId]?.cancel();
    _dataSubscriptions.remove(deviceId);
    _reconnectTimers[deviceId]?.cancel();
    _reconnectTimers.remove(deviceId);
    _dataTimeoutTimers[deviceId]?.cancel();
    _dataTimeoutTimers.remove(deviceId);
    _reconnectAttempts.remove(deviceId);
    _latestData.remove(deviceId);
  }

  void _emitState(String deviceId, BleConnectionState state) {
    _connectionStateController.add(MapEntry(deviceId, state));
  }

  void dispose() {
    for (final id in _connectionSubscriptions.keys.toList()) {
      _cleanup(id);
    }
    _connectionStateController.close();
    _rowingDataController.close();
  }

  // Static utility for parsing rowing data (for testing)
  static RowingData parseGeneralStatus(List<int> value) {
    if (value.length < 19) {
      return RowingData(timestamp: DateTime.now());
    }
    final bytes = Uint8List.fromList(value);
    final elapsedTimeCs = bytes[0] | (bytes[1] << 8) | (bytes[2] << 16);
    final distanceTenths = bytes[3] | (bytes[4] << 8) | (bytes[5] << 16);
    final strokeRate = bytes[10];

    return RowingData(
      elapsedTime: Duration(milliseconds: elapsedTimeCs * 10),
      distanceMeters: distanceTenths / 10.0,
      strokeRate: strokeRate,
      timestamp: DateTime.now(),
    );
  }
}

