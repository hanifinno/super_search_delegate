import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_search_delegate/search_config.dart';
import 'package:super_search_delegate/super_search_delegate.dart';

void main() {
  group('SearchConfig', () {
    test('propertySelector and customFilter cannot both be provided', () {
      expect(
        () => SearchConfig<String>(
          items: const [],
          itemBuilder: (_, __, ___) => const SizedBox(),
          propertySelector: (_) => [],
          customFilter: (_, __) => true,
        ),
        throwsAssertionError,
      );
    });
  });

  group('Filtering', () {
    test('filters by property', () {
      final config = SearchConfig<User>(
        items: [
          User('Alice', 'alice@example.com'),
          User('Bob', 'bob@example.com'),
        ],
        propertySelector: (user) => [user.name, user.email],
        itemBuilder: (_, __, ___) => const SizedBox(),
      );

      final delegate = SuperSearchDelegate<User>(config);
      delegate.query = 'alice';
      final results = delegate.filterItems();

      expect(results.length, 1);
      expect(results[0].name, 'Alice');
    });
  });
}

class User {
  final String name;
  final String email;

  User(this.name, this.email);
}
