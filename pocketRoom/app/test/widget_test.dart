// Pocket Room 기본 스모크 테스트

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_room/app.dart';

void main() {
  testWidgets('앱이 정상 실행되는지 확인', (WidgetTester tester) async {
    await tester.pumpWidget(const PocketRoomApp());
    expect(find.text('Pocket Room'), findsOneWidget);
  });
}
