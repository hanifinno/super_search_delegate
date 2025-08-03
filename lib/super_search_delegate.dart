library super_search_delegate;

import 'package:flutter/material.dart';
import 'search_config.dart';
import 'search_widgets.dart';

class SuperSearchDelegate<T> extends SearchDelegate<T?> {
  final SearchConfig<T> config;

  SuperSearchDelegate(this.config)
      : super(
          searchFieldLabel: config.searchFieldLabel,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
        );

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
      ];

  @override
  Widget buildResults(BuildContext context) => _buildResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults(context);

  Widget _buildResults(BuildContext context) {
    final results = _filterItems();
    return SuperSearchResults<T>(
      results: results,
      query: query,
      itemBuilder: config.itemBuilder,
      noResultsWidget: config.noResultsWidget,
      onItemSelected: (item) {
        close(context, item);
        config.onItemSelected?.call(item);
      },
    );
  }

  List<T> _filterItems() {
    if (query.isEmpty) return [];

    final normalizedQuery = query.toLowerCase();

    if (config.customFilter != null) {
      return config.items
          .where((item) => config.customFilter!(item, normalizedQuery))
          .toList();
    }

    return config.items.where((item) {
      final properties =
          config.propertySelector?.call(item) ?? _getAllStringProperties(item);

      return properties
          .any((prop) => prop.toLowerCase().contains(normalizedQuery));
    }).toList();
  }

  List<String> _getAllStringProperties(T item) {
    if (item is Map) {
      return item.values.whereType<String>().toList();
    }

    return item.toString().split(' ').where((word) => word.isNotEmpty).toList();
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required SearchConfig<T> config,
  }) async {
    return showSearch<T?>(
      context: context,
      delegate: SuperSearchDelegate<T>(config),
    );
  }
}
