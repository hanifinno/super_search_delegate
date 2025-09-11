// super_search_delegate_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_search_delegate/search_config.dart';
import 'package:super_search_delegate/super_search_delegate.dart';

void main() {
  group('SuperSearchDelegate', () {
    late List<String> items;

    setUp(() {
      items = ['Apple', 'Banana', 'Orange', 'Grapes', 'Mango'];
    });

    testWidgets('displays local search results correctly',
        (WidgetTester tester) async {
      final config = SearchConfig<String>(
        items: items,
        searchFieldLabel: 'Search fruits',
        itemBuilder: (context, item, query) => ListTile(title: Text(item)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                SuperSearchDelegate.show<String>(
                  context: context,
                  config: config,
                );
              },
              child: const Text('Open Search'),
            ),
          ),
        ),
      );

      // Open the search
      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      // Type a query
      await tester.enterText(find.byType(TextField), 'an');
      await tester.pumpAndSettle();

      // Check that only Banana and Orange are displayed
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Orange'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('calls onItemSelected when an item is tapped',
        (WidgetTester tester) async {
      String? selectedItem;
      final config = SearchConfig<String>(
        items: items,
        searchFieldLabel: 'Search fruits',
        itemBuilder: (context, item, query) => ListTile(title: Text(item)),
        onItemSelected: (item) => selectedItem = item,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                SuperSearchDelegate.show<String>(
                  context: context,
                  config: config,
                );
              },
              child: const Text('Open Search'),
            ),
          ),
        ),
      );

      // Open the search
      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      // Type a query
      await tester.enterText(find.byType(TextField), 'Mango');
      await tester.pumpAndSettle();

      // Tap on the result
      await tester.tap(find.text('Mango'));
      await tester.pumpAndSettle();

      expect(selectedItem, 'Mango');
    });

    testWidgets('shows no results widget for empty search',
        (WidgetTester tester) async {
      final config = SearchConfig<String>(
        items: items,
        searchFieldLabel: 'Search fruits',
        itemBuilder: (context, item, query) => ListTile(title: Text(item)),
        noResultsWidget: const Text('Nothing found!'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                SuperSearchDelegate.show<String>(
                  context: context,
                  config: config,
                );
              },
              child: const Text('Open Search'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      // Type a query that has no match
      await tester.enterText(find.byType(TextField), 'Pineapple');
      await tester.pumpAndSettle();

      expect(find.text('Nothing found!'), findsOneWidget);
    });
  });
}
