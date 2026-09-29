import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/article_model.dart';
import '../../../data/repositories/articles/article_repository_interface.dart';
import '../../../logic/articles/articles_cubit.dart';
import '../../../logic/articles/articles_state.dart';
import 'article_detail_screen.dart';
import 'widgets/article_card.dart';

class ArticlesListScreen extends StatelessWidget {
  const ArticlesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ArticlesCubit>(
      create: (context) => ArticlesCubit(
        articleRepository: context.read<ArticleRepositoryInterface>(),
      )..loadArticles(),
      child: const _ArticlesListView(),
    );
  }
}

class _ArticlesListView extends StatefulWidget {
  const _ArticlesListView();

  @override
  State<_ArticlesListView> createState() => _ArticlesListViewState();
}

class _ArticlesListViewState extends State<_ArticlesListView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openArticle(
    BuildContext context,
    ArticleModel article,
    List<ArticleModel> all,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArticleDetailScreen(article: article, allArticles: all),
      ),
    );
  }

  Widget _buildAudienceFilter(
    BuildContext context,
    ArticlesState state,
    bool isDark,
  ) {
    final isSelected = state.selectedAudience != null;
    final audienceColor = isSelected
        ? AppColors.assetBlue
        : (isDark ? Colors.grey[400]! : Colors.grey[700]!);

    return PopupMenuButton<String?>(
      tooltip: 'ပစ်မှတ် ရွေးချယ်ပါ (Target Audience)',
      initialValue: state.selectedAudience,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      onSelected: (aud) {
        if (aud == null) {
          if (state.selectedAudience != null) {
            context.read<ArticlesCubit>().filterByAudience(state.selectedAudience);
          }
        } else {
          context.read<ArticlesCubit>().filterByAudience(aud);
        }
      },
      itemBuilder: (ctx) {
        return [
          PopupMenuItem<String?>(
            value: null,
            child: Row(
              children: [
                Icon(
                  state.selectedAudience == null
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: state.selectedAudience == null
                      ? AppColors.primaryGreen
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'ပစ်မှတ် အားလုံး (All)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: state.selectedAudience == null
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: state.selectedAudience == null
                        ? AppColors.primaryGreen
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          ...state.audiences.map((aud) {
            final isAudSelected = state.selectedAudience == aud;
            return PopupMenuItem<String?>(
              value: aud,
              child: Row(
                children: [
                  Icon(
                    isAudSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: isAudSelected ? AppColors.assetBlue : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aud,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isAudSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isAudSelected ? AppColors.assetBlue : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.assetBlue.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.assetBlue
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 15,
              color: audienceColor,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                isSelected ? state.selectedAudience! : 'ပစ်မှတ် (Audience)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? AppColors.assetBlue
                      : (isDark ? Colors.grey[300] : Colors.grey[800]),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            if (isSelected)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  context
                      .read<ArticlesCubit>()
                      .filterByAudience(state.selectedAudience);
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 2.0),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.assetBlue,
                  ),
                ),
              )
            else
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: audienceColor,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final responsiveHorizontalPadding =
        MediaQuery.sizeOf(context).width * 0.05;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Accounting Guides (ဆောင်းပါးများ)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'ပြန်လည်ရယူရန်',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ArticlesCubit>().loadArticles(),
          ),
        ],
      ),
      body: BlocBuilder<ArticlesCubit, ArticlesState>(
        builder: (context, state) {
          if (state.isLoading && state.articles.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          if (state.errorMessage != null && state.articles.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsiveHorizontalPadding,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.menu_book,
                      size: 48,
                      color: AppColors.warningOrange,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ArticlesCubit>().loadArticles(),
                      child: const Text('ပြန်လည် ကြိုးစားမည်'),
                    ),
                  ],
                ),
              ),
            );
          }

          final filteredArticles = state.filteredArticles;
          final hasActiveFilters = state.selectedCategory != 'All' ||
              state.selectedAudience != null ||
              state.searchQuery.isNotEmpty;

          return RefreshIndicator(
            color: AppColors.primaryGreen,
            onRefresh: () => context.read<ArticlesCubit>().loadArticles(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header Learning Hub Banner
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsiveHorizontalPadding,
                              vertical: isWide ? 16 : 8,
                            ),
                            child: Container(
                              padding: isWide
                                  ? const EdgeInsets.all(16)
                                  : const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          AppColors.darkCard,
                                          AppColors.primaryGreen.withValues(
                                            alpha: 0.15,
                                          ),
                                        ]
                                      : [
                                          AppColors.greenContainerLight
                                              .withValues(alpha: 0.7),
                                          Colors.white,
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.primaryGreen.withValues(
                                          alpha: 0.3,
                                        )
                                      : AppColors.primaryGreen.withValues(
                                          alpha: 0.2,
                                        ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(isWide ? 12 : 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen.withValues(
                                        alpha: 0.18,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.auto_stories,
                                      color: AppColors.primaryGreen,
                                      size: isWide ? 28 : 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'စာရင်းကိုင် ဗဟုသုတ မဏ္ဍိုင် (Knowledge Base)',
                                          style: TextStyle(
                                            fontSize: isWide ? 15 : 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isWide
                                              ? 'အစပြုသူများ၊ SME လုပ်ငန်းရှင်များ၊ စာရင်းကိုင်များနှင့် ဆော့ဖ်ဝဲလ် Developers များအတွက် အခြေခံမှစ၍ လက်တွေ့အသုံးချနိုင်သော လမ်းညွှန်ဆောင်းပါးများ'
                                              : 'အခြေခံမှစ၍ လက်တွေ့အသုံးချနိုင်သော လမ်းညွှန်ဆောင်းပါးများ',
                                          maxLines: isWide ? 2 : 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.grey[300]
                                                : Colors.grey[700],
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Search Field
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsiveHorizontalPadding,
                              vertical: 6,
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) =>
                                  context.read<ArticlesCubit>().search(val),
                              decoration: InputDecoration(
                                hintText:
                                    'ဆောင်းပါး ခေါင်းစဉ် သို့မဟုတ် အကြောင်းအရာ ရှာဖွေပါ...',
                                hintStyle: const TextStyle(fontSize: 13),
                                prefixIcon:
                                    const Icon(Icons.search, size: 20),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          context
                                              .read<ArticlesCubit>()
                                              .search('');
                                        },
                                      )
                                    : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryGreen,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Unified Filter Bar (Target Audience + Categories + Reset)
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(
                              horizontal: responsiveHorizontalPadding,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                // Audience Filter Dropdown / Chip
                                if (state.audiences.isNotEmpty) ...[
                                  _buildAudienceFilter(context, state, isDark),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Container(
                                      height: 20,
                                      width: 1,
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                    ),
                                  ),
                                ],

                                // Categories Filter Chips
                                ...state.categories.map((category) {
                                  final isSelected =
                                      state.selectedCategory == category;
                                  final label = category == 'All'
                                      ? 'အားလုံး (All)'
                                      : category;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: FilterChip(
                                      selected: isSelected,
                                      showCheckmark: false,
                                      label: Text(label),
                                      visualDensity: VisualDensity.compact,
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.grey[300]
                                                : Colors.grey[800]),
                                      ),
                                      backgroundColor: isDark
                                          ? AppColors.darkCard
                                          : AppColors.lightCard,
                                      selectedColor: AppColors.primaryGreen,
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppColors.primaryGreen
                                            : (isDark
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      onSelected: (_) {
                                        context
                                            .read<ArticlesCubit>()
                                            .filterByCategory(category);
                                      },
                                    ),
                                  );
                                }),

                                // Reset Chip
                                if (hasActiveFilters) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: ActionChip(
                                      avatar: const Icon(
                                        Icons.refresh,
                                        size: 14,
                                        color: AppColors.creditRose,
                                      ),
                                      label: const Text('Reset'),
                                      visualDensity: VisualDensity.compact,
                                      labelStyle: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.creditRose,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      backgroundColor: AppColors.creditRose
                                          .withValues(alpha: 0.1),
                                      side: BorderSide(
                                        color: AppColors.creditRose
                                            .withValues(alpha: 0.3),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        context
                                            .read<ArticlesCubit>()
                                            .clearFilters();
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 6)),

                    // Articles List / Responsive Grid
                    if (filteredArticles.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsiveHorizontalPadding,
                              vertical: 16,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'ကိုက်ညီသော ဆောင်းပါး ရှာမတွေ့ပါ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'အခြား စကားလုံးများဖြင့် ရှာဖွေကြည့်ပါ သို့မဟုတ် Filter များကို ဖျက်ပါ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<ArticlesCubit>()
                                        .clearFilters();
                                  },
                                  icon: const Icon(Icons.clear_all),
                                  label: const Text('Filter များ ရှင်းထုတ်မည်'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (isWide)
                      // Wide Screen / Tablet 2-column Grid
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsiveHorizontalPadding,
                          vertical: 16,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 480,
                            mainAxisExtent: 255,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 8,
                          ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final article = filteredArticles[index];
                            return ArticleCard(
                              article: article,
                              onTap: () => _openArticle(
                                context,
                                article,
                                state.articles,
                              ),
                            );
                          }, childCount: filteredArticles.length),
                        ),
                      )
                    else
                      // Mobile Screen 1-column List
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsiveHorizontalPadding,
                          vertical: 16,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final article = filteredArticles[index];
                            return ArticleCard(
                              article: article,
                              onTap: () => _openArticle(
                                context,
                                article,
                                state.articles,
                              ),
                            );
                          }, childCount: filteredArticles.length),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
