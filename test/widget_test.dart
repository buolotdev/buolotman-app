import 'package:flutter_test/flutter_test.dart';

import 'package:buolot_man_app/main.dart';

void main() {
  testWidgets('App compiles and runs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
