import 'package:flutter/material.dart';

typedef ItemBuilder<T> = Widget Function(
    BuildContext context, T item, String query);
typedef PropertySelector<T> = List<String> Function(T item);
typedef ItemFilter<T> = bool Function(T item, String query);
typedef OnItemSelected<T> = void Function(T item);

class SearchConfig<T> {
  final List<T> items;
  final ItemBuilder<T> itemBuilder;
  final PropertySelector<T>? propertySelector;
  final ItemFilter<T>? customFilter;
  final String searchFieldLabel;
  final Widget? noResultsWidget;
  final OnItemSelected<T>? onItemSelected;

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
