import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsApiService {
  static const String _apiKey = '96ae59074c6a480594ffad62fc8b4441';
  static const String _baseUrl = 'https://newsapi.org/v2/top-headlines';

  static const List<String> categories = [
    'business',
    'entertainment',
    'general',
    'health',
    'science',
    'sports',
    'technology',
  ];

  /// Fetch news for a specific category
  Future<List<dynamic>> fetchNewsByCategory(
    String category, {
    int pageSize = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?category=$category&apiKey=$_apiKey&pageSize=$pageSize',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['articles'] ?? [];
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news for category $category: $e');
      rethrow;
    }
  }

  /// Fetch news from all categories
  Future<List<dynamic>> fetchAllNews({int pageSize = 20}) async {
    List<dynamic> allArticles = [];

    try {
      for (var category in categories) {
        final articles = await fetchNewsByCategory(
          category,
          pageSize: pageSize,
        );
        allArticles.addAll(articles);
      }
      return allArticles;
    } catch (e) {
      print('Error fetching all news: $e');
      rethrow;
    }
  }

  /// Fetch news based on category selection
  Future<List<dynamic>> fetchNews(String selectedCategory) async {
    if (selectedCategory == 'all') {
      return await fetchAllNews();
    } else {
      return await fetchNewsByCategory(selectedCategory);
    }
  }
}
