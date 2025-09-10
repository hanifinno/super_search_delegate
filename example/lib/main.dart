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

  /// Sample API (fetch all posts once, for local search demo)
  Future<void> fetchData() async {
    final dio = Dio();

    try {
      final response = await dio.get(
        'https://jsonplaceholder.typicode.com/posts',
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

  /// 🔹 Example of server-side paginated search
  Future<List<PostModel>> searchPostsFromServer(
      String query, int page, int pageSize) async {
    final dio = Dio();
    try {
      final response = await dio.get(
        'https://jsonplaceholder.typicode.com/posts',
        queryParameters: {
          "_page": page,
          "_limit": pageSize,
          "q":
              query, // (jsonplaceholder ignores this, but for real API it works)
        },
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => PostModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint("Server search error: $e");
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Using Model'),
        actions: [
          /// 🔹 Local Search (uses pre-fetched postList)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Local Search",
            onPressed: () async {
              final selected = await SuperSearchDelegate.show<PostModel>(
                context: context,
                config: SearchConfig<PostModel>(
                  items: postList,
                  itemBuilder: (context, item, query) {
                    return ListTile(
                      title: Text(item.title ?? ''),
                      subtitle: Text('Body: ${item.body}'),
                    );
                  },
                  propertySelector: (item) =>
                      [item.id.toString(), item.title.toString()],
                  onItemSelected: (item) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Local: ${item.title}')),
                    );
                  },
                ),
              );

              if (selected != null) {
                debugPrint('Selected (Local): ${selected.title}');
              }
            },
          ),

          /// 🔹 Server-side Paginated Search
          IconButton(
            icon: const Icon(Icons.cloud),
            tooltip: "Server Search",
            onPressed: () async {
              final selected = await SuperSearchDelegate.show<PostModel>(
                context: context,
                config: SearchConfig<PostModel>(
                  asyncSearch: searchPostsFromServer,
                  pageSize: 10,
                  itemBuilder: (context, item, query) {
                    return ListTile(
                      title: Text(item.title ?? ''),
                      subtitle: Text("User ID: ${item.userId}"),
                    );
                  },
                  onItemSelected: (item) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Server: ${item.title}')),
                    );
                  },
                  items: [],
                ),
              );

              if (selected != null) {
                debugPrint('Selected (Server): ${selected.title}');
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Tap 🔍 for Local Search\nTap ☁️ for Server Search (paginated)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
