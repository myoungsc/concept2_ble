class RowingData {
  final double distanceMeters;
  final Duration elapsedTime;
  final int strokeRate;
  final int watts;
  final int heartRate;
  final double pace500m;
  final int strokeCount;
  final DateTime timestamp;

  const RowingData({
    this.distanceMeters = 0,
    this.elapsedTime = Duration.zero,
    this.strokeRate = 0,
    this.watts = 0,
    this.heartRate = 0,
    this.pace500m = 0,
    this.strokeCount = 0,
    required this.timestamp,
  });

  RowingData copyWith({
    double? distanceMeters,
    Duration? elapsedTime,
    int? strokeRate,
    int? watts,
    int? heartRate,
    double? pace500m,
    int? strokeCount,
    DateTime? timestamp,
  }) {
    return RowingData(
      distanceMeters: distanceMeters ?? this.distanceMeters,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      strokeRate: strokeRate ?? this.strokeRate,
      watts: watts ?? this.watts,
      heartRate: heartRate ?? this.heartRate,
      pace500m: pace500m ?? this.pace500m,
      strokeCount: strokeCount ?? this.strokeCount,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  String get formattedElapsedTime {
    final minutes = elapsedTime.inMinutes;
    final seconds = elapsedTime.inSeconds % 60;
    final tenths = (elapsedTime.inMilliseconds % 1000) ~/ 100;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.$tenths';
  }

  String get formattedPace {
    if (pace500m <= 0) return '-:--';
    final totalSeconds = pace500m.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
