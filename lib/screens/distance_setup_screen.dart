import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/race_config.dart';
import '../providers/race_provider.dart';
import '../theme/app_theme.dart';
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
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: DiagonalStripePainter())),
          Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        children: [
                          Text(
                            'select_distance'.tr().toUpperCase(),
                            style: OlympicTextStyles.headline(fontSize: 52),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'choose_target_subtitle'.tr().toUpperCase(),
                            style: OlympicTextStyles.label(fontSize: 16),
                          ),
                          const SizedBox(height: 36),
                          _buildWarningBox(),
                          const SizedBox(height: 28),
                          _buildPresetGrid(),
                          const SizedBox(height: 24),
                          _buildCustomInput(),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _selectedDistance != null
                                  ? _goNext
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                disabledBackgroundColor:
                                    OlympicColors.bgElevated,
                                disabledForegroundColor: OlympicColors.gray500,
                              ),
                              child: Text('next'.tr().toUpperCase()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(top: 14, right: 16, child: _buildLanguageSwitcher()),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitcher() {
    final localeLabels = {
      const Locale('ko'): '한국어',
      const Locale('en'): 'English',
      const Locale('ja'): '日本語',
      const Locale('es'): 'Español',
    };

    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language, color: OlympicColors.white, size: 24),
      color: OlympicColors.bgCard,
      onSelected: (locale) {
        context.setLocale(locale);
      },
      itemBuilder: (context) => localeLabels.entries
          .map(
            (entry) => PopupMenuItem<Locale>(
              value: entry.key,
              child: Text(
                entry.value,
                style: OlympicTextStyles.body(
                  fontSize: 14,
                  color: context.locale == entry.key
                      ? OlympicColors.redOlympic
                      : OlympicColors.white,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OlympicColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: OlympicColors.redOlympic.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: OlympicColors.redOlympic,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ble_warning'.tr(),
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

  Widget _buildPresetGrid() {
    return Row(
      children: RaceConfig.presetDistances.map((d) {
        final isSelected = !_isCustom && _selectedDistance == d;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDistance = d;
                  _isCustom = false;
                  _customController.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 30,
                ),
                decoration: BoxDecoration(
                  color: OlympicColors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? OlympicColors.redOlympic
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    if (isSelected)
                      Container(
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: OlympicColors.redOlympic,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    Text(
                      '$d',
                      style: OlympicTextStyles.headline(
                        fontSize: 48,
                        color: isSelected
                            ? OlympicColors.white
                            : OlympicColors.gray300,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'meters'.tr().toUpperCase(),
                      style: OlympicTextStyles.label(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'custom'.tr().toUpperCase(),
          style: OlympicTextStyles.label(fontSize: 13),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 200,
          child: TextField(
            controller: _customController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: OlympicTextStyles.mono(fontSize: 20),
            decoration: InputDecoration(
              hintText: '100 ~ 10000',
              suffixText: 'm',
              suffixStyle: OlympicTextStyles.mono(
                fontSize: 14,
                color: OlympicColors.gray500,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
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
    );
  }

  void _goNext() {
    if (_selectedDistance == null) return;
    ref.read(raceProvider.notifier).setTargetDistance(_selectedDistance!);
    ref.read(raceProvider.notifier).setPhase(RacePhase.connecting);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DeviceConnectionScreen()));
  }
}
