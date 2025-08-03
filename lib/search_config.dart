import 'package:flutter/material.dart';

/// Signature for building the widget representation of each item in the list.
typedef ItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  String query,
);

/// Signature for selecting searchable string properties from an item.
/// For example: extracting `name` and `email` from a user model.
typedef PropertySelector<T> = List<String> Function(T item);

/// Signature for defining custom filtering logic for search.
typedef ItemFilter<T> = bool Function(T item, String query);

/// Signature for the callback when an item is selected.
typedef OnItemSelected<T> = void Function(T item);

/// A configuration class that defines how a searchable list behaves.
///
/// You can use this class to configure search behavior in a reusable and
/// generic way by passing the list of items, how to render each item, and
/// how to filter them using either a property selector or a custom filter.
///
/// Example usage:
/// ```dart
/// SearchConfig<User>(
///   items: userList,
///   itemBuilder: (context, user, query) => ListTile(title: Text(user.name)),
///   propertySelector: (user) => [user.name, user.email],
///   onItemSelected: (user) => print('Selected: ${user.name}'),
/// );
/// ```
class SearchConfig<T> {
  /// The full list of items to be searched.
  final List<T> items;

  /// A function that builds the UI widget for each item in the result list.
  final ItemBuilder<T> itemBuilder;

  /// A function that returns the list of string properties to be matched
  /// against the search query.
  ///
  /// This is mutually exclusive with [customFilter]. If both are provided,
  /// an assertion error will be thrown.
  final PropertySelector<T>? propertySelector;

  /// A custom function to define how each item should be filtered based
  /// on the search query.
  ///
  /// This allows for complex matching logic such as fuzzy search or tag matching.
  /// Cannot be used with [propertySelector].
  final ItemFilter<T>? customFilter;

  /// The label to display in the search input field.
  final String searchFieldLabel;

  /// A widget to show when there are no matching search results.
  final Widget? noResultsWidget;

  /// A callback function triggered when a user selects an item.
  final OnItemSelected<T>? onItemSelected;

  /// Creates a [SearchConfig] instance for customizing a searchable list.
  ///
  /// Throws an [AssertionError] if both [propertySelector] and [customFilter]
  /// are provided, as only one filtering strategy should be used at a time.
  SearchConfig({
    required this.items,
    required this.itemBuilder,
    this.propertySelector,
    this.customFilter,
    this.searchFieldLabel = 'Search...',
    this.noResultsWidget,
    this.onItemSelected,
  }) : assert(
          propertySelector == null || customFilter == null,
          'Cannot use both propertySelector and customFilter',
        );
}
