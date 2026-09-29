import '../../models/article_model.dart';

abstract class ArticleRepositoryInterface {
  Future<List<ArticleModel>> getArticles();
  Future<String> getArticleContent(String filePath);
  Future<ArticleModel?> getArticleById(String id);
}
