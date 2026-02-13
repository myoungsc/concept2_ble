import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';

import '../providers/race_provider.dart';
import '../services/screenshot_service.dart';
import '../theme/app_theme.dart';
import 'distance_setup_screen.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  final _screenshotController = ScreenshotController();
  bool _captured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureAndSave();
    });
  }

  Future<void> _captureAndSave() async {
    if (_captured) return;
    _captured = true;

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final permissionStatus =
          await ScreenshotService.checkAndRequestPermission();
      if (permissionStatus == PhotoPermissionStatus.denied) {
        if (mounted) _showPermissionDeniedDialog();
        return;
      }

      await ScreenshotService.captureAndSave(_screenshotController);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'saved_to_gallery'.tr(),
              style: OlympicTextStyles.body(),
            ),
            backgroundColor: OlympicColors.statusFinished,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'screenshot_failed'.tr(namedArgs: {'error': '$e'}),
              style: OlympicTextStyles.body(),
            ),
            backgroundColor: OlympicColors.redOlympic,
          ),
        );
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('photo_permission_title'.tr()),
        content: Text('photo_permission_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('close'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('go_to_settings'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final raceState = ref.watch(raceProvider);
    final sorted = raceState.sortedByFinish;

    return Scaffold(
      body: Screenshot(
        controller: _screenshotController,
        child: Container(
          color: OlympicColors.bgCharcoal,
          child: SafeArea(
            child: Column(
              children: [
                _buildBanner(raceState.config.targetDistanceMeters),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final p = sorted[index];
                      final rank = index + 1;
                      return _buildResultEntry(p, rank);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _goHome,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('home'.tr().toUpperCase()),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(int targetDistance) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  OlympicColors.goldMedal.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Column(
            children: [
              const Icon(Icons.emoji_events,
                  size: 44, color: OlympicColors.goldMedal),
              const SizedBox(height: 8),
              Text(
                'race_complete'.tr().toUpperCase(),
                style: OlympicTextStyles.headline(fontSize: 44),
              ),
              Text(
                'target_distance'.tr(namedArgs: {
                  'distance': '$targetDistance',
                }),
                style: OlympicTextStyles.body(
                  fontSize: 14,
                  color: OlympicColors.gray500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultEntry(dynamic p, int rank) {
    final isChampion = rank == 1;
    final rankColor = AppTheme.rankColor(rank);

    Color stripeColor;
    switch (rank) {
      case 1:
        stripeColor = OlympicColors.goldMedal;
        break;
      case 2:
        stripeColor = OlympicColors.silverMedal;
        break;
      case 3:
        stripeColor = OlympicColors.bronzeMedal;
        break;
      default:
        stripeColor = OlympicColors.gray700;
    }

    return Container(
      decoration: BoxDecoration(
        color: OlympicColors.bgCard,
        borderRadius: BorderRadius.circular(6),
        border: isChampion
            ? Border.all(color: OlympicColors.goldMedal, width: 2)
            : null,
        boxShadow: isChampion
            ? [
                BoxShadow(
                  color: OlympicColors.goldMedal.withValues(alpha: 0.1),
                  blurRadius: 20,
                )
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(width: 5, height: 60, color: stripeColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$rank${AppTheme.rankSuffix(rank)}',
                      style: OlympicTextStyles.bigNumber(
                        fontSize: 32,
                        color: rankColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      p.name.toUpperCase(),
                      style: OlympicTextStyles.participantName(fontSize: 22),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${p.currentDistance.toStringAsFixed(0)}m',
                        style: OlympicTextStyles.body(
                          fontSize: 13,
                          color: OlympicColors.gray500,
                        ),
                      ),
                      const SizedBox(width: 24),
                      if (p.latestData?.watts != null &&
                          p.latestData!.watts > 0)
                        Text(
                          '${p.latestData!.watts}W avg',
                          style: OlympicTextStyles.body(
                            fontSize: 13,
                            color: OlympicColors.gray500,
                          ),
                        ),
                      const SizedBox(width: 24),
                      Text(
                        _formatDuration(p.finishTime),
                        style: OlympicTextStyles.mono(
                          fontSize: 24,
                          color: isChampion
                              ? OlympicColors.goldMedal
                              : OlympicColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--.-';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final tenths = (duration.inMilliseconds % 1000) ~/ 100;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.$tenths';
  }

  void _goHome() {
    ref.read(raceProvider.notifier).resetRace();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DistanceSetupScreen()),
      (route) => false,
    );
  }
}
