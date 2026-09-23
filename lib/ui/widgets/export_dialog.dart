import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/export/export_service.dart';

class ExportDialog extends StatelessWidget {
  final ExportResult result;

  const ExportDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.table_chart, color: AppColors.primaryGreen, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Excel / CSV ဒေတာထုတ်ယူပြီးပါပြီ',
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
              'အစီရင်ခံစာအား Excel သို့မဟုတ် အခြားသော Accounting Software များတွင် အလွယ်တကူ ထည့်သွင်း (Import) အသုံးပြုနိုင်ရန် CSV ဖိုင်အဖြစ် သိမ်းဆည်းပြီးပါပြီ။',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ဖိုင်အမည် (File Name):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: SelectableText(
                result.fileName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ဖိုင်သိမ်းဆည်းထားသည့် လမ်းကြောင်း (Saved Location):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: SelectableText(
                result.filePath,
                style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: result.csvContent));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CSV content copied to clipboard!')),
            );
          },
          child: const Text('CSV စာသားကူးယူ (Copy CSV)'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('အိုကေ (OK)'),
        ),
      ],
    );
  }
}
