import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/article_model.dart';
import '../../../data/repositories/articles/article_repository_interface.dart';

class ArticleDetailScreen extends StatefulWidget {
  final ArticleModel article;
  final List<ArticleModel> allArticles;

  const ArticleDetailScreen({
    super.key,
    required this.article,
    this.allArticles = const [],
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen>
    with SingleTickerProviderStateMixin {
  late ArticleModel _currentArticle;
  String? _content;
  bool _isLoading = true;
  String? _error;
  double _fontScale = 1.0;

  late final ScrollController _scrollController;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  double _slideDirection =
      1.0; // 1.0 for next (from right), -1.0 for prev (from left)
  bool _isSwitching = false;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _currentArticle = widget.article;
    _scrollController = ScrollController()..addListener(_onScroll);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _loadArticleContent();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.offset > 350;
    if (show != _showScrollToTop) {
      setState(() {
        _showScrollToTop = show;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _cleanMarkdownContent(String raw) {
    var content = raw;
    // Replace HTML line breaks with clean space/divider where found
    content = content.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      ' / ',
    );

    // Clean LaTeX block equations: $$\text{...} = ...$$ -> clean blockquotes
    content = content.replaceAllMapped(RegExp(r'\$\$(.*?)\$\$', dotAll: true), (
      match,
    ) {
      var math = match.group(1) ?? '';
      math = math.replaceAll(RegExp(r'\\text\{(.*?)\}'), r'$1');
      math = math.replaceAll(r'\quad', '  ');
      math = math.replaceAll(r'\times', '×');
      math = math.replaceAll(r'\rightarrow', '→');
      math = math.replaceAll(r'\sum', '∑');
      math = math.replaceAll(r'\left(', '(').replaceAll(r'\right)', ')');
      math = math.replaceAllMapped(
        RegExp(r'\\frac\{(.*?)\}\{(.*?)\}'),
        (fracMatch) => '(${fracMatch.group(1)} ÷ ${fracMatch.group(2)})',
      );
      math = math.trim();
      return '\n\n> 💡 **$math**\n\n';
    });

    // Clean inline math: $\text{...}$ or $...$
    content = content.replaceAllMapped(RegExp(r'\$(.*?)\$'), (match) {
      var math = match.group(1) ?? '';
      math = math.replaceAll(RegExp(r'\\text\{(.*?)\}'), r'$1');
      math = math.replaceAll(r'\rightarrow', '→');
      return '**${math.trim()}**';
    });

    // Clean any remaining unparsed LaTeX arrows
    content = content.replaceAll(r'\rightarrow', '→');

    return content;
  }

  Future<void> _loadArticleContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<ArticleRepositoryInterface>();
      final text = await repo.getArticleContent(_currentArticle.filePath);
      if (mounted) {
        setState(() {
          _content = _cleanMarkdownContent(text);
          _isLoading = false;
        });
        _animController.forward(from: 0.0);
        _preloadAdjacentArticles();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'ဆောင်းပါး အချက်အလက်များကို ဖွင့်၍မရနိုင်ပါ။ (${e.toString()})';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _switchArticle(ArticleModel targetArticle) async {
    if (_isSwitching) return;
    _isSwitching = true;

    final repo = context.read<ArticleRepositoryInterface>();

    final currentIndex = widget.allArticles.indexWhere(
      (a) => a.id == _currentArticle.id,
    );
    final targetIndex = widget.allArticles.indexWhere(
      (a) => a.id == targetArticle.id,
    );
    final isNext = targetIndex >= currentIndex;
    _slideDirection = isNext ? 1.0 : -1.0;

    // Start preloading target article content immediately in parallel
    final preloadFuture = repo.getArticleContent(targetArticle.filePath);

    // 1. Smoothly fade out current content directly without scrolling backwards
    await _animController.reverse();

    // 2. Retrieve preloaded content
    String? newContent;
    String? errorMsg;
    try {
      final text = await preloadFuture;
      newContent = _cleanMarkdownContent(text);
    } catch (e) {
      errorMsg =
          'ဆောင်းပါး အချက်အလက်များကို ဖွင့်၍မရနိုင်ပါ။ (${e.toString()})';
    }

    if (!mounted) return;

    // 3. Update state with target article
    setState(() {
      _currentArticle = targetArticle;
      _content = newContent;
      _error = errorMsg;
      _isLoading = false;
    });

    // 4. Reset scroll to 0.0 while invisible so desired article starts fresh at the top
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }

    // 5. Smoothly animate in the desired article starting from the top
    _animController.forward(from: 0.0);
    _isSwitching = false;

    // Preload adjacent articles for subsequent clicks
    _preloadAdjacentArticles();
  }

  void _preloadAdjacentArticles() {
    if (!mounted) return;
    final currentIndex = widget.allArticles.indexWhere(
      (a) => a.id == _currentArticle.id,
    );
    final repo = context.read<ArticleRepositoryInterface>();
    if (currentIndex > 0) {
      repo.getArticleContent(widget.allArticles[currentIndex - 1].filePath);
    }
    if (currentIndex >= 0 && currentIndex < widget.allArticles.length - 1) {
      repo.getArticleContent(widget.allArticles[currentIndex + 1].filePath);
    }
  }

  void _adjustFontScale(double delta) {
    setState(() {
      _fontScale = (_fontScale + delta).clamp(0.85, 1.5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    final currentIndex = widget.allArticles.indexWhere(
      (a) => a.id == _currentArticle.id,
    );
    final prevArticle = (currentIndex > 0)
        ? widget.allArticles[currentIndex - 1]
        : null;
    final nextArticle =
        (currentIndex >= 0 && currentIndex < widget.allArticles.length - 1)
        ? widget.allArticles[currentIndex + 1]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: Offset(_slideDirection * 0.1, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
            );
          },
          child: Text(
            _currentArticle.titleMm,
            key: ValueKey<String>(_currentArticle.id),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          // Text size controls
          IconButton(
            icon: const Icon(Icons.text_decrease, size: 20),
            tooltip: 'စာလုံးအရွယ်အစား သေးငယ်ရန် (A-)',
            onPressed: () => _adjustFontScale(-0.1),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase, size: 20),
            tooltip: 'စာလုံးအရွယ်အစား ကြီးရန် (A+)',
            onPressed: () => _adjustFontScale(0.1),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              tooltip: 'အပေါ်သို့ ပြန်တက်မည် (Scroll to Top)',
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 3,
              onPressed: () {
                _scrollController.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                );
              },
              child: const Icon(Icons.arrow_upward, size: 20),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width * 0.05,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.creditRose,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadArticleContent,
                      icon: const Icon(Icons.refresh),
                      label: const Text('ပြန်လည် ကြိုးစားမည်'),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: Offset(_slideDirection * 0.06, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animController,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Article Header Banner
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.sizeOf(context).width * 0.05,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category & Read Time
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _currentArticle.category,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_currentArticle.readTimeMinutes} မိနစ်ဖတ်ရန်',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Title (Burmese)
                              Text(
                                _currentArticle.titleMm,
                                style: const TextStyle(
                                  fontFamily: 'Pyidaungsu',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Title (English)
                              Text(
                                _currentArticle.titleEn,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Subtitle
                              Text(
                                _currentArticle.subtitleMm,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Target Audiences Chips
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: _currentArticle.targetAudience
                                    .map(
                                      (aud) => Chip(
                                        avatar: const Icon(
                                          Icons.person_outline,
                                          size: 13,
                                          color: AppColors.assetBlue,
                                        ),
                                        label: Text(aud),
                                        labelStyle: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.assetBlue,
                                        ),
                                        backgroundColor: AppColors.assetBlue
                                            .withValues(alpha: 0.1),
                                        side: BorderSide.none,
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    )
                                    .toList(),
                              ),
                              const Divider(height: 24),
                            ],
                          ),
                        ),
                      ),

                      // Markdown Body
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.sizeOf(context).width * 0.05,
                            vertical: 8,
                          ),
                          child: MarkdownBody(
                            data: _content ?? '',
                            selectable: true,
                            styleSheet: MarkdownStyleSheet.fromTheme(theme)
                                .copyWith(
                                  p: TextStyle(
                                    fontFamily: 'Pyidaungsu',
                                    fontSize: 15 * _fontScale,
                                    height: 1.7,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  h1: TextStyle(
                                    fontFamily: 'Pyidaungsu',
                                    fontSize: 22 * _fontScale,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                    height: 1.4,
                                  ),
                                  h2: TextStyle(
                                    fontFamily: 'Pyidaungsu',
                                    fontSize: 18 * _fontScale,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    height: 1.4,
                                  ),
                                  h3: TextStyle(
                                    fontFamily: 'Pyidaungsu',
                                    fontSize: 16 * _fontScale,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.assetBlue,
                                    height: 1.4,
                                  ),
                                  blockquote: TextStyle(
                                    fontFamily: 'Pyidaungsu',
                                    fontSize: 14 * _fontScale,
                                    height: 1.6,
                                    color: isDark
                                        ? Colors.grey[200]
                                        : Colors.grey[800],
                                  ),
                                  blockquoteDecoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.primaryGreen.withValues(
                                            alpha: 0.12,
                                          )
                                        : AppColors.greenContainerLight
                                              .withValues(alpha: 0.5),
                                    border: const Border(
                                      left: BorderSide(
                                        color: AppColors.primaryGreen,
                                        width: 4,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  blockquotePadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  tableBorder: TableBorder.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                    width: 1,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(15),
                                    ),
                                  ),
                                  tableHead: TextStyle(
                                    fontFamily: 'Pyidaungsu',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13 * _fontScale,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                  tableHeadCellsDecoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(15),
                                    ),
                                    color: isDark
                                        ? AppColors.primaryGreen.withValues(
                                            alpha: 0.12,
                                          )
                                        : AppColors.greenContainerLight
                                              .withValues(alpha: 0.5),
                                  ),
                                  tableHeadAlign: TextAlign.left,
                                  tableBody: TextStyle(
                                    fontFamily: 'Pyidaungsu',
                                    fontSize: 13 * _fontScale,
                                    height: 1.4,
                                  ),
                                  tableCellsPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  tableColumnWidth:
                                      const IntrinsicColumnWidth(),
                                  tableScrollbarThumbVisibility: true,
                                  code: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13 * _fontScale,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .onPrimary,
                                  ),
                                  codeblockDecoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  codeblockPadding: const EdgeInsets.all(14),
                                  horizontalRuleDecoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),

                      // Bottom Navigation: Previous / Next Articles
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.sizeOf(context).width * 0.05,
                            vertical: 16,
                          ),
                          child: Column(
                            children: [
                              const Divider(height: 32),
                              if (isWide)
                                // Wide Screen: Side-by-side Row
                                Row(
                                  children: [
                                    if (prevArticle != null)
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 10,
                                            ),
                                            alignment: Alignment.centerLeft,
                                          ),
                                          onPressed: _isSwitching
                                              ? null
                                              : () =>
                                                    _switchArticle(prevArticle),
                                          icon: const Icon(
                                            Icons.arrow_back,
                                            size: 16,
                                          ),
                                          label: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'ယခင် ဆောင်းပါး',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                              Text(
                                                prevArticle.titleMm,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      const Spacer(),
                                    const SizedBox(width: 12),
                                    if (nextArticle != null)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryGreen,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 10,
                                            ),
                                            alignment: Alignment.centerRight,
                                          ),
                                          onPressed: _isSwitching
                                              ? null
                                              : () =>
                                                    _switchArticle(nextArticle),
                                          icon: const Icon(
                                            Icons.arrow_forward,
                                            size: 16,
                                          ),
                                          label: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'နောက်ဆောင်းပါး',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              Text(
                                                nextArticle.titleMm,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      const Spacer(),
                                  ],
                                )
                              else
                                // Mobile View: Full-width stacked buttons
                                Column(
                                  children: [
                                    if (prevArticle != null)
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 12,
                                            ),
                                            alignment: Alignment.centerLeft,
                                          ),
                                          onPressed: _isSwitching
                                              ? null
                                              : () =>
                                                    _switchArticle(prevArticle),
                                          icon: const Icon(
                                            Icons.arrow_back,
                                            size: 16,
                                          ),
                                          label: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'ယခင် ဆောင်းပါး (Previous Article)',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                prevArticle.titleMm,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (prevArticle != null &&
                                        nextArticle != null)
                                      const SizedBox(height: 10),
                                    if (nextArticle != null)
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryGreen,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 12,
                                            ),
                                            alignment: Alignment.centerLeft,
                                          ),
                                          onPressed: _isSwitching
                                              ? null
                                              : () =>
                                                    _switchArticle(nextArticle),
                                          icon: const Icon(
                                            Icons.arrow_forward,
                                            size: 16,
                                          ),
                                          label: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'နောက်ဆောင်းပါး (Next Article)',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                nextArticle.titleMm,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
