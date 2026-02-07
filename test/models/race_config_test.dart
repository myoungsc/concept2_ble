import 'package:flutter_test/flutter_test.dart';
import 'package:concept2_ble/models/race_config.dart';

void main() {
  group('RaceConfig', () {
    test('기본 목표 거리가 2000m이다', () {
      const config = RaceConfig();
      expect(config.targetDistanceMeters, 2000);
    });

    test('프리셋 거리 목록이 올바르다', () {
      expect(RaceConfig.presetDistances, [200, 500, 1000, 2000]);
    });

    test('최소/최대 거리 범위가 올바르다', () {
      expect(RaceConfig.minDistance, 100);
      expect(RaceConfig.maxDistance, 10000);
    });

    test('copyWith가 올바르게 작동한다', () {
      const config = RaceConfig(targetDistanceMeters: 500);
      final updated = config.copyWith(targetDistanceMeters: 1000);

      expect(updated.targetDistanceMeters, 1000);
    });
  });

  group('RacePhase', () {
    test('모든 레이스 단계가 정의되어 있다', () {
      expect(RacePhase.values.length, 5);
      expect(RacePhase.values, contains(RacePhase.setup));
      expect(RacePhase.values, contains(RacePhase.connecting));
      expect(RacePhase.values, contains(RacePhase.ready));
      expect(RacePhase.values, contains(RacePhase.racing));
      expect(RacePhase.values, contains(RacePhase.finished));
    });
  });
}
