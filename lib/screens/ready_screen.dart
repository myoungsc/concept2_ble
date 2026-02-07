import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ble_device_state.dart';
import '../models/race_config.dart';
import '../providers/race_provider.dart';
import '../widgets/connection_status_indicator.dart';
import 'race_screen.dart';

class ReadyScreen extends ConsumerStatefulWidget {
  const ReadyScreen({super.key});

  @override
  ConsumerState<ReadyScreen> createState() => _ReadyScreenState();
}

class _ReadyScreenState extends ConsumerState<ReadyScreen> {
  bool _isWaiting = false;

  @override
  Widget build(BuildContext context) {
    final raceState = ref.watch(raceProvider);

    // Auto-navigate to race screen when race starts
    if (raceState.phase == RacePhase.racing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RaceScreen()),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('레이스 준비'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target distance display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    '목표 거리',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${raceState.config.targetDistanceMeters}m',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Participants list
            const Text(
              '참가자 목록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: raceState.participants.length,
                itemBuilder: (context, index) {
                  final p = raceState.participants[index];
                  final isReady =
                      p.connectionState == BleConnectionState.subscribed ||
                          p.connectionState == BleConnectionState.connected;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isReady ? Colors.green : Colors.orange,
                        child: Text(
                          '${p.laneNumber}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: ConnectionStatusIndicator(
                        state: p.connectionState,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isReady
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isReady ? Colors.green : Colors.orange,
                          ),
                        ),
                        child: Text(
                          isReady ? '준비됨' : '미준비',
                          style: TextStyle(
                            color: isReady ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_isWaiting)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '로잉을 시작하면 레이스가 자동으로 시작됩니다',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: _startWaiting,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('대기 시작'),
              ),
          ],
        ),
      ),
    );
  }

  void _startWaiting() {
    ref.read(raceProvider.notifier).enterReadyPhase();
    setState(() => _isWaiting = true);
  }
}
