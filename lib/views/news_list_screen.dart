import 'package:article_app/services/api_services.dart';
import 'package:article_app/views/book_mark_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsListScreen extends StatefulWidget {
  @override
  _NewsListScreenState createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final NewsApiService _apiService = NewsApiService();
  final TextEditingController searchController = TextEditingController();

  String selectedCategory = 'all';
  List<dynamic> articles = [];
  List<dynamic> filteredArticles = [];
  Set<String> bookmarks = {};
  bool loading = false;
  String searchQuery = '';

  final List<String> categories = ['all', ...NewsApiService.categories];

  @override
  void initState() {
    super.initState();
    loadBookmarks();
    fetchNews();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bookmarks = (prefs.getStringList('bookmarks') ?? []).toSet();
    });
  }

  Future<void> saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarks', bookmarks.toList());
  }

  Future<void> fetchNews() async {
    setState(() => loading = true);
    try {
      final fetchedArticles = await _apiService.fetchNews(selectedCategory);
      setState(() {
        articles = fetchedArticles;
        filteredArticles = articles;
        searchController.clear();
        searchQuery = '';
      });
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load news')));
    } finally {
      setState(() => loading = false);
    }
  }

  void filterArticles(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredArticles = articles;
      } else {
        filteredArticles = articles.where((article) {
          final title = (article['title'] ?? '').toLowerCase();
          final description = (article['description'] ?? '').toLowerCase();
          return title.contains(query.toLowerCase()) ||
              description.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void toggleBookmark(String url) {
    setState(() {
      if (bookmarks.contains(url)) {
        bookmarks.remove(url);
      } else {
        bookmarks.add(url);
      }
    });
    saveBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore World',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'latest News Updates',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.bookmark),
                if (bookmarks.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${bookmarks.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookmarksScreen(bookmarks: bookmarks),
                ),
              );
              loadBookmarks();
              setState(() {});
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryChips(),
            _buildArticlesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          fillColor: Colors.grey[200],
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(20),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(20),
          ),
          hintText: 'Search',
          prefixIcon: Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    filterArticles('');
                  },
                )
              : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: filterArticles,
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (ctx, i) => Padding(
          padding: EdgeInsets.all(8),
          child: ChoiceChip(
            label: Text(
              categories[i].toUpperCase(),
              style: TextStyle(
                fontWeight: selectedCategory == categories[i]
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            selected: selectedCategory == categories[i],
            onSelected: (_) {
              setState(() => selectedCategory = categories[i]);
              fetchNews();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildArticlesList() {
    return Expanded(
      child: loading
          ? Center(child: CircularProgressIndicator())
          : filteredArticles.isEmpty
          ? Center(
              child: Text(
                searchQuery.isEmpty
                    ? 'No articles available'
                    : 'No articles found',
              ),
            )
          : ListView.builder(
              itemCount: filteredArticles.length,
              itemBuilder: (ctx, i) => _buildArticleCard(filteredArticles[i]),
            ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    final url = article['url'] ?? '';

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
              errorBuilder: (_, __, ___) =>
                  Container(height: 200, color: Colors.grey[300]),
            ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      article['publishedAt'] != null
                          ? DateFormat('MMM dd, yyyy | hh:mm a').format(
                              DateTime.parse(article['publishedAt']).toLocal(),
                            )
                          : '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),

                    IconButton(
                      icon: Icon(
                        bookmarks.contains(url)
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: bookmarks.contains(url) ? Colors.blue : null,
                      ),
                      onPressed: () => toggleBookmark(url),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  article['title'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  article['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
