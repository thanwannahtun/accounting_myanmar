import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/article_model.dart';
import 'article_repository_interface.dart';

class ArticleRepositoryImpl implements ArticleRepositoryInterface {
  static const String _indexAssetPath = 'assets/articles/articles_index.json';

  List<ArticleModel>? _cachedArticles;
  final Map<String, String> _cachedContents = {};

  @override
  Future<List<ArticleModel>> getArticles() async {
    if (_cachedArticles != null) {
      return _cachedArticles!;
    }

    try {
      final jsonString = await rootBundle.loadString(_indexAssetPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      final articles = jsonList
          .map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
          .toList();
      articles.sort((a, b) => a.order.compareTo(b.order));
      _cachedArticles = articles;
      return articles;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<String> getArticleContent(String filePath) async {
    if (_cachedContents.containsKey(filePath)) {
      return _cachedContents[filePath]!;
    }

    try {
      final content = await rootBundle.loadString(filePath);
      _cachedContents[filePath] = content;
      return content;
    } catch (e) {
      return '# Error Loading Article\n\nဆောင်းပါး ဖတ်ရှုရာတွင် ချို့ယွင်းချက် ဖြစ်ပေါ်နေပါသည်။ ဖိုင်တည်နေရာ: $filePath';
    }
  }

  @override
  Future<ArticleModel?> getArticleById(String id) async {
    final articles = await getArticles();
    try {
      return articles.firstWhere((article) => article.id == id);
    } catch (_) {
      return null;
    }
  }
}
