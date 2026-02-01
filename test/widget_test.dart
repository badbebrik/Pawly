import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pawly/app/app.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PawlyApp()));
    await tester.pump();

    expect(find.text('Pawly'), findsOneWidget);
  });
}
