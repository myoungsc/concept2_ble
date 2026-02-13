import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ble_device_state.dart';
import '../models/race_config.dart';
import '../providers/race_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/countdown_overlay.dart';
import 'race_screen.dart';

class ReadyScreen extends ConsumerStatefulWidget {
  const ReadyScreen({super.key});

  @override
  ConsumerState<ReadyScreen> createState() => _ReadyScreenState();
}

class _ReadyScreenState extends ConsumerState<ReadyScreen> {
  @override
  Widget build(BuildContext context) {
    final raceState = ref.watch(raceProvider);

    if (raceState.phase == RacePhase.racing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RaceScreen()),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'warmup_title'.tr().toUpperCase(),
          style: OlympicTextStyles.label(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: OlympicColors.white,
            letterSpacing: 3,
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTargetBanner(raceState),
                const SizedBox(height: 24),
                _buildResetInstruction(raceState),
                const SizedBox(height: 16),
                Text(
                  'participants'.tr().toUpperCase(),
                  style: OlympicTextStyles.label(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: OlympicColors.white,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: raceState.participants.length,
                    itemBuilder: (context, index) {
                      final p = raceState.participants[index];
                      return _buildParticipantTile(p, index);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildStartButton(raceState),
              ],
            ),
          ),
          if (raceState.phase == RacePhase.countdown)
            CountdownOverlay(
              onComplete: () {
                ref.read(raceProvider.notifier).startRace();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTargetBanner(RaceState raceState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: OlympicColors.blueOlympic,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'target'.tr().toUpperCase(),
            style: OlympicTextStyles.label(
              fontSize: 12,
              color: OlympicColors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${raceState.config.targetDistanceMeters}M',
            style: OlympicTextStyles.headline(fontSize: 44),
          ),
        ],
      ),
    );
  }

  Widget _buildResetInstruction(RaceState raceState) {
    final allZero = raceState.allDevicesAtZero;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OlympicColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: allZero
              ? OlympicColors.statusFinished.withValues(alpha: 0.3)
              : OlympicColors.redOlympic.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            allZero ? Icons.check_circle : Icons.warning_amber_rounded,
            color: allZero
                ? OlympicColors.statusFinished
                : OlympicColors.redOlympic,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              allZero
                  ? 'all_devices_zero'.tr()
                  : 'reset_pm5_instruction'.tr(),
              style: OlympicTextStyles.body(
                fontSize: 13,
                color: OlympicColors.gray300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(dynamic p, int index) {
    final isConnected =
        p.connectionState == BleConnectionState.subscribed ||
            p.connectionState == BleConnectionState.connected;
    final hasData = p.latestData != null;
    final isAtZero = hasData && p.currentDistance <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAtZero
              ? OlympicColors.statusFinished
              : isConnected
                  ? OlympicColors.blueOlympic
                  : OlympicColors.redOlympic.withValues(alpha: 0.7),
          child: Text(
            '${p.laneNumber}',
            style: OlympicTextStyles.bigNumber(
              fontSize: 20,
              color: OlympicColors.white,
            ),
          ),
        ),
        title: Text(
          p.name.toUpperCase(),
          style: OlympicTextStyles.participantName(fontSize: 16),
        ),
        subtitle: ConnectionStatusIndicator(
          state: p.connectionState,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasData)
              Text(
                '${p.currentDistance.toStringAsFixed(1)}m',
                style: OlympicTextStyles.mono(
                  fontSize: 16,
                  color: isAtZero
                      ? OlympicColors.statusFinished
                      : OlympicColors.redOlympic,
                ),
              ),
            if (!hasData)
              Text(
                'waiting_data'.tr(),
                style: OlympicTextStyles.body(
                  fontSize: 12,
                  color: OlympicColors.gray500,
                ),
              ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isAtZero
                    ? OlympicColors.statusFinished
                        .withValues(alpha: 0.15)
                    : OlympicColors.redOlympic
                        .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isAtZero
                      ? OlympicColors.statusFinished
                          .withValues(alpha: 0.4)
                      : OlympicColors.redOlympic
                          .withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                isAtZero
                    ? 'confirmed_zero'.tr()
                    : 'needs_reset'.tr(),
                style: OlympicTextStyles.label(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isAtZero
                      ? OlympicColors.statusFinishedLight
                      : OlympicColors.redOlympic,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(RaceState raceState) {
    final canStart = raceState.allDevicesAtZero &&
        raceState.phase == RacePhase.warmup;

    return ElevatedButton(
      onPressed: canStart ? _startCountdown : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        disabledBackgroundColor: OlympicColors.bgElevated,
        disabledForegroundColor: OlympicColors.gray500,
      ),
      child: Text('start_race'.tr().toUpperCase()),
    );
  }

  void _startCountdown() {
    ref.read(raceProvider.notifier).startCountdown();
  }
}
