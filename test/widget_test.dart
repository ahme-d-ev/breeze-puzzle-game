// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:block_puz_2026/main.dart';
import 'package:block_puz_2026/services/theme_manager.dart';

void main() {
  testWidgets('App starts and shows splash', (WidgetTester tester) async {
    final ThemeManager themeManager = ThemeManager();
    await tester.pumpWidget(MyApp(themeManager: themeManager));

    expect(find.text('BLOCK PUZZLE'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PLAY'), findsOneWidget);
  });
}
