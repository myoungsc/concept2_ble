import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/race_config.dart';
import '../providers/race_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/race_lane_widget.dart';
import 'result_screen.dart';

class RaceScreen extends ConsumerStatefulWidget {
  const RaceScreen({super.key});

  @override
  ConsumerState<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends ConsumerState<RaceScreen>
    with SingleTickerProviderStateMixin {
  bool _navigatedToResult = false;
  late AnimationController _liveController;

  @override
  void initState() {
    super.initState();
    _liveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _liveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final raceState = ref.watch(raceProvider);

    if (raceState.phase == RacePhase.finished && !_navigatedToResult) {
      _navigatedToResult = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ResultScreen()),
        );
      });
    }

    final sorted = raceState.sortedByDistance;
    final elapsed = raceState.elapsed;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: DiagonalStripePainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(raceState, elapsed, sorted),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final participant = sorted[index];
                      final originalIndex = raceState.participants
                          .indexWhere((p) => p.id == participant.id);
                      final color = AppTheme.laneColor(originalIndex);

                      return SizedBox(
                        height: _laneHeight(sorted.length, context),
                        child: RaceLaneWidget(
                          participant: participant,
                          rank: index + 1,
                          targetDistance:
                              raceState.config.targetDistanceMeters,
                          laneColor: color,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _laneHeight(int count, BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final available = screenH - 72 - MediaQuery.of(context).padding.top - 20;
    final h = (available - (count - 1) * 6) / count;
    return h.clamp(60.0, 120.0);
  }

  Widget _buildHeader(RaceState raceState, Duration elapsed,
      List<dynamic> sorted) {
    final finishedCount =
        sorted.where((p) => p.isFinished).length;

    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipPath(
            clipper: AngleRightClipper(angle: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              color: OlympicColors.redOlympic,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CONCEPT2',
                    style: OlympicTextStyles.bigNumber(fontSize: 32),
                  ),
                  Container(
                    width: 2,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  Text(
                    'race_display'.tr().toUpperCase(),
                    style: OlympicTextStyles.label(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ),
          ClipPath(
            clipper: ParallelogramClipper(angle: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              color: OlympicColors.blueOlympic,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'target'.tr().toUpperCase(),
                    style: OlympicTextStyles.label(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '${raceState.config.targetDistanceMeters}',
                          style: OlympicTextStyles.bigNumber(fontSize: 36),
                        ),
                        TextSpan(
                          text: 'M',
                          style: OlympicTextStyles.label(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLiveIndicator(),
                  const SizedBox(width: 16),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _formatTime(elapsed),
                          style: OlympicTextStyles.mono(fontSize: 48),
                        ),
                        TextSpan(
                          text: '.${_formatTenths(elapsed)}',
                          style: OlympicTextStyles.mono(
                            fontSize: 30,
                            color:
                                OlympicColors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipPath(
            clipper: AngleLeftClipper(angle: 20),
            child: Container(
              padding: const EdgeInsets.only(left: 40, right: 24),
              color: OlympicColors.bgCard,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏁', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$finishedCount / ${sorted.length}',
                        style: OlympicTextStyles.bigNumber(fontSize: 28),
                      ),
                      Text(
                        'finished'.tr().toUpperCase(),
                        style: OlympicTextStyles.label(
                          fontSize: 11,
                          letterSpacing: 2,
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

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: OlympicColors.redOlympic,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _liveController,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: OlympicColors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'live'.tr().toUpperCase(),
            style: OlympicTextStyles.label(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: OlympicColors.white,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTenths(Duration duration) {
    return '${(duration.inMilliseconds % 1000) ~/ 100}';
  }
}
