import 'package:flutter_test/flutter_test.dart';
import 'package:concept2_ble/utils/concept2_constants.dart';

void main() {
  group('Concept2Constants', () {
    test('isPm5Device는 PM5 이름을 인식한다', () {
      expect(Concept2Constants.isPm5Device('PM5 12345'), isTrue);
      expect(Concept2Constants.isPm5Device('pm5 Row'), isTrue);
      expect(Concept2Constants.isPm5Device('Concept2 PM5'), isTrue);
    });

    test('isPm5Device는 관련없는 이름을 거부한다', () {
      expect(Concept2Constants.isPm5Device('Heart Rate Monitor'), isFalse);
      expect(Concept2Constants.isPm5Device('Unknown Device'), isFalse);
      expect(Concept2Constants.isPm5Device(''), isFalse);
    });

    test('재연결 정책 상수가 올바르다', () {
      expect(Concept2Constants.maxImmediateRetries, 3);
      expect(Concept2Constants.maxReconnectTimeSeconds, 60);
      expect(
        Concept2Constants.dataTimeoutDuration,
        const Duration(seconds: 3),
      );
    });
  });
}
