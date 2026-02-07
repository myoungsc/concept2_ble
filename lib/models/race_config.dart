enum RacePhase {
  setup,
  connecting,
  ready,
  racing,
  finished,
}

class RaceConfig {
  final int targetDistanceMeters;

  const RaceConfig({
    this.targetDistanceMeters = 2000,
  });

  static const List<int> presetDistances = [200, 500, 1000, 2000];
  static const int minDistance = 100;
  static const int maxDistance = 10000;

  RaceConfig copyWith({int? targetDistanceMeters}) {
    return RaceConfig(
      targetDistanceMeters: targetDistanceMeters ?? this.targetDistanceMeters,
    );
  }
}
