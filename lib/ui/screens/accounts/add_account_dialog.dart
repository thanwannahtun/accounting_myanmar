import 'package:flutter/material.dart';

import '../../../core/constants/account_types.dart';
import '../../../data/models/account.dart';

class AddAccountDialog extends StatefulWidget {
  final Account? initialAccount;
  final Function({
    required String code,
    required String name,
    required String type,
  })
  onSave;

  const AddAccountDialog({
    super.key,
    this.initialAccount,
    required this.onSave,
  });

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late String _selectedType;

  bool get isEditing => widget.initialAccount != null;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.initialAccount?.code ?? '');
    _nameCtrl = TextEditingController(text: widget.initialAccount?.name ?? '');
    _selectedType = widget.initialAccount?.type ?? AccountTypes.revenue;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onSave(
      code: _codeCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      type: _selectedType,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    final dialogContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isEditing
                      ? 'အကောင့် ပြင်ဆင်ခြင်း (Edit Account)'
                      : 'အကောင့်သစ် ထည့်သွင်းခြင်း (Add Account)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 16),

          // GL Code Field
          Text(
            'GL Code (စာရင်းကုဒ်)',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _codeCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. 1001 or 6002',
              prefixIcon: Icon(Icons.tag, size: 18),
            ),
            keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'ကျေးဇူးပြု၍ စာရင်းကုဒ် ထည့်သွင်းပါ (Enter GL Code)';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Account Name Field
          Text(
            'Account Name (အကောင့်အမည်)',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Cash in Hand or Office Supplies',
              prefixIcon: Icon(Icons.badge_outlined, size: 18),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'ကျေးဇူးပြု၍ အကောင့်အမည် ထည့်သွင်းပါ (Enter Account Name)';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Account Type Dropdown
          Text(
            'Account Type (အမျိုးအစား)',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.category_outlined, size: 18),
            ),
            items: AccountTypes.all.map((t) {
              return DropdownMenuItem(value: t, child: Text(t));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedType = val);
            },
          ),

          const SizedBox(height: 24),

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
                onPressed: _submit,
                icon: Icon(isEditing ? Icons.check : Icons.add, size: 18),
                label: Text(isEditing ? 'Update Account' : 'Save Account'),
              ),
            ],
          ),
        ],
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: dialogContent,
        ),
      ),
    );
  }
}
