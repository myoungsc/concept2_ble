import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/ble_device_state.dart';
import '../models/participant.dart';
import '../theme/app_theme.dart';

class RaceLaneWidget extends StatelessWidget {
  final Participant participant;
  final int rank;
  final int targetDistance;
  final Color laneColor;

  const RaceLaneWidget({
    super.key,
    required this.participant,
    required this.rank,
    required this.targetDistance,
    required this.laneColor,
  });

  bool get _isDisconnected =>
      participant.connectionState == BleConnectionState.reconnecting ||
      participant.connectionState == BleConnectionState.failed ||
      participant.connectionState == BleConnectionState.disconnected;

  @override
  Widget build(BuildContext context) {
    final progress = targetDistance > 0
        ? (participant.currentDistance / targetDistance).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: OlympicColors.bgCard,
        borderRadius: BorderRadius.circular(6),
        border: rank == 1
            ? Border.all(color: OlympicColors.goldMedal, width: 2)
            : null,
        boxShadow: rank == 1
            ? [
                BoxShadow(
                  color: OlympicColors.goldMedal.withValues(alpha: 0.15),
                  blurRadius: 20,
                )
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(
            width: 6,
            color: _isDisconnected && !participant.isFinished
                ? OlympicColors.redOlympic
                : participant.isFinished
                    ? OlympicColors.statusFinished
                    : laneColor,
          ),
          _buildRank(),
          _buildParticipantInfo(),
          Expanded(child: _buildTrack(progress)),
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildRank() {
    final color = AppTheme.rankColor(rank);
    return SizedBox(
      width: 56,
      child: Center(
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$rank',
                style: OlympicTextStyles.bigNumber(
                  fontSize: 36,
                  color: color,
                ).copyWith(
                  shadows: rank == 1
                      ? [
                          Shadow(
                            color: OlympicColors.goldMedal
                                .withValues(alpha: 0.4),
                            blurRadius: 20,
                          )
                        ]
                      : null,
                ),
              ),
              TextSpan(
                text: AppTheme.rankSuffix(rank),
                style: OlympicTextStyles.label(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantInfo() {
    final isFinished = participant.isFinished;
    final disconnected = _isDisconnected && !isFinished;

    return SizedBox(
      width: 155,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    participant.name.toUpperCase(),
                    style: OlympicTextStyles.participantName(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (disconnected) ...[
                  const SizedBox(width: 4),
                  _BleWarningBadge(),
                ],
              ],
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: disconnected
                        ? OlympicColors.redOlympic
                        : isFinished
                            ? OlympicColors.statusFinished
                            : OlympicColors.statusRowing,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  disconnected
                      ? 'ble_reconnecting'.tr().toUpperCase()
                      : isFinished
                          ? 'status_finished'.tr().toUpperCase()
                          : 'status_rowing'.tr().toUpperCase(),
                  style: OlympicTextStyles.label(
                    fontSize: 10,
                    color: disconnected
                        ? OlympicColors.redOlympic
                        : isFinished
                            ? OlympicColors.statusFinishedLight
                            : OlympicColors.statusRowingLight,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrack(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            height: 28,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Row(
                  children: List.generate(
                    10,
                    (i) => Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: i < 9
                              ? Border(
                                  right: BorderSide(
                                    color: Colors.white
                                        .withValues(alpha: 0.04),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 500),
                  curve: Cubic(0.16, 1, 0.3, 1),
                  widthFactor: progress,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.trackBarGradient(laneColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: OlympicColors.white,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: OlympicColors.white
                                    .withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatChip(
            label: 'stat_dist'.tr().toUpperCase(),
            value: participant.currentDistance.toStringAsFixed(0),
            unit: 'm',
            large: true,
          ),
          const SizedBox(width: 2),
          _StatChip(
            label: 'stat_spm'.tr().toUpperCase(),
            value: '${participant.latestData?.strokeRate ?? 0}',
          ),
          const SizedBox(width: 2),
          _StatChip(
            label: 'stat_watts'.tr().toUpperCase(),
            value: '${participant.latestData?.watts ?? 0}',
          ),
          const SizedBox(width: 2),
          _StatChip(
            label: 'stat_time'.tr().toUpperCase(),
            value: participant.latestData?.formattedElapsedTime ?? '0:00.0',
            muted: true,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final bool large;
  final bool muted;

  const _StatChip({
    required this.label,
    required this.value,
    this.unit,
    this.large = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      constraints: const BoxConstraints(minWidth: 72),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: OlympicTextStyles.label(
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: OlympicTextStyles.mono(
                    fontSize: large ? 20 : 17,
                    color: muted ? OlympicColors.gray500 : OlympicColors.white,
                  ),
                ),
                if (unit != null)
                  TextSpan(
                    text: unit,
                    style: OlympicTextStyles.mono(
                      fontSize: 10,
                      color: OlympicColors.gray500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BleWarningBadge extends StatefulWidget {
  @override
  State<_BleWarningBadge> createState() => _BleWarningBadgeState();
}

class _BleWarningBadgeState extends State<_BleWarningBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Icon(
        Icons.bluetooth_disabled,
        color: OlympicColors.redOlympic,
        size: 14,
      ),
    );
  }
}
