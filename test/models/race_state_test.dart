import 'package:flutter_test/flutter_test.dart';
import 'package:concept2_ble/models/participant.dart';
import 'package:concept2_ble/models/rowing_data.dart';
import 'package:concept2_ble/providers/race_provider.dart';

void main() {
  group('RaceState.allDevicesAtZero', () {
    test('참가자가 없으면 false를 반환한다', () {
      const state = RaceState();
      expect(state.allDevicesAtZero, isFalse);
    });

    test('latestData가 null인 참가자가 있으면 false를 반환한다', () {
      final state = RaceState(
        participants: [
          const Participant(id: 'a', name: 'A', laneNumber: 1),
        ],
      );
      expect(state.allDevicesAtZero, isFalse);
    });

    test('거리가 0보다 큰 참가자가 있으면 false를 반환한다', () {
      final state = RaceState(
        participants: [
          Participant(
            id: 'a',
            name: 'A',
            laneNumber: 1,
            latestData: RowingData(
              distanceMeters: 10.5,
              timestamp: DateTime.now(),
            ),
          ),
        ],
      );
      expect(state.allDevicesAtZero, isFalse);
    });

    test('모든 참가자가 0m이면 true를 반환한다', () {
      final state = RaceState(
        participants: [
          Participant(
            id: 'a',
            name: 'A',
            laneNumber: 1,
            latestData: RowingData(
              distanceMeters: 0,
              timestamp: DateTime.now(),
            ),
          ),
          Participant(
            id: 'b',
            name: 'B',
            laneNumber: 2,
            latestData: RowingData(
              distanceMeters: 0,
              timestamp: DateTime.now(),
            ),
          ),
        ],
      );
      expect(state.allDevicesAtZero, isTrue);
    });

    test('일부 참가자만 0m이면 false를 반환한다', () {
      final state = RaceState(
        participants: [
          Participant(
            id: 'a',
            name: 'A',
            laneNumber: 1,
            latestData: RowingData(
              distanceMeters: 0,
              timestamp: DateTime.now(),
            ),
          ),
          Participant(
            id: 'b',
            name: 'B',
            laneNumber: 2,
            latestData: RowingData(
              distanceMeters: 5.0,
              timestamp: DateTime.now(),
            ),
          ),
        ],
      );
      expect(state.allDevicesAtZero, isFalse);
    });
  });

  group('RaceState.allFinished', () {
    test('참가자가 없으면 false를 반환한다', () {
      const state = RaceState();
      expect(state.allFinished, isFalse);
    });

    test('모든 참가자가 완주하면 true를 반환한다', () {
      final state = RaceState(
        participants: [
          const Participant(
            id: 'a',
            name: 'A',
            laneNumber: 1,
            isFinished: true,
            finishTime: Duration(minutes: 1, seconds: 30),
          ),
          const Participant(
            id: 'b',
            name: 'B',
            laneNumber: 2,
            isFinished: true,
            finishTime: Duration(minutes: 1, seconds: 45),
          ),
        ],
      );
      expect(state.allFinished, isTrue);
    });
  });

  group('Participant.machineFinishTime', () {
    test('machineFinishTime은 별도로 저장된다', () {
      const p = Participant(
        id: 'a',
        name: 'A',
        laneNumber: 1,
        isFinished: true,
        finishTime: Duration(minutes: 1, seconds: 30),
        machineFinishTime: Duration(minutes: 1, seconds: 28),
      );
      expect(p.finishTime, const Duration(minutes: 1, seconds: 30));
      expect(p.machineFinishTime, const Duration(minutes: 1, seconds: 28));
      expect(p.finishTime != p.machineFinishTime, isTrue);
    });

    test('copyWith로 machineFinishTime을 설정할 수 있다', () {
      const p = Participant(id: 'a', name: 'A', laneNumber: 1);
      final updated = p.copyWith(
        machineFinishTime: const Duration(minutes: 2),
      );
      expect(updated.machineFinishTime, const Duration(minutes: 2));
    });
  });

  group('RaceState.sortedByFinish', () {
    test('완주 시간 기준으로 정렬된다', () {
      final state = RaceState(
        participants: [
          Participant(
            id: 'a',
            name: 'A',
            laneNumber: 1,
            isFinished: true,
            finishTime: const Duration(minutes: 2),
            latestData: RowingData(
              distanceMeters: 2000,
              timestamp: DateTime.now(),
            ),
          ),
          Participant(
            id: 'b',
            name: 'B',
            laneNumber: 2,
            isFinished: true,
            finishTime: const Duration(minutes: 1, seconds: 30),
            latestData: RowingData(
              distanceMeters: 2000,
              timestamp: DateTime.now(),
            ),
          ),
        ],
      );
      final sorted = state.sortedByFinish;
      expect(sorted[0].id, 'b');
      expect(sorted[1].id, 'a');
    });

    test('완주한 참가자가 미완주 참가자보다 앞에 온다', () {
      final state = RaceState(
        participants: [
          Participant(
            id: 'a',
            name: 'A',
            laneNumber: 1,
            isFinished: false,
            latestData: RowingData(
              distanceMeters: 1500,
              timestamp: DateTime.now(),
            ),
          ),
          Participant(
            id: 'b',
            name: 'B',
            laneNumber: 2,
            isFinished: true,
            finishTime: const Duration(minutes: 1, seconds: 30),
            latestData: RowingData(
              distanceMeters: 2000,
              timestamp: DateTime.now(),
            ),
          ),
        ],
      );
      final sorted = state.sortedByFinish;
      expect(sorted[0].id, 'b');
      expect(sorted[1].id, 'a');
    });
  });
}
