library super_search_delegate;

import 'package:flutter/material.dart';
import 'search_config.dart';
import 'search_widgets.dart';

/// A generic, highly customizable [SearchDelegate] for Flutter,
/// based on a [SearchConfig] object.
///
/// `SuperSearchDelegate` handles displaying suggestions and search results,
/// and allows filtering via property selectors or custom filtering logic.
///
/// This delegate can be used for searching any type of object, such as
/// users, products, or categories.
class SuperSearchDelegate<T> extends SearchDelegate<T?> {
  /// Configuration object that controls item list, builder, filter behavior, etc.
  final SearchConfig<T> config;

  /// Creates a [SuperSearchDelegate] using the provided [SearchConfig].
  ///
  /// Automatically sets the search field label and keyboard behavior.
  SuperSearchDelegate(this.config)
      : super(
          searchFieldLabel: config.searchFieldLabel,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
        );

  /// Builds the leading widget in the search app bar (typically a back button).
  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  /// Builds the action widgets in the search app bar (e.g., a clear button).
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

  /// Builds the main search results when a user submits a query.
  @override
  Widget buildResults(BuildContext context) => _buildResults(context);

  /// Builds suggestions dynamically as the user types.
  @override
  Widget buildSuggestions(BuildContext context) => _buildResults(context);

  /// Internal method to build search results using [SuperSearchResults].
  Widget _buildResults(BuildContext context) {
    final results = filterItems();
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

  /// Filters the list of items based on the current query.
  ///
  /// Priority is given to [customFilter] if provided.
  /// Otherwise, uses [propertySelector] or string representation of the item.
  List<T> filterItems() {
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

  /// Attempts to extract all string properties from the item.
  ///
  /// If the item is a `Map`, only `String` values are returned.
  /// Otherwise, falls back to `.toString()` and splits the result.
  List<String> _getAllStringProperties(T item) {
    if (item is Map) {
      return item.values.whereType<String>().toList();
    }

    return item.toString().split(' ').where((word) => word.isNotEmpty).toList();
  }

  /// Static helper method to easily launch the search delegate.
  ///
  /// Returns the selected item (or null if none was selected).
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
