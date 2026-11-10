import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

void main() {
  testWidgets(
      'suggestions box lines up with the field when safe-area insets are uneven',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3;
    // Large inset on the right only, like a status bar along one side.
    tester.view.padding = const FakeViewPadding(right: 250);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TypeAheadField<String>(
              builder: (context, controller, focusNode) => TextField(
                key: const Key('field'),
                controller: controller,
                focusNode: focusNode,
              ),
              suggestionsCallback: (_) => ['Alice', 'Bob'],
              itemBuilder: (context, s) => ListTile(title: Text(s)),
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.byKey(const Key('field')));
    await tester.pumpAndSettle();

    final fieldRect = tester.getRect(find.byKey(const Key('field')));
    final listRect = tester.getRect(find.byType(ListView));
    expect(listRect.left, moreOrLessEquals(fieldRect.left, epsilon: 1));
    expect(listRect.right, moreOrLessEquals(fieldRect.right, epsilon: 1));
  });
}
