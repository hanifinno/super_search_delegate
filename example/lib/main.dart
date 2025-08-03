import 'package:flutter/material.dart';
import 'package:super_search_delegate/search_config.dart';
import 'package:super_search_delegate/super_search_delegate.dart';

void main() {
  runApp(const MyApp());
}

/// A sample app demonstrating `SuperSearchDelegate` with a custom model.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Search with Model',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomePage(),
    );
  }
}

/// Simple key-value model class for search data.
class KeyValueItem {
  final String key;
  final String value;

  KeyValueItem({required this.key, required this.value});

  @override
  String toString() => '$key: $value';
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Sample data list
  static final List<KeyValueItem> data = [
    KeyValueItem(key: '001', value: 'Apple'),
    KeyValueItem(key: '002', value: 'Banana'),
    KeyValueItem(key: '003', value: 'Mango'),
    KeyValueItem(key: '004', value: 'Grapes'),
    KeyValueItem(key: '005', value: 'Orange'),
    KeyValueItem(key: '006', value: 'Pineapple'),
    KeyValueItem(key: '007', value: 'Watermelon'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Using Model'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              // Show search delegate
              final selected = await SuperSearchDelegate.show<KeyValueItem>(
                context: context,
                config: SearchConfig<KeyValueItem>(
                  items: data,
                  itemBuilder: (context, item, query) {
                    return ListTile(
                      title: Text(item.value),
                      subtitle: Text('ID: ${item.key}'),
                    );
                  },
                  // Fields to search on
                  propertySelector: (item) => [item.key, item.value],
                  onItemSelected: (item) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('You selected: ${item.value}')),
                    );
                  },
                ),
              );

              if (selected != null) {
                debugPrint(
                    'Selected item: ${selected.value} (${selected.key})');
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Tap the 🔍 icon to search by name or ID.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
