import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/account.dart';
import '../../../data/models/journal_entry_line.dart';

class AddJournalEntryDialog extends StatefulWidget {
  final List<Account> accounts;
  final Function({
    required String date,
    required String description,
    required List<JournalEntryLine> lines,
    String? remark,
    bool isDraft,
  })
  onSave;

  const AddJournalEntryDialog({
    super.key,
    required this.accounts,
    required this.onSave,
  });

  @override
  State<AddJournalEntryDialog> createState() => _AddJournalEntryDialogState();
}

class _LineEntryModel {
  String id;
  String accountId;
  TextEditingController debitCtrl;
  TextEditingController creditCtrl;

  _LineEntryModel({required this.id})
    : accountId = '',
      debitCtrl = TextEditingController(text: ''),
      creditCtrl = TextEditingController(text: '');

  double get debit =>
      double.tryParse(debitCtrl.text.replaceAll(',', '')) ?? 0.0;
  double get credit =>
      double.tryParse(creditCtrl.text.replaceAll(',', '')) ?? 0.0;
}

class _AddJournalEntryDialogState extends State<AddJournalEntryDialog> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  late String _selectedDate;
  late List<_LineEntryModel> _lines;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _lines = [_LineEntryModel(id: '1'), _LineEntryModel(id: '2')];
  }

  @override
  void dispose() {
    _descController.dispose();
    _remarkController.dispose();
    for (final line in _lines) {
      line.debitCtrl.dispose();
      line.creditCtrl.dispose();
    }
    super.dispose();
  }

  double get totalDebit => _lines.fold(0.0, (sum, l) => sum + l.debit);
  double get totalCredit => _lines.fold(0.0, (sum, l) => sum + l.credit);
  bool get isBalanced =>
      (totalDebit - totalCredit).abs() < 0.001 && totalDebit > 0;

  void _addLine() {
    setState(() {
      _lines.add(
        _LineEntryModel(id: DateTime.now().millisecondsSinceEpoch.toString()),
      );
    });
  }

  void _removeLine(int index) {
    if (_lines.length <= 2) return;
    setState(() {
      final removed = _lines.removeAt(index);
      removed.debitCtrl.dispose();
      removed.creditCtrl.dispose();
    });
  }

  void _submit({bool isDraft = false}) {
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('အကြောင်းအရာ (Description) ထည့်သွင်းပေးပါ'),
          backgroundColor: AppColors.creditRose,
        ),
      );
      return;
    }

    if (!isDraft && !isBalanced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'စာရင်းအတည်ပြုရန် Debit နှင့် Credit တူညီရပါမည် (Debits & Credits must balance)',
          ),
          backgroundColor: AppColors.creditRose,
        ),
      );
      return;
    }

    final entryLines = _lines
        .where((l) => l.accountId.isNotEmpty && (l.debit > 0 || l.credit > 0))
        .map(
          (l) => JournalEntryLine(
            id: 'l_${DateTime.now().millisecondsSinceEpoch}_${l.id}',
            journalEntryId: '',
            accountId: l.accountId,
            debit: l.debit,
            credit: l.credit,
          ),
        )
        .toList();

    widget.onSave(
      date: _selectedDate,
      description: desc,
      remark: _remarkController.text.trim().isNotEmpty
          ? _remarkController.text.trim()
          : null,
      lines: entryLines,
      isDraft: isDraft,
    );
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_selectedDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final numberFormat = NumberFormat('#,##0.00', 'en_US');
    final isMobile = MediaQuery.sizeOf(context).width < 650;

    if (isMobile) {
      // Mobile Full-Screen Layout with system keyboard awareness
      return Dialog.fullscreen(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text('စာရင်းသွင်းရန် (New Entry)'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              TextButton(
                onPressed: _descController.text.trim().isNotEmpty
                    ? () => _submit(isDraft: true)
                    : null,
                child: const Text('Draft'),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  onPressed:
                      (isBalanced && _descController.text.trim().isNotEmpty)
                      ? () => _submit(isDraft: false)
                      : null,
                  child: const Text('Post'),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Picker Button
                      Text(
                        'ရက်စွဲ (Date)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Description Field
                      Text(
                        'အကြောင်းအရာ (Description / Memo)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. ဝယ်ယူသူထံမှ အကြွေးငွေ လက်ခံရရှိခြင်း',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 14),

                      // Remark Field (Optional)
                      Text(
                        'မှတ်စု / မှတ်ချက် (Remark / Notes - Optional)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _remarkController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'အပိုဆောင်း အချက်အလက်များ၊ ပြေစာအမှတ် သို့မဟုတ် မှတ်စုများ ထည့်သွင်းနိုင်သည်...',
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Line Items Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'စာရင်းခွဲများ (${_lines.length} Lines)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addLine,
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 16,
                            ),
                            label: const Text('Add Line'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Mobile Stacked Line Cards
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _lines.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _lines[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Line Header with Account Dropdown
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 11,
                                      backgroundColor: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightNeutralContainer,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: item.accountId.isEmpty
                                            ? null
                                            : item.accountId,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                        ),
                                        hint: const Text(
                                          'အကောင့်ရွေးချယ်ပါ...',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        items: widget.accounts.map((acc) {
                                          return DropdownMenuItem<String>(
                                            value: acc.id,
                                            child: Text(
                                              '${acc.code} - ${acc.name}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            item.accountId = val ?? '';
                                          });
                                        },
                                      ),
                                    ),
                                    if (_lines.length > 2)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                        ),
                                        color: AppColors.creditRose,
                                        onPressed: () => _removeLine(index),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Debit and Credit side by side
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Debit (+)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryGreen,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          TextField(
                                            controller: item.debitCtrl,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            textAlign: TextAlign.right,
                                            enabled: item.credit <= 0,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'Courier',
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryGreen,
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: '0.00',
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10,
                                                  ),
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Credit (-)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.creditRose,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          TextField(
                                            controller: item.creditCtrl,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            textAlign: TextAlign.right,
                                            enabled: item.debit <= 0,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'Courier',
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.creditRose,
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: '0.00',
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10,
                                                  ),
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Persistent Totals Bar at bottom
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Dr: ${numberFormat.format(totalDebit)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Courier',
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              Text(
                                'Cr: ${numberFormat.format(totalCredit)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Courier',
                                  color: AppColors.creditRose,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isBalanced
                                          ? AppColors.primaryGreen
                                          : AppColors.creditRose)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    (isBalanced
                                            ? AppColors.primaryGreen
                                            : AppColors.creditRose)
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isBalanced
                                      ? Icons.check_circle
                                      : Icons.warning_amber_rounded,
                                  size: 14,
                                  color: isBalanced
                                      ? AppColors.primaryGreen
                                      : AppColors.creditRose,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isBalanced
                                      ? 'Balanced'
                                      : 'Diff: ${numberFormat.format((totalDebit - totalCredit).abs())}',
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
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _descController.text.trim().isNotEmpty
                                  ? () => _submit(isDraft: true)
                                  : null,
                              icon: const Icon(Icons.edit_note, size: 16),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: const Text('မူကြမ်းသိမ်းမည်'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                              ),
                              onPressed:
                                  (isBalanced &&
                                      _descController.text.trim().isNotEmpty)
                                  ? () => _submit(isDraft: false)
                                  : null,
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 16,
                              ),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: const Text('အတည်ပြုသွင်းမည်'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Tablet & Desktop Modal Dialog Layout
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'စာရင်းသွင်းရန် (New Journal Entry)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Date & Description
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date (ရက်စွဲ)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const Icon(Icons.calendar_today, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description / Memo (အကြောင်းအရာ)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            hintText:
                                'e.g. ဝယ်ယူသူထံမှ အကြွေးငွေ လက်ခံရရှိခြင်း',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Remark Field (Optional)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'မှတ်စု / မှတ်ချက် (Remark / Notes - Optional)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _remarkController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'အပိုဆောင်း အချက်အလက်များ၊ ပြေစာအမှတ် သို့မဟုတ် မှတ်စုများ ထည့်သွင်းနိုင်သည်...',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Lines List Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightNeutralContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Account (စာရင်းခေါင်းစဉ်)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Debit (+)',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Credit (-)',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.creditRose,
                        ),
                      ),
                    ),
                    SizedBox(width: 36),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Dynamic Lines in Table
              Expanded(
                child: ListView.separated(
                  itemCount: _lines.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _lines[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Account Dropdown
                        Expanded(
                          flex: 5,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: item.accountId.isEmpty
                                ? null
                                : item.accountId,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            hint: const Text(
                              'အကောင့်ရွေးပါ...',
                              style: TextStyle(fontSize: 12),
                            ),
                            items: widget.accounts.map((acc) {
                              return DropdownMenuItem<String>(
                                value: acc.id,
                                child: Text(
                                  '${acc.code} - ${acc.name}',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                item.accountId = val ?? '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Debit Field
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: item.debitCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.right,
                            enabled: item.credit <= 0,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Credit Field
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: item.creditCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.right,
                            enabled: item.debit <= 0,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                              color: AppColors.creditRose,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Delete Line Button
                        SizedBox(
                          width: 32,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: _lines.length > 2
                                ? AppColors.creditRose
                                : Colors.grey,
                            onPressed: _lines.length > 2
                                ? () => _removeLine(index)
                                : null,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Add Line Button & Running Totals
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Line Item'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightNeutralContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isBalanced
                            ? AppColors.primaryGreen.withValues(alpha: 0.5)
                            : AppColors.creditRose.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Debit: ${numberFormat.format(totalDebit)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Credit: ${numberFormat.format(totalCredit)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.creditRose,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isBalanced
                              ? Icons.check_circle
                              : Icons.warning_amber_rounded,
                          size: 16,
                          color: isBalanced
                              ? AppColors.primaryGreen
                              : AppColors.creditRose,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _descController.text.trim().isNotEmpty
                        ? () => _submit(isDraft: true)
                        : null,
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Save as Draft (မူကြမ်းသိမ်းမည်)'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        (isBalanced && _descController.text.trim().isNotEmpty)
                        ? () => _submit(isDraft: false)
                        : null,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Post Entry (စာရင်းအတည်ပြုသွင်းမည်)'),
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
