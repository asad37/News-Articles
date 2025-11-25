import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BookmarksScreen extends StatefulWidget {
  final Set<String> bookmarks;
  BookmarksScreen({required this.bookmarks});

  @override
  _BookmarksScreenState createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<dynamic> bookmarkedArticles = [];
  List<dynamic> filteredBookmarks = [];
  bool loading = false;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBookmarkedArticles();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchBookmarkedArticles() async {
    setState(() => loading = true);
    List<dynamic> allArticles = [];
    for (var category in [
      'business',
      'entertainment',
      'general',
      'health',
      'science',
      'sports',
      'technology',
    ]) {
      try {
        final response = await http.get(
          Uri.parse(
            'https://newsapi.org/v2/top-headlines?category=$category&apiKey=96ae59074c6a480594ffad62fc8b4441&pageSize=50',
          ),
        );
        if (response.statusCode == 200) {
          allArticles.addAll(json.decode(response.body)['articles']);
        }
      } catch (e) {}
    }
    setState(() {
      bookmarkedArticles = allArticles
          .where((a) => widget.bookmarks.contains(a['url']))
          .toList();
      filteredBookmarks = bookmarkedArticles;
      loading = false;
    });
  }

  void filterBookmarks(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredBookmarks = bookmarkedArticles;
      } else {
        filteredBookmarks = bookmarkedArticles.where((article) {
          final title = (article['title'] ?? '').toLowerCase();
          final description = (article['description'] ?? '').toLowerCase();
          return title.contains(query.toLowerCase()) ||
              description.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Bookmarkes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          filterBookmarks('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: filterBookmarks,
            ),
          ),
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator())
                : filteredBookmarks.isEmpty
                ? Center(
                    child: Text(
                      searchQuery.isEmpty
                          ? 'No bookmarks yet'
                          : 'No bookmarks found',
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredBookmarks.length,
                    itemBuilder: (ctx, i) {
                      final article = filteredBookmarks[i];
                      return Card(
                        margin: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (article['urlToImage'] != null)
                              Image.network(
                                article['urlToImage'],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                ),
                              ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article['title'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    article['publishedAt'] != null
                                        ? DateFormat('MMM dd, yyyy').format(
                                            DateTime.parse(
                                              article['publishedAt'],
                                            ),
                                          )
                                        : '',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
