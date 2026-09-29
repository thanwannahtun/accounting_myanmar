import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/article_model.dart';
import '../../data/repositories/articles/article_repository_interface.dart';
import 'articles_state.dart';

class ArticlesCubit extends Cubit<ArticlesState> {
  final ArticleRepositoryInterface articleRepository;

  ArticlesCubit({required this.articleRepository}) : super(const ArticlesState());

  Future<void> loadArticles() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final articles = await articleRepository.getArticles();

      // Extract unique categories
      final Set<String> categorySet = {'All'};
      final Set<String> audienceSet = {};

      for (final a in articles) {
        if (a.category.isNotEmpty) {
          categorySet.add(a.category);
        }
        for (final aud in a.targetAudience) {
          audienceSet.add(aud);
        }
      }

      final filtered = _applyFilters(
        articles: articles,
        category: state.selectedCategory,
        query: state.searchQuery,
        audience: state.selectedAudience,
      );

      emit(state.copyWith(
        articles: articles,
        filteredArticles: filtered,
        categories: categorySet.toList(),
        audiences: audienceSet.toList(),
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'ဆောင်းပါးများ ရယူ၍ မရနိုင်ပါ။ (${e.toString()})',
      ));
    }
  }

  void search(String query) {
    final filtered = _applyFilters(
      articles: state.articles,
      category: state.selectedCategory,
      query: query,
      audience: state.selectedAudience,
    );
    emit(state.copyWith(
      searchQuery: query,
      filteredArticles: filtered,
    ));
  }

  void filterByCategory(String category) {
    final filtered = _applyFilters(
      articles: state.articles,
      category: category,
      query: state.searchQuery,
      audience: state.selectedAudience,
    );
    emit(state.copyWith(
      selectedCategory: category,
      filteredArticles: filtered,
    ));
  }

  void filterByAudience(String? audience) {
    final newAudience = (state.selectedAudience == audience) ? null : audience;
    final filtered = _applyFilters(
      articles: state.articles,
      category: state.selectedCategory,
      query: state.searchQuery,
      audience: newAudience,
      clearAudience: newAudience == null,
    );
    emit(state.copyWith(
      selectedAudience: newAudience,
      clearAudience: newAudience == null,
      filteredArticles: filtered,
    ));
  }

  void clearFilters() {
    emit(state.copyWith(
      selectedCategory: 'All',
      searchQuery: '',
      clearAudience: true,
      filteredArticles: state.articles,
    ));
  }

  List<ArticleModel> _applyFilters({
    required List<ArticleModel> articles,
    required String category,
    required String query,
    String? audience,
    bool clearAudience = false,
  }) {
    final effectiveAudience = clearAudience ? null : audience;
    final normalizedQuery = query.trim().toLowerCase();

    return articles.where((article) {
      // Category filter
      if (category != 'All' && article.category != category) {
        return false;
      }

      // Audience filter
      if (effectiveAudience != null &&
          !article.targetAudience.contains(effectiveAudience)) {
        return false;
      }

      // Query filter
      if (normalizedQuery.isNotEmpty) {
        final inMmTitle = article.titleMm.toLowerCase().contains(normalizedQuery);
        final inEnTitle = article.titleEn.toLowerCase().contains(normalizedQuery);
        final inSubtitle =
            article.subtitleMm.toLowerCase().contains(normalizedQuery);
        final inSummary =
            article.summaryMm.toLowerCase().contains(normalizedQuery);
        final inCategory =
            article.category.toLowerCase().contains(normalizedQuery);
        final inAudience = article.targetAudience.any(
            (aud) => aud.toLowerCase().contains(normalizedQuery));

        if (!inMmTitle &&
            !inEnTitle &&
            !inSubtitle &&
            !inSummary &&
            !inCategory &&
            !inAudience) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
