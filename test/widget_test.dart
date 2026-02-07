import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:concept2_ble/main.dart';

void main() {
  testWidgets('App launches with distance setup screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: Concept2RaceApp()),
    );

    expect(find.text('목표 거리 설정'), findsOneWidget);
    expect(find.text('레이스 거리를 선택하세요'), findsOneWidget);
  });
}
