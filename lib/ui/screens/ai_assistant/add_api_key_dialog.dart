import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AddApiKeyDialog extends StatefulWidget {
  final String? initialKey;
  final Function(String key) onSave;
  final VoidCallback? onCancel;

  const AddApiKeyDialog({
    super.key,
    this.initialKey,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<AddApiKeyDialog> createState() => _AddApiKeyDialogState();
}

class _AddApiKeyDialogState extends State<AddApiKeyDialog> {
  late TextEditingController _keyController;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.initialKey ?? '');
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _submit() {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;
    widget.onSave(key);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.key, color: AppColors.primaryGreen, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gemini API Key ထည့်သွင်းပါ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI စာရင်းကိုင်လက်ထောက်ကို အသုံးပြုနိုင်ရန် Google Gemini API Key လိုအပ်ပါသည်။ သင်၏ API Key ကို စက်တွင်း Encrypted Secure Storage တွင် လုံခြုံစွာ သိမ်းဆည်းပေးမည် ဖြစ်ပါသည်။',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gemini API Key:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _keyController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.assetBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.assetBlue.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.assetBlue,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API Key ကို aistudio.google.com မှ အခမဲ့ ရယူနိုင်ပါသည်။ Settings မှလည်း အချိန်မရွေး ပြန်လည် ပြင်ဆင်နိုင်ပါသည်။',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.assetBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onCancel?.call();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('သိမ်းဆည်းမည် (Save Key)'),
        ),
      ],
    );
  }
}
