// Widget test for CounterPage — pumps the PAGE directly (it creates its own
// Bloc via BlocProvider, so no get_it init, no router, no network needed).
// Run: flutter test
import 'package:bloc_clean_arc_learn/features/counter/presentation/pages/counter_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter page increments and decrements', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CounterPage()));

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byTooltip('Increment'));
    await tester.pump(); // BlocBuilder rebuilds on emitted state
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byTooltip('Decrement'));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
  });
}
