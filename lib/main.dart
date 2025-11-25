import 'package:article_app/views/news_list_screen.dart';
import 'package:flutter/material.dart';

void main() => runApp(NewsApp());

class NewsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.lightBlue),
      home: NewsListScreen(),
    );
  }
}
