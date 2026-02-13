import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ble_device_state.dart';
import '../models/participant.dart';
import '../models/race_config.dart';
import 'ble_provider.dart';

class RaceState {
  final RaceConfig config;
  final RacePhase phase;
  final List<Participant> participants;
  final DateTime? raceStartTime;
  final Duration elapsed;

  const RaceState({
    this.config = const RaceConfig(),
    this.phase = RacePhase.setup,
    this.participants = const [],
    this.raceStartTime,
    this.elapsed = Duration.zero,
  });

  bool get allFinished =>
      participants.isNotEmpty && participants.every((p) => p.isFinished);

  bool get allDevicesAtZero =>
      participants.isNotEmpty &&
      participants.every(
          (p) => p.latestData != null && p.currentDistance <= 0);

  List<Participant> get sortedByDistance {
    final sorted = List<Participant>.from(participants);
    sorted.sort((a, b) => b.currentDistance.compareTo(a.currentDistance));
    return sorted;
  }

  List<Participant> get sortedByFinish {
    final sorted = List<Participant>.from(participants);
    sorted.sort((a, b) {
      if (a.isFinished && b.isFinished) {
        return (a.finishTime ?? Duration.zero)
            .compareTo(b.finishTime ?? Duration.zero);
      }
      if (a.isFinished) return -1;
      if (b.isFinished) return 1;
      return b.currentDistance.compareTo(a.currentDistance);
    });
    return sorted;
  }

  RaceState copyWith({
    RaceConfig? config,
    RacePhase? phase,
    List<Participant>? participants,
    DateTime? raceStartTime,
    Duration? elapsed,
  }) {
    return RaceState(
      config: config ?? this.config,
      phase: phase ?? this.phase,
      participants: participants ?? this.participants,
      raceStartTime: raceStartTime ?? this.raceStartTime,
      elapsed: elapsed ?? this.elapsed,
    );
  }
}

class RaceNotifier extends StateNotifier<RaceState> {
  final Ref _ref;
  StreamSubscription? _dataSubscription;
  StreamSubscription? _connectionSubscription;
  Timer? _elapsedTimer;

  RaceNotifier(this._ref) : super(const RaceState()) {
    _listenToConnectionState();
    _listenToRowingData();
  }

  void _listenToConnectionState() {
    _connectionSubscription =
        _ref.read(bleServiceProvider).connectionStateStream.listen((entry) {
      final deviceId = entry.key;
      final connState = entry.value;

      final participants = state.participants.map((p) {
        if (p.device?.remoteId.str == deviceId) {
          return p.copyWith(connectionState: connState);
        }
        return p;
      }).toList();

      state = state.copyWith(participants: participants);
    });
  }

  void _listenToRowingData() {
    _dataSubscription =
        _ref.read(bleServiceProvider).rowingDataStream.listen((entry) {
      final deviceId = entry.key;
      final data = entry.value;

      if (state.phase != RacePhase.warmup &&
          state.phase != RacePhase.countdown &&
          state.phase != RacePhase.racing) {
        return;
      }

      final participants = state.participants.map((p) {
        if (p.device?.remoteId.str == deviceId) {
          if (state.phase == RacePhase.racing) {
            final justFinished = !p.isFinished &&
                data.distanceMeters >= state.config.targetDistanceMeters;
            return p.copyWith(
              latestData: data,
              isFinished: justFinished || p.isFinished,
              finishTime: (justFinished && !p.isFinished)
                  ? DateTime.now().difference(state.raceStartTime!)
                  : p.finishTime,
              machineFinishTime: (justFinished && !p.isFinished)
                  ? data.elapsedTime
                  : p.machineFinishTime,
            );
          }
          return p.copyWith(latestData: data);
        }
        return p;
      }).toList();

      state = state.copyWith(participants: participants);

      if (state.allFinished && state.phase == RacePhase.racing) {
        state = state.copyWith(phase: RacePhase.finished);
        _elapsedTimer?.cancel();
        _ref.read(bleServiceProvider).setRaceMode(false);
      }
    });
  }

  void setTargetDistance(int meters) {
    state = state.copyWith(
      config: state.config.copyWith(targetDistanceMeters: meters),
    );
  }

  void addParticipant(String name, dynamic device) {
    final laneNumber = state.participants.length + 1;
    final participant = Participant(
      id: device.remoteId.str,
      name: name,
      laneNumber: laneNumber,
      device: device,
      connectionState: BleConnectionState.connected,
    );
    state = state.copyWith(
      participants: [...state.participants, participant],
    );
  }

  void updateParticipantName(String participantId, String name) {
    final participants = state.participants.map((p) {
      if (p.id == participantId) {
        return p.copyWith(name: name);
      }
      return p;
    }).toList();
    state = state.copyWith(participants: participants);
  }

  void removeParticipant(String participantId) {
    final participants =
        state.participants.where((p) => p.id != participantId).toList();
    final updated = participants.asMap().entries.map((entry) {
      return entry.value.copyWith(laneNumber: entry.key + 1);
    }).toList();
    state = state.copyWith(participants: updated);
  }

  void setPhase(RacePhase phase) {
    state = state.copyWith(phase: phase);
  }

  void startCountdown() {
    _ref.read(bleServiceProvider).setRaceMode(true);
    state = state.copyWith(phase: RacePhase.countdown);
  }

  void startRace() {
    final now = DateTime.now();
    state = state.copyWith(
      phase: RacePhase.racing,
      raceStartTime: now,
    );
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (state.phase == RacePhase.racing) {
        state = state.copyWith(
          elapsed: DateTime.now().difference(state.raceStartTime!),
        );
      }
    });
  }

  void resetRace() {
    _elapsedTimer?.cancel();
    _ref.read(bleServiceProvider).setRaceMode(false);
    state = const RaceState();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }
}

final raceProvider = StateNotifierProvider<RaceNotifier, RaceState>((ref) {
  return RaceNotifier(ref);
});
