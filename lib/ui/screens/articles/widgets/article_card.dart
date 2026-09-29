import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/article_model.dart';

class ArticleCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;

  const ArticleCard({super.key, required this.article, required this.onTap});

  IconData _getIconData(String name) {
    switch (name) {
      case 'school_outlined':
        return Icons.school_outlined;
      case 'functions_outlined':
        return Icons.functions_outlined;
      case 'balance_outlined':
        return Icons.balance_outlined;
      case 'category_outlined':
        return Icons.category_outlined;
      case 'sync_alt_outlined':
        return Icons.sync_alt_outlined;
      case 'format_list_numbered_outlined':
        return Icons.format_list_numbered_outlined;
      case 'account_balance_outlined':
        return Icons.account_balance_outlined;
      case 'trending_up_outlined':
        return Icons.trending_up_outlined;
      case 'payments_outlined':
        return Icons.payments_outlined;
      case 'code_outlined':
        return Icons.code_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    if (category.contains('Foundations')) {
      return AppColors.primaryGreen;
    } else if (category.contains('Core Concepts')) {
      return AppColors.assetBlue;
    } else if (category.contains('Practical Workflows')) {
      return AppColors.primaryGold;
    } else if (category.contains('Financial Statements')) {
      return AppColors.equityPurple;
    } else if (category.contains('Business Management')) {
      return Colors.teal;
    } else if (category.contains('Software Architecture')) {
      return Colors.deepOrange;
    }
    return AppColors.primaryGreen;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryColor = _getCategoryColor(article.category);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Order & Category + Read time
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconData(article.icon),
                          size: 14,
                          color: categoryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '#${article.order}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      article.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${article.readTimeMinutes} မိနစ်',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Title in Burmese
              Text(
                article.titleMm,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Subtitle in English
              const SizedBox(height: 2),
              Text(
                article.titleEn,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Short summary preview
              const SizedBox(height: 6),
              Text(
                article.summaryMm,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // Target audience chips + Read CTA
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: article.targetAudience.map((aud) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                aud,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ဖတ်ရှုရန်',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
