import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ble_device_state.dart';
import '../models/rowing_data.dart';
import '../services/concept2_ble_service.dart';
import '../utils/concept2_constants.dart';

final bleServiceProvider = Provider<Concept2BleService>((ref) {
  final service = Concept2BleService();
  ref.onDispose(() => service.dispose());
  return service;
});

final isScanningProvider = StreamProvider<bool>((ref) {
  return FlutterBluePlus.isScanning;
});

final scanResultsProvider = StreamProvider<List<ScanResult>>((ref) {
  return FlutterBluePlus.scanResults.map((results) {
    return results.where((r) {
      final name = r.device.platformName;
      return name.isNotEmpty && Concept2Constants.isPm5Device(name);
    }).toList();
  });
});

final deviceConnectionStateProvider =
    StreamProvider<MapEntry<String, BleConnectionState>>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.connectionStateStream;
});

final rowingDataStreamProvider =
    StreamProvider<MapEntry<String, RowingData>>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.rowingDataStream;
});
