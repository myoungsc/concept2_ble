import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/race_config.dart';
import '../providers/race_provider.dart';
import 'device_connection_screen.dart';

class DistanceSetupScreen extends ConsumerStatefulWidget {
  const DistanceSetupScreen({super.key});

  @override
  ConsumerState<DistanceSetupScreen> createState() =>
      _DistanceSetupScreenState();
}

class _DistanceSetupScreenState extends ConsumerState<DistanceSetupScreen> {
  int? _selectedDistance;
  final _customController = TextEditingController();
  bool _isCustom = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('목표 거리 설정'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BLE notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '원활한 연결을 위해 ErgData 및 다른 BLE 앱 연결을 해제해주세요.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '레이스 거리를 선택하세요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Preset buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: RaceConfig.presetDistances.map((d) {
                final isSelected = !_isCustom && _selectedDistance == d;
                return ChoiceChip(
                  label: Text(
                    '${d}m',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedDistance = d;
                      _isCustom = false;
                      _customController.clear();
                    });
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            // Custom input
            const Text(
              '직접 입력 (100m ~ 10,000m)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      hintText: '거리 입력',
                      suffixText: 'm',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      final distance = int.tryParse(value);
                      setState(() {
                        if (distance != null &&
                            distance >= RaceConfig.minDistance &&
                            distance <= RaceConfig.maxDistance) {
                          _selectedDistance = distance;
                          _isCustom = true;
                        } else {
                          if (_isCustom) _selectedDistance = null;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Next button
            ElevatedButton(
              onPressed: _selectedDistance != null ? _goNext : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('다음'),
            ),
          ],
        ),
      ),
    );
  }

  void _goNext() {
    if (_selectedDistance == null) return;
    ref.read(raceProvider.notifier).setTargetDistance(_selectedDistance!);
    ref.read(raceProvider.notifier).setPhase(RacePhase.connecting);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DeviceConnectionScreen(),
      ),
    );
  }
}
