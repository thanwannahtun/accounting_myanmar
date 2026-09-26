import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/account.dart';
import '../../../data/models/journal_entry.dart';
import '../../widgets/account_type_badge.dart';
import '../../widgets/currency_formatter.dart';

class JournalEntryDetailDialog extends StatelessWidget {
  final JournalEntry entry;
  final List<Account> accounts;
  final VoidCallback? onReverse;
  final VoidCallback? onPost;
  final VoidCallback? onDeleteDraft;

  const JournalEntryDetailDialog({
    super.key,
    required this.entry,
    required this.accounts,
    this.onReverse,
    this.onPost,
    this.onDeleteDraft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final numberFormat = NumberFormat('#,##0.00', 'en_US');

    final totalDebit = entry.lines.fold<double>(0.0, (sum, l) => sum + l.debit);
    final totalCredit = entry.lines.fold<double>(
      0.0,
      (sum, l) => sum + l.credit,
    );
    final isBalanced = (totalDebit - totalCredit).abs() < 0.001;

    final isMobile = MediaQuery.sizeOf(context).width < 640;

    if (isMobile) {
      // Mobile Fullscreen Layout
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('စာရင်းအသေးစိတ် (Entry Details)'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderMeta(theme, isDark, isBalanced),
                const SizedBox(height: 16),
                _buildDescriptionBox(theme, isDark),
                if (entry.remark != null && entry.remark!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildRemarkBox(theme, isDark),
                ],
                const SizedBox(height: 20),
                _buildLineItemsSection(theme, isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightSurface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'စုစုပေါင်း (Totals):',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Dr: ${numberFormat.format(totalDebit)}',
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Cr: ${numberFormat.format(totalCredit)}',
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.creditRose,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (entry.canReverse && onReverse != null)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGold,
                            side: const BorderSide(
                              color: AppColors.primaryGold,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: const Text('Reverse Entry (ပြောင်းပြန်လှန်မည်)'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onReverse!();
                          },
                        ),
                      if (entry.isDraft && onPost != null)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Post Entry (စာရင်းအတည်ပြုရန်)'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onPost!();
                          },
                        ),
                      if (entry.isDraft && onDeleteDraft != null)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.creditRose,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete Draft (မူကြမ်းဖျက်မည်)'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onDeleteDraft!();
                          },
                        ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close (ပိတ်မည်)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Tablet & Desktop Modal Layout
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildHeaderMeta(theme, isDark, isBalanced)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Scrollable Details
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDescriptionBox(theme, isDark),
                      if (entry.remark != null &&
                          entry.remark!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildRemarkBox(theme, isDark),
                      ],
                      const SizedBox(height: 20),
                      _buildLineItemsSection(theme, isDark),
                      const SizedBox(height: 16),
                      _buildTotalsCard(
                        theme,
                        isDark,
                        numberFormat,
                        totalDebit,
                        totalCredit,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (entry.canReverse && onReverse != null)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGold,
                            side: const BorderSide(
                              color: AppColors.primaryGold,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: const Text(
                            'Reverse Entry (ပြောင်းပြန်လှန်မည်)',
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onReverse!();
                          },
                        ),
                      if (entry.isDraft && onPost != null)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Post Entry (စာရင်းအတည်ပြုရန်)'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onPost!();
                          },
                        ),
                      if (entry.isDraft && onDeleteDraft != null)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.creditRose,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onDeleteDraft!();
                          },
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete Draft (မူကြမ်းဖျက်မည်)'),
                        ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderMeta(ThemeData theme, bool isDark, bool isBalanced) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#${entry.id}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isBalanced
                        ? AppColors.primaryGreen
                        : AppColors.creditRose)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBalanced ? Icons.check_circle : Icons.error_outline,
                    size: 13,
                    color: isBalanced
                        ? AppColors.primaryGreen
                        : AppColors.creditRose,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isBalanced ? 'Balanced' : 'Unbalanced',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isBalanced
                          ? AppColors.primaryGreen
                          : AppColors.creditRose,
                    ),
                  ),
                ],
              ),
            ),
            // Accounting Status Badge
            if (entry.isDraft)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_note, size: 13, color: Colors.blueGrey),
                    SizedBox(width: 4),
                    Text(
                      'Draft (မူကြမ်း)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              )
            else if (entry.isReversed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 13, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Reversed (ပြန်လှန်ပြီး)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            else if (entry.isReversal)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      size: 13,
                      color: AppColors.primaryGold,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Reversal (ပြောင်းပြန်)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ],
                ),
              )
            else if (entry.isPosted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 13,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Posted (အတည်ပြုပြီး)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('ရက်စွဲ: ${entry.date}', style: theme.textTheme.bodySmall),
            if (entry.linkedTransactionId != null)
              Text(
                'Linked: #${entry.linkedTransactionId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionBox(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'အကြောင်းအရာ (Description)',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface
                : AppColors.lightNeutralContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Text(
            entry.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              decoration: entry.isReversed ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemarkBox(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'မှတ်စု / မှတ်ချက် (Remark / Notes)',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface
                : AppColors.lightNeutralContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notes, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.remark!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineItemsSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'စာရင်းခွဲများ (Line Items)',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...entry.lines.map((line) {
          final acc = accounts.where((a) => a.id == line.accountId).firstOrNull;
          final accName = acc != null ? acc.name : line.accountId;
          final accCode = acc?.code ?? '';
          final accType = acc?.type;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (accCode.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF14241B)
                          : const Color(0xFFF1F5F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      accCode,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (accType != null) ...[
                        const SizedBox(height: 3),
                        AccountTypeBadge(type: accType),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (line.debit > 0)
                      Text(
                        'Dr: ${CurrencyFormatter.format(line.debit)}',
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    if (line.credit > 0)
                      Text(
                        'Cr: ${CurrencyFormatter.format(line.credit)}',
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.creditRose,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTotalsCard(
    ThemeData theme,
    bool isDark,
    NumberFormat numberFormat,
    double totalDebit,
    double totalCredit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'စုစုပေါင်း (Totals)',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCard
                : AppColors.lightNeutralContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    'Dr: ${numberFormat.format(totalDebit)}',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Cr: ${numberFormat.format(totalCredit)}',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.creditRose,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
