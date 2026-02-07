import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ble_provider.dart';
import '../providers/race_provider.dart';
import '../widgets/connection_status_indicator.dart';
import 'ready_screen.dart';

class DeviceConnectionScreen extends ConsumerStatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  ConsumerState<DeviceConnectionScreen> createState() =>
      _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState
    extends ConsumerState<DeviceConnectionScreen> {
  final Map<String, TextEditingController> _nameControllers = {};
  final Set<String> _connectedDeviceIds = {};

  @override
  void dispose() {
    for (final c in _nameControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final raceState = ref.watch(raceProvider);
    final scanResults = ref.watch(scanResultsProvider);
    final isScanning = ref.watch(isScanningProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('로잉머신 연결'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connected devices
            if (raceState.participants.isNotEmpty) ...[
              const Text(
                '연결된 기기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...raceState.participants.map((p) {
                _nameControllers.putIfAbsent(
                  p.id,
                  () => TextEditingController(text: p.name),
                );
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        '${p.laneNumber}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: TextField(
                      controller: _nameControllers[p.id],
                      decoration: const InputDecoration(
                        hintText: '참가자 이름',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      onChanged: (value) {
                        ref
                            .read(raceProvider.notifier)
                            .updateParticipantName(p.id, value);
                      },
                    ),
                    subtitle: ConnectionStatusIndicator(
                      state: p.connectionState,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _removeDevice(p.id, p.device),
                    ),
                  ),
                );
              }),
              const Divider(height: 24),
            ],

            // Scan section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '기기 검색',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed:
                      isScanning.value == true ? _stopScan : _startScan,
                  icon: Icon(
                    isScanning.value == true
                        ? Icons.stop
                        : Icons.bluetooth_searching,
                  ),
                  label: Text(
                    isScanning.value == true ? '중지' : '스캔 시작',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Scan results
            Expanded(
              child: scanResults.when(
                data: (results) {
                  final filteredResults = results
                      .where((r) =>
                          !_connectedDeviceIds.contains(r.device.remoteId.str))
                      .toList();

                  if (filteredResults.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bluetooth_searching,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            isScanning.value == true
                                ? 'PM5 검색 중...'
                                : '스캔 시작을 눌러 PM5를 검색하세요',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredResults.length,
                    itemBuilder: (context, index) {
                      final result = filteredResults[index];
                      final device = result.device;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.rowing, color: Colors.blue),
                          title: Text(
                            device.platformName.isNotEmpty
                                ? device.platformName
                                : 'PM5',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'ID: ${device.remoteId.str.substring(device.remoteId.str.length > 8 ? device.remoteId.str.length - 8 : 0)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _connectDevice(device),
                            child: const Text('연결'),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('오류: $e')),
              ),
            ),

            // Complete button
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: raceState.participants.isNotEmpty ? _goNext : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: Text(
                '완료 (${raceState.participants.length}명)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startScan() async {
    final service = ref.read(bleServiceProvider);
    await service.startScan();
  }

  Future<void> _stopScan() async {
    final service = ref.read(bleServiceProvider);
    await service.stopScan();
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    final service = ref.read(bleServiceProvider);
    await service.connectDevice(device);
    _connectedDeviceIds.add(device.remoteId.str);

    final defaultName = '참가자 ${ref.read(raceProvider).participants.length + 1}';
    ref.read(raceProvider.notifier).addParticipant(defaultName, device);
  }

  Future<void> _removeDevice(String participantId, dynamic device) async {
    if (device != null) {
      final service = ref.read(bleServiceProvider);
      await service.disconnectDevice(device);
      _connectedDeviceIds.remove(participantId);
    }
    ref.read(raceProvider.notifier).removeParticipant(participantId);
    _nameControllers.remove(participantId)?.dispose();
  }

  void _goNext() {
    // Validate all names are set
    final participants = ref.read(raceProvider).participants;
    final hasEmptyNames = participants.any((p) => p.name.trim().isEmpty);
    if (hasEmptyNames) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 참가자의 이름을 입력해주세요')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReadyScreen()),
    );
  }
}
