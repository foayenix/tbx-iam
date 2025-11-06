import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:i_am/presentation/screens/play_screen.dart';

void main() {
  testWidgets('PlayScreen shows timer and riddle', (WidgetTester tester) async {
    // Build the PlayScreen wrapped in necessary providers
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PlayScreen(),
        ),
      ),
    );

    // Wait for the widget to settle
    await tester.pumpAndSettle();

    // Verify timer is displayed (looking for any number)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Verify answer input field exists
    expect(find.byType(TextField), findsOneWidget);

    // Verify submit button exists
    expect(find.text('SUBMIT'), findsOneWidget);

    // Verify score display
    expect(find.textContaining('Score:'), findsOneWidget);
    expect(find.textContaining('Streak:'), findsOneWidget);
  });

  testWidgets('PlayScreen allows text input', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PlayScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the text field
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    // Enter text
    await tester.enterText(textField, 'circle');
    await tester.pump();

    // Verify text was entered
    expect(find.text('circle'), findsOneWidget);
  });

  testWidgets('PlayScreen submit button is tappable', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PlayScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find and tap submit button
    final submitButton = find.text('SUBMIT');
    expect(submitButton, findsOneWidget);

    await tester.tap(submitButton);
    await tester.pump();

    // Test passed if no exception thrown
  });
}
