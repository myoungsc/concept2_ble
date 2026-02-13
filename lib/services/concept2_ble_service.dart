import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/ble_device_state.dart';
import '../models/rowing_data.dart';
import '../utils/concept2_constants.dart';

class Concept2BleService {
  final Map<String, StreamSubscription> _connectionSubscriptions = {};
  final Map<String, List<StreamSubscription>> _charSubscriptions = {};
  final Map<String, Timer> _reconnectTimers = {};
  final Map<String, Timer> _dataTimeoutTimers = {};
  final Map<String, int> _reconnectAttempts = {};
  final Map<String, BluetoothDevice> _devices = {};

  bool _raceMode = false;

  final _connectionStateController =
      StreamController<MapEntry<String, BleConnectionState>>.broadcast();
  final _rowingDataController =
      StreamController<MapEntry<String, RowingData>>.broadcast();

  Stream<MapEntry<String, BleConnectionState>> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<MapEntry<String, RowingData>> get rowingDataStream =>
      _rowingDataController.stream;

  void setRaceMode(bool active) {
    _raceMode = active;
    if (active) {
      for (final device in _devices.values) {
        _requestHighPriority(device);
      }
    }
  }

  Future<void> _requestHighPriority(BluetoothDevice device) async {
    try {
      await device.requestConnectionPriority(
        connectionPriorityRequest: ConnectionPriority.high,
      );
    } catch (_) {}
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    await FlutterBluePlus.startScan(
      timeout: timeout,
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  Future<void> connectDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.str;
    _devices[deviceId] = device;
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
      if (_raceMode) {
        _scheduleReconnect(device, 0);
      }
    }
  }

  Future<void> _subscribeToCharacteristics(BluetoothDevice device) async {
    final deviceId = device.remoteId.str;

    _cancelCharSubscriptions(deviceId);

    try {
      final services = await device.discoverServices();
      final rowingService = services.firstWhere(
        (s) => s.serviceUuid == Concept2Constants.rowingService,
        orElse: () => throw Exception('Rowing service not found'),
      );

      final generalStatus = rowingService.characteristics.firstWhere(
        (c) => c.characteristicUuid == Concept2Constants.generalStatusChar,
        orElse: () => throw Exception('General status char not found'),
      );
      await generalStatus.setNotifyValue(true);

      BluetoothCharacteristic? additionalStatus1;
      try {
        additionalStatus1 = rowingService.characteristics.firstWhere(
          (c) => c.characteristicUuid == Concept2Constants.additionalStatus1Char,
        );
        await additionalStatus1.setNotifyValue(true);
      } catch (_) {}

      BluetoothCharacteristic? additionalStatus2;
      try {
        additionalStatus2 = rowingService.characteristics.firstWhere(
          (c) => c.characteristicUuid == Concept2Constants.additionalStatus2Char,
        );
        await additionalStatus2.setNotifyValue(true);
      } catch (_) {}

      _emitState(deviceId, BleConnectionState.subscribed);
      _reconnectAttempts[deviceId] = 0;

      final subs = <StreamSubscription>[];

      subs.add(generalStatus.onValueReceived.listen((value) {
        _handleGeneralStatus(deviceId, value);
        _resetDataTimeout(device);
      }));

      if (additionalStatus1 != null) {
        subs.add(additionalStatus1.onValueReceived.listen((value) {
          _handleAdditionalStatus1(deviceId, value);
        }));
      }

      if (additionalStatus2 != null) {
        subs.add(additionalStatus2.onValueReceived.listen((value) {
          _handleAdditionalStatus2(deviceId, value);
        }));
      }

      _charSubscriptions[deviceId] = subs;

      if (_raceMode) {
        await _requestHighPriority(device);
      }

      _startDataTimeout(device);
    } catch (e) {
      _emitState(deviceId, BleConnectionState.connected);
      Future.delayed(const Duration(seconds: 2), () {
        if (_connectionSubscriptions.containsKey(deviceId)) {
          _subscribeToCharacteristics(device);
        }
      });
    }
  }

  void _cancelCharSubscriptions(String deviceId) {
    final subs = _charSubscriptions.remove(deviceId);
    if (subs != null) {
      for (final sub in subs) {
        sub.cancel();
      }
    }
  }

  final Map<String, RowingData> _latestData = {};

  void _handleGeneralStatus(String deviceId, List<int> value) {
    if (value.length < 19) return;

    final bytes = Uint8List.fromList(value);
    final elapsedTimeCs =
        bytes[0] | (bytes[1] << 8) | (bytes[2] << 16);
    final distanceTenths =
        bytes[3] | (bytes[4] << 8) | (bytes[5] << 16);
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
    final currentPaceCs = bytes[7] | (bytes[8] << 8);

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
    final avgPower = bytes[4] | (bytes[5] << 8);

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

    _cancelCharSubscriptions(deviceId);
    _dataTimeoutTimers[deviceId]?.cancel();

    final attempts = _reconnectAttempts[deviceId] ?? 0;

    if (!_raceMode && attempts >= _maxTotalAttempts()) {
      _emitState(deviceId, BleConnectionState.failed);
      return;
    }

    _emitState(deviceId, BleConnectionState.reconnecting);
    _scheduleReconnect(device, attempts);
  }

  void _scheduleReconnect(BluetoothDevice device, int attempts) {
    final deviceId = device.remoteId.str;
    _reconnectAttempts[deviceId] = attempts + 1;

    final delay = _getReconnectDelay(attempts);
    _reconnectTimers[deviceId]?.cancel();
    _reconnectTimers[deviceId] = Timer(delay, () {
      _attemptReconnect(device);
    });
  }

  Duration _getReconnectDelay(int attempt) {
    if (_raceMode) {
      if (attempt < 3) return const Duration(milliseconds: 300);
      if (attempt < 6) return const Duration(seconds: 1);
      return const Duration(seconds: 2);
    }

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
    return Concept2Constants.maxImmediateRetries + 6;
  }

  Future<void> _attemptReconnect(BluetoothDevice device) async {
    final deviceId = device.remoteId.str;

    if (!_devices.containsKey(deviceId)) return;

    try {
      await device.connect(
        autoConnect: false,
        timeout: Duration(seconds: _raceMode ? 8 : 10),
      );
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
      _raceMode
          ? Concept2Constants.raceDataTimeoutDuration
          : Concept2Constants.dataTimeoutDuration,
      () => _handleDataTimeout(device),
    );
  }

  void _resetDataTimeout(BluetoothDevice device) {
    _startDataTimeout(device);
  }

  void _handleDataTimeout(BluetoothDevice device) {
    _cancelCharSubscriptions(device.remoteId.str);
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
    _cancelCharSubscriptions(deviceId);
    _reconnectTimers[deviceId]?.cancel();
    _reconnectTimers.remove(deviceId);
    _dataTimeoutTimers[deviceId]?.cancel();
    _dataTimeoutTimers.remove(deviceId);
    _reconnectAttempts.remove(deviceId);
    _latestData.remove(deviceId);
    _devices.remove(deviceId);
  }

  void _emitState(String deviceId, BleConnectionState state) {
    _connectionStateController.add(MapEntry(deviceId, state));
  }

  void dispose() {
    for (final id in _devices.keys.toList()) {
      _cleanup(id);
    }
    _connectionStateController.close();
    _rowingDataController.close();
  }

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
