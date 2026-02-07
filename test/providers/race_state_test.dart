import 'package:flutter_test/flutter_test.dart';
import 'package:concept2_ble/models/participant.dart';
import 'package:concept2_ble/models/race_config.dart';
import 'package:concept2_ble/models/rowing_data.dart';
import 'package:concept2_ble/providers/race_provider.dart';

void main() {
  group('RaceState', () {
    test('기본 상태가 올바르다', () {
      const state = RaceState();

      expect(state.phase, RacePhase.setup);
      expect(state.participants, isEmpty);
      expect(state.raceStartTime, isNull);
      expect(state.config.targetDistanceMeters, 2000);
    });

    test('allFinished는 참가자가 없으면 false이다', () {
      const state = RaceState();
      expect(state.allFinished, isFalse);
    });

    test('allFinished는 모든 참가자가 완주하면 true이다', () {
      final state = RaceState(
        participants: [
          const Participant(
            id: '1',
            name: '참가자1',
            laneNumber: 1,
            isFinished: true,
            finishTime: Duration(minutes: 7),
          ),
          const Participant(
            id: '2',
            name: '참가자2',
            laneNumber: 2,
            isFinished: true,
            finishTime: Duration(minutes: 8),
          ),
        ],
      );

      expect(state.allFinished, isTrue);
    });

    test('allFinished는 한 명이라도 미완주이면 false이다', () {
      final state = RaceState(
        participants: [
          const Participant(
            id: '1',
            name: '참가자1',
            laneNumber: 1,
            isFinished: true,
          ),
          const Participant(
            id: '2',
            name: '참가자2',
            laneNumber: 2,
            isFinished: false,
          ),
        ],
      );

      expect(state.allFinished, isFalse);
    });

    test('sortedByDistance는 거리 내림차순으로 정렬한다', () {
      final state = RaceState(
        participants: [
          Participant(
            id: '1',
            name: '참가자1',
            laneNumber: 1,
            latestData: RowingData(
              distanceMeters: 100,
              timestamp: DateTime.now(),
            ),
          ),
          Participant(
            id: '2',
            name: '참가자2',
            laneNumber: 2,
            latestData: RowingData(
              distanceMeters: 300,
              timestamp: DateTime.now(),
            ),
          ),
          Participant(
            id: '3',
            name: '참가자3',
            laneNumber: 3,
            latestData: RowingData(
              distanceMeters: 200,
              timestamp: DateTime.now(),
            ),
          ),
        ],
      );

      final sorted = state.sortedByDistance;
      expect(sorted[0].name, '참가자2'); // 300m
      expect(sorted[1].name, '참가자3'); // 200m
      expect(sorted[2].name, '참가자1'); // 100m
    });

    test('sortedByFinish는 완주자를 시간순으로, 미완주자를 거리순으로 정렬한다', () {
      final state = RaceState(
        participants: [
          Participant(
            id: '1',
            name: '참가자1',
            laneNumber: 1,
            isFinished: true,
            finishTime: const Duration(minutes: 8),
            latestData: RowingData(
              distanceMeters: 2000,
              timestamp: DateTime.now(),
            ),
          ),
          Participant(
            id: '2',
            name: '참가자2',
            laneNumber: 2,
            isFinished: false,
            latestData: RowingData(
              distanceMeters: 1500,
              timestamp: DateTime.now(),
            ),
          ),
          Participant(
            id: '3',
            name: '참가자3',
            laneNumber: 3,
            isFinished: true,
            finishTime: const Duration(minutes: 7),
            latestData: RowingData(
              distanceMeters: 2000,
              timestamp: DateTime.now(),
            ),
          ),
        ],
      );

      final sorted = state.sortedByFinish;
      expect(sorted[0].name, '참가자3'); // 1st: 7분 완주
      expect(sorted[1].name, '참가자1'); // 2nd: 8분 완주
      expect(sorted[2].name, '참가자2'); // 3rd: 미완주
    });

    test('copyWith가 올바르게 작동한다', () {
      const state = RaceState();
      final updated = state.copyWith(
        phase: RacePhase.racing,
        config: const RaceConfig(targetDistanceMeters: 500),
      );

      expect(updated.phase, RacePhase.racing);
      expect(updated.config.targetDistanceMeters, 500);
      expect(updated.participants, isEmpty); // 변경하지 않은 필드 유지
    });
  });

  group('Participant', () {
    test('currentDistance는 latestData가 없으면 0이다', () {
      const p = Participant(id: '1', name: 'Test', laneNumber: 1);
      expect(p.currentDistance, 0);
    });

    test('currentDistance는 latestData의 거리를 반환한다', () {
      final p = Participant(
        id: '1',
        name: 'Test',
        laneNumber: 1,
        latestData: RowingData(
          distanceMeters: 1234.5,
          timestamp: DateTime.now(),
        ),
      );
      expect(p.currentDistance, 1234.5);
    });
  });
}
