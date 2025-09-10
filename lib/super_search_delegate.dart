// super_search_delegate.dart
import 'package:flutter/material.dart';
import 'search_config.dart';
import 'search_widgets.dart';

class SuperSearchDelegate<T> extends SearchDelegate<T?> {
  final SearchConfig<T> config;

  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  List<T> _serverResults = [];

  // Tracks live query changes
  final ValueNotifier<String> _currentQuery = ValueNotifier('');

  SuperSearchDelegate(this.config)
      : super(
          searchFieldLabel: config.searchFieldLabel,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
        );

  /// 🔹 Override query setter to reset server results when query changes
  @override
  set query(String newQuery) {
    if (newQuery != super.query) {
      super.query = newQuery;

      if (config.asyncSearch != null) {
        _serverResults.clear();
        _currentPage = 1;
        _hasMore = true;
        _isLoading = false;

        // Update ValueNotifier triggers rebuild
        _currentQuery.value = newQuery;
      }
    }
  }

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              query = '';
              _serverResults.clear();
              _currentPage = 1;
              _hasMore = true;
              _isLoading = false;
              _currentQuery.value = ''; // triggers rebuild
            },
          ),
      ];

  @override
  Widget buildResults(BuildContext context) => _buildResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults(context);

  Widget _buildResults(BuildContext context) {
    if (config.asyncSearch != null) {
      return _buildServerSearch(context); // pass context
    } else {
      final results = filterItems();
      return SuperSearchResults<T>(
        results: results,
        query: query,
        itemBuilder: config.itemBuilder,
        noResultsWidget: config.noResultsWidget,
        onItemSelected: (item) {
          close(context, item); // ✅ context from the method
          config.onItemSelected?.call(item);
        },
      );
    }
  }

  /// 🔹 Server-side search with pagination & live query
  Widget _buildServerSearch(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _currentQuery,
      builder: (context, queryValue, _) {
        if (queryValue.isEmpty) {
          return config.noResultsWidget ??
              const Center(child: Text("Start typing to search..."));
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (_hasMore &&
                !_isLoading &&
                scrollInfo.metrics.pixels ==
                    scrollInfo.metrics.maxScrollExtent) {
              _loadMore();
            }
            return false;
          },
          child: FutureBuilder<List<T>>(
            // Always call _loadMore with reset=false so FutureBuilder rebuilds each time
            future: _loadMore(reset: false),
            builder: (context, snapshot) {
              if (_isLoading && _serverResults.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              if (_serverResults.isEmpty) {
                return config.noResultsWidget ??
                    const Center(child: Text("No results found"));
              }

              return ListView.builder(
                itemCount: _serverResults.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _serverResults.length) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ));
                  }

                  final item = _serverResults[index];
                  return InkWell(
                    onTap: () {
                      close(context, item);
                      config.onItemSelected?.call(item);
                    },
                    child: config.itemBuilder(context, item, queryValue),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  /// 🔹 Load more results (pagination)
  Future<List<T>> _loadMore({bool reset = false}) async {
    if (_isLoading) return _serverResults;

    _isLoading = true;
    if (reset) {
      _currentPage = 1;
      _serverResults.clear();
      _hasMore = true;
    }

    final newItems = await config.asyncSearch!(
      _currentQuery.value,
      _currentPage,
      config.pageSize,
    );

    if (newItems.length < config.pageSize) {
      _hasMore = false;
    }

    _serverResults.addAll(newItems);
    _currentPage++;
    _isLoading = false;

    // Force rebuild by updating the query notifier
    _currentQuery.notifyListeners();

    return _serverResults;
  }

  /// 🔹 Local filtering
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

  List<String> _getAllStringProperties(T item) {
    if (item is Map) {
      return item.values.whereType<String>().toList();
    }
    return item.toString().split(' ').where((word) => word.isNotEmpty).toList();
  }

  /// 🔹 Show delegate helper
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
