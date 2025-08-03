import 'package:flutter/material.dart';
import 'search_config.dart';

/// A widget that displays a list of search results with optional tap handling.
///
/// If the [results] list is empty, it shows [noResultsWidget] or a default
/// message saying no results were found for the given [query].
///
/// This widget is used internally to render the filtered items.
class SuperSearchResults<T> extends StatelessWidget {
  /// The list of filtered items to display.
  final List<T> results;

  /// The current search query (used for highlighting or display purposes).
  final String query;

  /// A builder function to render each result item.
  final ItemBuilder<T> itemBuilder;

  /// A widget to show when there are no results.
  /// Defaults to a centered message.
  final Widget? noResultsWidget;

  /// Callback invoked when an item is selected (tapped).
  final OnItemSelected<T>? onItemSelected;

  /// Creates a [SuperSearchResults] widget.
  const SuperSearchResults({
    super.key,
    required this.results,
    required this.query,
    required this.itemBuilder,
    this.noResultsWidget,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return noResultsWidget ??
          Center(
            child: Text(
              'No results for "$query"',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return InkWell(
          onTap: () => onItemSelected?.call(item),
          child: itemBuilder(context, item, query),
        );
      },
    );
  }
}

/// A custom [AppBar] widget that displays a text field for entering search queries.
///
/// This is typically used at the top of a screen or scaffold when performing
/// full-screen search.
class SuperSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The controller attached to the search input field.
  final TextEditingController controller;

  /// Callback triggered when the text in the input field changes.
  final ValueChanged<String> onChanged;

  /// Callback triggered when the close (X) button is pressed.
  final VoidCallback onClose;

  /// The placeholder text shown inside the input field.
  final String searchFieldLabel;

  /// Creates a [SuperSearchAppBar] with a search field and close icon.
  const SuperSearchAppBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClose,
    this.searchFieldLabel = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: searchFieldLabel,
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ],
    );
  }

  /// Defines the size of the app bar — fixed at [kToolbarHeight].
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
