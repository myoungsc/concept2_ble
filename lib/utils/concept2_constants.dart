import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Concept2Constants {
  Concept2Constants._();

  static final Guid discoveryService =
      Guid('ce060000-43e5-11e4-916c-0800200c9a66');
  static final Guid informationService =
      Guid('ce060010-43e5-11e4-916c-0800200c9a66');
  static final Guid rowingService =
      Guid('ce060020-43e5-11e4-916c-0800200c9a66');
  static final Guid controlService =
      Guid('ce060030-43e5-11e4-916c-0800200c9a66');

  static final Guid generalStatusChar =
      Guid('ce060031-43e5-11e4-916c-0800200c9a66');
  static final Guid additionalStatus1Char =
      Guid('ce060032-43e5-11e4-916c-0800200c9a66');
  static final Guid additionalStatus2Char =
      Guid('ce060033-43e5-11e4-916c-0800200c9a66');
  static final Guid strokeDataChar =
      Guid('ce060035-43e5-11e4-916c-0800200c9a66');
  static final Guid additionalStrokeDataChar =
      Guid('ce060036-43e5-11e4-916c-0800200c9a66');
  static final Guid multiplexedChar =
      Guid('ce060080-43e5-11e4-916c-0800200c9a66');

  static const List<String> deviceNamePrefixes = [
    'PM5',
    'Concept2',
  ];

  static const int maxImmediateRetries = 3;
  static const int maxReconnectTimeSeconds = 60;
  static const Duration dataTimeoutDuration = Duration(seconds: 5);
  static const Duration raceDataTimeoutDuration = Duration(seconds: 8);

  static bool isPm5Device(String name) {
    return deviceNamePrefixes.any(
      (prefix) => name.toUpperCase().contains(prefix.toUpperCase()),
    );
  }
}
