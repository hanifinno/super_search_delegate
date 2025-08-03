import 'package:flutter/material.dart';
import 'search_config.dart';

class SuperSearchResults<T> extends StatelessWidget {
  final List<T> results;
  final String query;
  final ItemBuilder<T> itemBuilder;
  final Widget? noResultsWidget;
  final OnItemSelected<T>? onItemSelected;

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

class SuperSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;
  final String searchFieldLabel;

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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
