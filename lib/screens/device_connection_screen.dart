import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ble_device_state.dart';
import '../models/race_config.dart';
import '../providers/ble_provider.dart';
import '../providers/race_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_status_indicator.dart';
import 'ready_screen.dart';

final btAdapterStateProvider = StreamProvider<BluetoothAdapterState>((ref) {
  return FlutterBluePlus.adapterState;
});

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
  final Set<String> _connectingDeviceIds = {};
  final Set<String> _disconnectingDeviceIds = {};
  bool _autoScanStarted = false;

  @override
  void dispose() {
    for (final c in _nameControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btState = ref.watch(btAdapterStateProvider);

    return btState.when(
      data: (state) {
        if (state != BluetoothAdapterState.on) {
          _autoScanStarted = false;
          return _buildBluetoothOffScreen();
        }
        if (!_autoScanStarted) {
          _autoScanStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
        }
        return _buildScanScreen();
      },
      loading: () => _buildBluetoothOffScreen(),
      error: (_, __) => _buildBluetoothOffScreen(),
    );
  }

  Widget _buildBluetoothOffScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'connect_devices'.tr().toUpperCase(),
          style: OlympicTextStyles.label(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: OlympicColors.white,
            letterSpacing: 3,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bluetooth_disabled,
              size: 80,
              color: OlympicColors.redOlympic,
            ),
            const SizedBox(height: 24),
            Text(
              'bt_turn_on'.tr(),
              style: OlympicTextStyles.headline(fontSize: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'bt_turn_on_desc'.tr(),
              style: OlympicTextStyles.body(
                fontSize: 14,
                color: OlympicColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await FlutterBluePlus.turnOn();
                } catch (_) {}
              },
              icon: const Icon(Icons.bluetooth, size: 20),
              label: Text(
                'bt_enable'.tr().toUpperCase(),
                style: OlympicTextStyles.label(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: OlympicColors.white,
                  letterSpacing: 2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: OlympicColors.blueOlympic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanScreen() {
    final raceState = ref.watch(raceProvider);
    final scanResults = ref.watch(scanResultsProvider);
    final isScanning = ref.watch(isScanningProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'connect_devices'.tr().toUpperCase(),
          style: OlympicTextStyles.label(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: OlympicColors.white,
            letterSpacing: 3,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (raceState.participants.isNotEmpty) ...[
              Text(
                'connected'.tr().toUpperCase(),
                style: OlympicTextStyles.label(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: OlympicColors.white,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              ...raceState.participants.asMap().entries.map((entry) {
                final index = entry.key;
                final p = entry.value;
                _nameControllers.putIfAbsent(
                  p.id,
                  () => TextEditingController(text: p.name),
                );
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.laneColor(index),
                      child: Text(
                        '${p.laneNumber}',
                        style: OlympicTextStyles.bigNumber(
                          fontSize: 20,
                          color: OlympicColors.white,
                        ),
                      ),
                    ),
                    title: TextField(
                      controller: _nameControllers[p.id],
                      decoration: InputDecoration(
                        hintText: 'participant_hint'.tr(),
                        border: InputBorder.none,
                        isDense: true,
                        filled: false,
                        hintStyle: TextStyle(color: OlympicColors.gray500),
                      ),
                      style: OlympicTextStyles.participantName(fontSize: 16),
                      onChanged: (value) {
                        ref
                            .read(raceProvider.notifier)
                            .updateParticipantName(p.id, value);
                      },
                    ),
                    subtitle: ConnectionStatusIndicator(
                      state: p.connectionState,
                    ),
                    trailing: _buildDisconnectButton(p.id, p.device),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Divider(color: OlympicColors.bgElevated),
              const SizedBox(height: 8),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'scan_devices'.tr().toUpperCase(),
                  style: OlympicTextStyles.label(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: OlympicColors.white,
                    letterSpacing: 3,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed:
                      isScanning.value == true ? _stopScan : _startScan,
                  icon: Icon(
                    isScanning.value == true
                        ? Icons.stop
                        : Icons.bluetooth_searching,
                    size: 18,
                  ),
                  label: Text(
                    isScanning.value == true
                        ? 'stop'.tr().toUpperCase()
                        : 'scan'.tr().toUpperCase(),
                    style: OlympicTextStyles.label(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: OlympicColors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isScanning.value == true
                        ? OlympicColors.bgElevated
                        : OlympicColors.blueOlympic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: scanResults.when(
                data: (results) {
                  final filteredResults = results
                      .where((r) =>
                          !_connectedDeviceIds
                              .contains(r.device.remoteId.str))
                      .toList();

                  if (filteredResults.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bluetooth_searching,
                              size: 48, color: OlympicColors.gray500),
                          const SizedBox(height: 12),
                          Text(
                            isScanning.value == true
                                ? 'scanning_pm5'.tr()
                                : 'scan_to_search'.tr(),
                            style: OlympicTextStyles.body(
                              color: OlympicColors.gray500,
                              fontSize: 16,
                            ),
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
                          leading: const Icon(Icons.rowing,
                              color: OlympicColors.blueOlympic),
                          title: Text(
                            device.platformName.isNotEmpty
                                ? device.platformName
                                : 'PM5',
                            style: OlympicTextStyles.participantName(
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'ID: ${device.remoteId.str.substring(device.remoteId.str.length > 8 ? device.remoteId.str.length - 8 : 0)}',
                            style: OlympicTextStyles.body(
                              color: OlympicColors.gray500,
                              fontSize: 12,
                            ),
                          ),
                          trailing: _buildConnectButton(device),
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('오류: $e',
                      style: OlympicTextStyles.body(
                          color: OlympicColors.redOlympic)),
                ),
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _canProceed(raceState) ? _goNext : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: OlympicColors.bgElevated,
                disabledForegroundColor: OlympicColors.gray500,
              ),
              child: Text(
                'done_count'.tr(namedArgs: {
                  'count': '${raceState.participants.length}',
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startScan() async {
    try {
      final service = ref.read(bleServiceProvider);
      await service.startScan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'bt_turn_on'.tr(),
              style: OlympicTextStyles.body(),
            ),
            backgroundColor: OlympicColors.redOlympic,
          ),
        );
      }
    }
  }

  Future<void> _stopScan() async {
    final service = ref.read(bleServiceProvider);
    await service.stopScan();
  }

  bool _canProceed(RaceState raceState) {
    if (raceState.participants.isEmpty) return false;
    return raceState.participants.every((p) =>
        p.connectionState == BleConnectionState.connected ||
        p.connectionState == BleConnectionState.subscribed);
  }

  Widget _buildDisconnectButton(String participantId, dynamic device) {
    final isDisconnecting = _disconnectingDeviceIds.contains(participantId);

    return ElevatedButton(
      onPressed: isDisconnecting ? null : () => _removeDevice(participantId, device),
      style: ElevatedButton.styleFrom(
        backgroundColor: OlympicColors.bgElevated,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(80, 36),
        disabledBackgroundColor: OlympicColors.bgElevated.withValues(alpha: 0.5),
      ),
      child: isDisconnecting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: OlympicColors.redOlympic,
              ),
            )
          : Text(
              'disconnect'.tr().toUpperCase(),
              style: OlympicTextStyles.label(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: OlympicColors.redOlympic,
                letterSpacing: 2,
              ),
            ),
    );
  }

  Widget _buildConnectButton(BluetoothDevice device) {
    final deviceId = device.remoteId.str;
    final isConnecting = _connectingDeviceIds.contains(deviceId);

    return ElevatedButton(
      onPressed: isConnecting ? null : () => _connectDevice(device),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        minimumSize: const Size(90, 36),
        disabledBackgroundColor: OlympicColors.blueOlympic.withValues(alpha: 0.5),
      ),
      child: isConnecting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: OlympicColors.white,
              ),
            )
          : Text(
              'connect'.tr().toUpperCase(),
              style: OlympicTextStyles.label(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: OlympicColors.white,
                letterSpacing: 2,
              ),
            ),
    );
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.str;
    setState(() => _connectingDeviceIds.add(deviceId));

    try {
      final service = ref.read(bleServiceProvider);
      await service.connectDevice(device);
      _connectedDeviceIds.add(deviceId);

      final defaultName = 'default_participant'.tr(namedArgs: {
        'n': '${ref.read(raceProvider).participants.length + 1}',
      });
      ref.read(raceProvider.notifier).addParticipant(defaultName, device);
    } finally {
      if (mounted) setState(() => _connectingDeviceIds.remove(deviceId));
    }
  }

  Future<void> _removeDevice(String participantId, dynamic device) async {
    setState(() => _disconnectingDeviceIds.add(participantId));
    try {
      if (device != null) {
        final service = ref.read(bleServiceProvider);
        await service.disconnectDevice(device);
        _connectedDeviceIds.remove(participantId);
      }
      ref.read(raceProvider.notifier).removeParticipant(participantId);
      _nameControllers.remove(participantId)?.dispose();
    } finally {
      if (mounted) setState(() => _disconnectingDeviceIds.remove(participantId));
    }
  }

  void _goNext() {
    final participants = ref.read(raceProvider).participants;
    final hasEmptyNames = participants.any((p) => p.name.trim().isEmpty);
    if (hasEmptyNames) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'enter_all_names'.tr(),
            style: OlympicTextStyles.body(),
          ),
          backgroundColor: OlympicColors.redOlympic,
        ),
      );
      return;
    }

    ref.read(raceProvider.notifier).setPhase(RacePhase.warmup);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReadyScreen()),
    );
  }
}
