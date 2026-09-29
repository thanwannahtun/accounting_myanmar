import 'package:equatable/equatable.dart';
import '../../data/models/article_model.dart';

class ArticlesState extends Equatable {
  final List<ArticleModel> articles;
  final List<ArticleModel> filteredArticles;
  final bool isLoading;
  final String? errorMessage;
  final String selectedCategory;
  final String searchQuery;
  final String? selectedAudience;
  final List<String> categories;
  final List<String> audiences;

  const ArticlesState({
    this.articles = const [],
    this.filteredArticles = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.selectedAudience,
    this.categories = const ['All'],
    this.audiences = const [],
  });

  ArticlesState copyWith({
    List<ArticleModel>? articles,
    List<ArticleModel>? filteredArticles,
    bool? isLoading,
    String? errorMessage,
    String? selectedCategory,
    String? searchQuery,
    String? selectedAudience,
    bool clearAudience = false,
    List<String>? categories,
    List<String>? audiences,
  }) {
    return ArticlesState(
      articles: articles ?? this.articles,
      filteredArticles: filteredArticles ?? this.filteredArticles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedAudience:
          clearAudience ? null : (selectedAudience ?? this.selectedAudience),
      categories: categories ?? this.categories,
      audiences: audiences ?? this.audiences,
    );
  }

  @override
  List<Object?> get props => [
        articles,
        filteredArticles,
        isLoading,
        errorMessage,
        selectedCategory,
        searchQuery,
        selectedAudience,
        categories,
        audiences,
      ];
}
