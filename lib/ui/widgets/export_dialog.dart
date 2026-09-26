import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/export/export_service.dart';

class ExportDialog extends StatelessWidget {
  final ExportResult result;

  const ExportDialog({super.key, required this.result});

  Widget _buildBody(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'အစီရင်ခံစာအား Excel သို့မဟုတ် အခြားသော Accounting Software များတွင် အလွယ်တကူ ထည့်သွင်း အသုံးပြုနိုင်ရန် CSV ဖိုင်အဖြစ် သိမ်းဆည်းပြီးပါပြီ။',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
              ),
            ],
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
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: SelectableText(
            result.fileName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'ဖိုင်သိမ်းဆည်းထားသည့် လမ်းကြောင်း (Saved Location):',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: SelectableText(
            result.filePath,
            style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.sizeOf(context).width < 640;

    void copyCsv() {
      Clipboard.setData(ClipboardData(text: result.csvContent));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV content copied to clipboard!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    }

    if (isMobile) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Excel / CSV Export'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: _buildBody(context, isDark),
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: copyCsv,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy CSV'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('အိုကေ (OK)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Tablet & Desktop Centered Modal Dialog
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.table_chart,
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Excel / CSV ဒေတာထုတ်ယူပြီးပါပြီ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildBody(context, isDark),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: copyCsv,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('CSV စာသားကူးယူ (Copy CSV)'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('အိုကေ (OK)'),
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
