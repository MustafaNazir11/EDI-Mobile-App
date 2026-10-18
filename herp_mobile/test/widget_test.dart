import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herp_mobile/main.dart';

void main() {
  testWidgets('Citizen home displays sections and report feedback', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Hello, Citizen'), findsOneWidget);
    expect(find.text('Emergency Services'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('Recent Incidents'), findsOneWidget);
    expect(find.text('Medical assistance'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report Emergency'));
    await tester.pump();

    expect(
      find.text('Incident reporting will be available in the next step.'),
      findsOneWidget,
    );
  });
}
