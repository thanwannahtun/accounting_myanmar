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
  }) onSave;

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

  _LineEntryModel({
    required this.id,
  })  : accountId = '',
        debitCtrl = TextEditingController(text: ''),
        creditCtrl = TextEditingController(text: '');

  double get debit => double.tryParse(debitCtrl.text.replaceAll(',', '')) ?? 0.0;
  double get credit => double.tryParse(creditCtrl.text.replaceAll(',', '')) ?? 0.0;
}

class _AddJournalEntryDialogState extends State<AddJournalEntryDialog> {
  final TextEditingController _descController = TextEditingController();
  late String _selectedDate;
  late List<_LineEntryModel> _lines;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _lines = [
      _LineEntryModel(id: '1'),
      _LineEntryModel(id: '2'),
    ];
  }

  @override
  void dispose() {
    _descController.dispose();
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
      _lines.add(_LineEntryModel(id: DateTime.now().millisecondsSinceEpoch.toString()));
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

  void _submit() {
    final desc = _descController.text.trim();
    if (desc.isEmpty || !isBalanced) return;

    final entryLines = _lines
        .where((l) => l.accountId.isNotEmpty && (l.debit > 0 || l.credit > 0))
        .map((l) => JournalEntryLine(
              id: 'l_${DateTime.now().millisecondsSinceEpoch}_${l.id}',
              journalEntryId: '',
              accountId: l.accountId,
              debit: l.debit,
              credit: l.credit,
            ))
        .toList();

    widget.onSave(
      date: _selectedDate,
      description: desc,
      lines: entryLines,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                  const Text(
                    'စာရင်းသွင်းရန် (New Journal Entry)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date (ရက်စွဲ)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () async {
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
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_selectedDate, style: const TextStyle(fontSize: 12)),
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
                        const Text('Description / Memo (အကြောင်းအရာ)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. ဝယ်ယူသူထံမှ အကြွေးငွေ လက်ခံရရှိခြင်း',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Lines List Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 5, child: Text('Account (စာရင်းခေါင်းစဉ်)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    SizedBox(width: 8),
                    Expanded(flex: 3, child: Text('Debit (+)', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen))),
                    SizedBox(width: 8),
                    Expanded(flex: 3, child: Text('Credit (-)', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.creditRose))),
                    SizedBox(width: 36),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Dynamic Lines
              Expanded(
                child: ListView.separated(
                  itemCount: _lines.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
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
                            initialValue: item.accountId.isEmpty ? null : item.accountId,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            hint: const Text('အကောင့်ရွေးပါ...', style: TextStyle(fontSize: 12)),
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.right,
                            enabled: item.credit <= 0,
                            style: const TextStyle(fontSize: 12, fontFamily: 'Courier', color: AppColors.primaryGreen),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.right,
                            enabled: item.debit <= 0,
                            style: const TextStyle(fontSize: 12, fontFamily: 'Courier', color: AppColors.creditRose),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                            color: _lines.length > 2 ? AppColors.creditRose : Colors.grey,
                            onPressed: _lines.length > 2 ? () => _removeLine(index) : null,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isBalanced ? AppColors.primaryGreen.withOpacity(0.5) : AppColors.creditRose.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Debit: ${NumberFormat('#,##0.00').format(totalDebit)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Credit: ${NumberFormat('#,##0.00').format(totalCredit)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.creditRose),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isBalanced ? Icons.check_circle : Icons.warning_amber_rounded,
                          size: 16,
                          color: isBalanced ? AppColors.primaryGreen : AppColors.creditRose,
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
                  ElevatedButton.icon(
                    onPressed: (isBalanced && _descController.text.trim().isNotEmpty) ? _submit : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Save Entry (စာရင်းသိမ်းမည်)'),
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
