import 'package:flutter_test/flutter_test.dart';

import 'package:do_or_not/main.dart';

void main() {
  testWidgets('App launches with title', (WidgetTester tester) async {
    await tester.pumpWidget(const DoOrNotApp());

    expect(find.text('DO OR NOT'), findsOneWidget);
    expect(find.text('去吧'), findsOneWidget);
  });
}
