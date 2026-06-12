import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:do_or_not/main.dart';

void main() {
  testWidgets('App launches with title', (WidgetTester tester) async {
    await tester.pumpWidget(const DoOrNotApp());
    await tester.pump();

    expect(find.text('DO OR NOT'), findsOneWidget);
    expect(find.text('Go'), findsOneWidget);
  });

  test('Chinese locale strings are available', () {
    final l10n = lookupAppLocalizations(const Locale('zh'));
    expect(l10n.decideButton, '去吧');
    expect(l10n.homeTagline, '二选一，命运替你决定');
  });

  test('English locale strings are available', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(l10n.decideButton, 'Go');
    expect(l10n.homeTagline, 'Two choices—fate decides for you');
  });
}
