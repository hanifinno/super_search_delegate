// super_search_delegate.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:super_search_delegate/search_config.dart';

class _ServerState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;

  _ServerState({
    required this.items,
    required this.isLoading,
    required this.hasMore,
  });

  _ServerState<T> copyWith({List<T>? items, bool? isLoading, bool? hasMore}) {
    return _ServerState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class SuperSearchDelegate<T> extends SearchDelegate<T?> {
  final SearchConfig<T> config;

  // Pagination & request tracking
  int _currentPage = 1;
  int _pageSize = 20;
  int _searchId =
      0; // increment on every new query (reset) to discard stale responses
  final List<T> _serverResults = [];
  final ValueNotifier<_ServerState<T>> _serverState =
      ValueNotifier<_ServerState<T>>(
    _ServerState<T>(items: const [], isLoading: false, hasMore: true),
  );

  // Local search notifier
  final ValueNotifier<List<T>> _localResultsNotifier = ValueNotifier<List<T>>(
    [],
  );

  // Scroll controller (used by the ListView)
  final ScrollController _scrollController = ScrollController();

  // Debounce
  Timer? _debounceTimer;

  // Last query seen
  String _lastQuery = '';

  SuperSearchDelegate(this.config)
      : super(
          searchFieldLabel: config.searchFieldLabel,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
        ) {
    _pageSize = config.pageSize;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _serverState.dispose();
    _localResultsNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // UI chrome
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
              // clear results immediately
              _serverResults.clear();
              _serverState.value = _serverState.value.copyWith(
                items: [],
                isLoading: false,
                hasMore: true,
              );
              _localResultsNotifier.value = [];
              showSuggestions(context);
            },
          ),
      ];

  @override
  Widget buildResults(BuildContext context) => _buildResults(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    // Async search path
    if (config.asyncSearch != null) {
      if (query.isEmpty) {
        // clear previous results and show prompt
        _serverResults.clear();
        _serverState.value = _serverState.value.copyWith(
          items: [],
          isLoading: false,
          hasMore: true,
        );
        return config.noResultsWidget ??
            const Center(child: Text('Start typing to search...'));
      }

      // If query changed, reset state and debounce a new search
      if (query != _lastQuery) {
        _lastQuery = query;
        _currentPage = 1;
        _hasMoreReset();
        _serverResults.clear();
        _serverState.value = _serverState.value.copyWith(
          items: [],
          isLoading: false,
          hasMore: true,
        );

        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          if (_lastQuery == query) {
            // start a fresh search (increment searchId so old responses are ignored)
            _searchId++;
            _loadMore(context, reset: true);
          }
        });
      }
    }
    // Local search path
    else {
      _filterLocalResults();
    }

    return _buildResults(context);
  }

  Widget _buildResults(BuildContext context) {
    if (config.asyncSearch != null) {
      return _buildServerSearch(context);
    } else {
      return _buildLocalSearch(context);
    }
  }

  Widget _buildServerSearch(BuildContext context) {
    // Use ValueListenableBuilder on the server state so UI updates instantly when notifier changes.
    return ValueListenableBuilder<_ServerState<T>>(
      valueListenable: _serverState,
      builder: (context, state, _) {
        final items = state.items;
        final isLoading = state.isLoading;
        final hasMore = state.hasMore;

        if (query.isEmpty) {
          return config.noResultsWidget ??
              const Center(child: Text('Start typing to search...'));
        }

        if (isLoading && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (items.isEmpty && !isLoading) {
          return config.noResultsWidget ??
              const Center(child: Text('No results found'));
        }

        // NotificationListener detects near-bottom scroll for pagination
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              final metrics = notification.metrics;
              if (metrics.pixels >= metrics.maxScrollExtent - 120 &&
                  !isLoading &&
                  hasMore) {
                _loadMore(context);
              }
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            itemCount: items.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == items.length) {
                // pagination loader
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              final item = items[index];
              return InkWell(
                onTap: () {
                  close(context, item);
                  config.onItemSelected?.call(item);
                },
                child: config.itemBuilder(context, item, query),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLocalSearch(BuildContext context) {
    // local results listenable
    return ValueListenableBuilder<List<T>>(
      valueListenable: _localResultsNotifier,
      builder: (context, localResults, _) {
        if (query.isEmpty) {
          return config.noResultsWidget ??
              const Center(child: Text('Start typing to search...'));
        }

        if (localResults.isEmpty) {
          return config.noResultsWidget ??
              const Center(child: Text('No results found'));
        }

        return ListView.builder(
          itemCount: localResults.length,
          itemBuilder: (context, index) {
            final item = localResults[index];
            return InkWell(
              onTap: () {
                close(context, item);
                config.onItemSelected?.call(item);
              },
              child: config.itemBuilder(context, item, query),
            );
          },
        );
      },
    );
  }

  void _filterLocalResults() {
    if (query.isEmpty) {
      _localResultsNotifier.value = [];
      return;
    }

    final normalizedQuery = query.toLowerCase();

    if (config.customFilter != null) {
      _localResultsNotifier.value = config.items
          .where((item) => config.customFilter!(item, normalizedQuery))
          .toList();
    } else {
      _localResultsNotifier.value = config.items.where((item) {
        final properties = config.propertySelector?.call(item) ??
            _getAllStringProperties(item);
        return properties.any(
          (prop) => prop.toLowerCase().contains(normalizedQuery),
        );
      }).toList();
    }
  }

  void _hasMoreReset() {
    // helper if you want to compute hasMore differently later
    // For now we just set true when resetting
  }

  Future<void> _loadMore(BuildContext context, {bool reset = false}) async {
    // allow reset to start even if we were loading previous request; otherwise ignore if already loading
    if (_serverState.value.isLoading && !reset) return;

    // if reset, increment searchId to mark previous requests stale
    if (reset) {
      _searchId++;
    }

    // capture which searchId this call belongs to
    final int callSearchId = _searchId;

    // set loading => true and notify
    _serverState.value = _serverState.value.copyWith(isLoading: true);

    if (reset) {
      _currentPage = 1;
      _serverResults.clear();
      _serverState.value = _serverState.value.copyWith(
        items: [],
        isLoading: true,
        hasMore: true,
      );
    }

    try {
      final newItems = await config.asyncSearch!(
        query,
        _currentPage,
        _pageSize,
      );

      // if a newer search started, drop this result
      if (callSearchId != _searchId) {
        return;
      }

      if (newItems.length < _pageSize) {
        _hasMoreFalse();
      } else {
        _hasMoreTrue();
      }

      _serverResults.addAll(newItems);
      // assign a new list reference so listeners are triggered
      _serverState.value = _serverState.value.copyWith(
        items: List<T>.unmodifiable(_serverResults),
        isLoading: false,
        hasMore: _serverState.value.hasMore,
      );

      _currentPage++;
    } catch (error, st) {
      debugPrint('Search load error: $error\n$st');
      // keep existing items but stop loading
      if (callSearchId == _searchId) {
        _serverState.value = _serverState.value.copyWith(isLoading: false);
      }
    } finally {
      // final safety: ensure loading flag cleared for current search id
      if (callSearchId == _searchId) {
        _serverState.value = _serverState.value.copyWith(isLoading: false);
      }
    }
  }

  void _hasMoreFalse() {
    _serverState.value = _serverState.value.copyWith(hasMore: false);
  }

  void _hasMoreTrue() {
    _serverState.value = _serverState.value.copyWith(hasMore: true);
  }

  List<String> _getAllStringProperties(T item) {
    if (item is Map) return item.values.whereType<String>().toList();
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
