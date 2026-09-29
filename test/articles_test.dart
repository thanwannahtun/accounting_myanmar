import 'package:flutter_test/flutter_test.dart';
import 'package:accountingmyanmar/data/models/article_model.dart';
import 'package:accountingmyanmar/data/repositories/articles/article_repository_interface.dart';
import 'package:accountingmyanmar/logic/articles/articles_cubit.dart';

class FakeArticleRepository implements ArticleRepositoryInterface {
  final List<ArticleModel> _sampleArticles = [
    const ArticleModel(
      id: 'what_is_accounting',
      order: 1,
      titleMm: 'စာရင်းကိုင်ပညာဆိုတာဘာလဲ',
      titleEn: 'What is Accounting?',
      subtitleMm: 'အခြေခံသဘောတရားများ',
      category: 'Foundations (အခြေခံ)',
      targetAudience: ['Beginners', 'SMEs'],
      readTimeMinutes: 5,
      filePath: 'assets/articles/01_what_is_accounting.md',
      icon: 'school_outlined',
      summaryMm: 'စာရင်းကိုင်ပညာ၏ အဓိပ္ပာယ်နှင့် အခြေခံများ',
    ),
    const ArticleModel(
      id: 'debit_and_credit',
      order: 3,
      titleMm: 'Debit နှင့် Credit အမှန်တကယ် နားလည်ခြင်း',
      titleEn: 'Debit vs Credit',
      subtitleMm: 'DEALER စည်းမျဉ်း',
      category: 'Core Concepts (အဓိက သဘောတရား)',
      targetAudience: ['Beginners', 'Developers'],
      readTimeMinutes: 7,
      filePath: 'assets/articles/03_debit_and_credit.md',
      icon: 'balance_outlined',
      summaryMm: 'Debit နှင့် Credit စည်းမျဉ်းများ',
    ),
    const ArticleModel(
      id: 'accounting_for_developers',
      order: 10,
      titleMm: 'Developers များအတွက် စာရင်းကိုင် စနစ်တည်ဆောက်မှု',
      titleEn: 'Accounting for Software Developers',
      subtitleMm: 'Double-Entry Architecture',
      category: 'Software Architecture (နည်းပညာနှင့် စနစ်)',
      targetAudience: ['Developers'],
      readTimeMinutes: 8,
      filePath: 'assets/articles/10_accounting_for_developers.md',
      icon: 'code_outlined',
      summaryMm: 'Double-Entry database schema နှင့် Developer checklist',
    ),
  ];

  @override
  Future<List<ArticleModel>> getArticles() async {
    return _sampleArticles;
  }

  @override
  Future<String> getArticleContent(String filePath) async {
    return '# Sample Content for $filePath';
  }

  @override
  Future<ArticleModel?> getArticleById(String id) async {
    return _sampleArticles.firstWhere((a) => a.id == id);
  }
}

void main() {
  group('ArticleModel Tests', () {
    test('fromJson creates correct ArticleModel instance', () {
      final json = {
        'id': 'test_article',
        'order': 1,
        'titleMm': 'စမ်းသပ်ဆောင်းပါး',
        'titleEn': 'Test Article',
        'subtitleMm': 'စမ်းသပ်မှု',
        'category': 'Foundations',
        'targetAudience': ['Beginners', 'SMEs'],
        'readTimeMinutes': 5,
        'filePath': 'assets/articles/01_test.md',
        'icon': 'school_outlined',
        'summaryMm': 'စမ်းသပ်ချက် အနှစ်ချုပ်',
      };

      final article = ArticleModel.fromJson(json);

      expect(article.id, 'test_article');
      expect(article.order, 1);
      expect(article.titleMm, 'စမ်းသပ်ဆောင်းပါး');
      expect(article.titleEn, 'Test Article');
      expect(article.category, 'Foundations');
      expect(article.targetAudience, contains('Beginners'));
      expect(article.readTimeMinutes, 5);
      expect(article.icon, 'school_outlined');
    });
  });

  group('ArticlesCubit Tests', () {
    late FakeArticleRepository fakeRepository;
    late ArticlesCubit articlesCubit;

    setUp(() {
      fakeRepository = FakeArticleRepository();
      articlesCubit = ArticlesCubit(articleRepository: fakeRepository);
    });

    tearDown(() {
      articlesCubit.close();
    });

    test('Initial state has empty articles and is not loading', () {
      expect(articlesCubit.state.articles, isEmpty);
      expect(articlesCubit.state.isLoading, isFalse);
    });

    test('loadArticles loads and parses categories and audiences correctly', () async {
      await articlesCubit.loadArticles();

      expect(articlesCubit.state.articles.length, 3);
      expect(articlesCubit.state.filteredArticles.length, 3);
      expect(articlesCubit.state.categories, contains('Foundations (အခြေခံ)'));
      expect(articlesCubit.state.categories, contains('Core Concepts (အဓိက သဘောတရား)'));
      expect(articlesCubit.state.audiences, contains('Beginners'));
      expect(articlesCubit.state.audiences, contains('Developers'));
    });

    test('search filters articles by Burmese title or English title', () async {
      await articlesCubit.loadArticles();

      // Search by English text
      articlesCubit.search('Developers');
      expect(articlesCubit.state.filteredArticles.length, 2);

      // Search by Burmese text
      articlesCubit.search('ပညာဆိုတာဘာလဲ');
      expect(articlesCubit.state.filteredArticles.length, 1);
      expect(articlesCubit.state.filteredArticles.first.id, 'what_is_accounting');
    });

    test('filterByCategory filters articles correctly', () async {
      await articlesCubit.loadArticles();

      articlesCubit.filterByCategory('Foundations (အခြေခံ)');
      expect(articlesCubit.state.filteredArticles.length, 1);
      expect(articlesCubit.state.filteredArticles.first.id, 'what_is_accounting');

      articlesCubit.filterByCategory('All');
      expect(articlesCubit.state.filteredArticles.length, 3);
    });

    test('filterByAudience filters articles correctly', () async {
      await articlesCubit.loadArticles();

      articlesCubit.filterByAudience('Developers');
      expect(articlesCubit.state.filteredArticles.length, 2);

      // Toggle off
      articlesCubit.filterByAudience('Developers');
      expect(articlesCubit.state.filteredArticles.length, 3);
    });

    test('clearFilters resets all applied filters', () async {
      await articlesCubit.loadArticles();

      articlesCubit.filterByCategory('Foundations (အခြေခံ)');
      articlesCubit.search('ပညာ');
      expect(articlesCubit.state.filteredArticles.length, 1);

      articlesCubit.clearFilters();
      expect(articlesCubit.state.filteredArticles.length, 3);
      expect(articlesCubit.state.selectedCategory, 'All');
      expect(articlesCubit.state.searchQuery, '');
    });
  });
}
