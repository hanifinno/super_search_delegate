import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:super_search_delegate/search_config.dart';
import 'package:super_search_delegate/super_search_delegate.dart';
import 'package:dio/dio.dart';

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

/// Sample model class for search data.
class PostModel {
  int? userId;
  int? id;
  String? title;
  String? body;

  PostModel({
    this.userId,
    this.id,
    this.title,
    this.body,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      userId: json['userId'],
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'id': id,
      'title': title,
      'body': body,
    };
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<PostModel> postList = [];

  @override
  void initState() {
    fetchData();
    super.initState();
  }

//Smaple Api Calling
  Future<void> fetchData() async {
    final dio = Dio();

    try {
      final response = await dio.get(
        'https://jsonplaceholder.typicode.com/posts',
        options: Options(
          headers: {
            'Authorization':
                'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImNtZDVodGFwZDAwMHd1eHBkZnIzYXB2cjAiLCJyb2xlIjoiYWRtaW4iLCJjb21wYW55X2lkIjoiY21kNWh0YWZ4MDAwZnV4cGRlYnFmd2R2cSIsImlhdCI6MTc1MzMyODU3NCwiZXhwIjoxNzUzNTg3Nzc0fQ.gtH4U-ey8YvigHFTSigTaliMz65nu2jvj4-2vyzTwXQ',
          },
        ),
      );

      if (response.statusCode == 200) {
        postList = (response.data as List)
            .map((item) => PostModel.fromJson(item))
            .toList();

        debugPrint('Data fetched: ${postList.length} posts');
      } else {
        debugPrint('Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch failed: $e');
    }
  }

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
              final selected = await SuperSearchDelegate.show<PostModel>(
                context: context,
                config: SearchConfig<PostModel>(
                  items: postList,
                  itemBuilder: (context, item, query) {
                    return ListTile(
                      title: Text(item.title ?? ''),
                      subtitle: Text('ID: ${item.body}'),
                    );
                  },
                  // Fields to search on
                  propertySelector: (item) =>
                      [item.id.toString(), item.title.toString()],
                  onItemSelected: (item) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('You selected: ${item.userId}')),
                    );
                  },
                ),
              );

              if (selected != null) {
                debugPrint(
                    'Selected item: ${selected.title} (${selected.userId})');
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
