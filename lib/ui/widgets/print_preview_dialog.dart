import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/print/print_service.dart';

class PrintPreviewDialog extends StatelessWidget {
  final FormattedPrintDocument document;
  final String defaultPrinter;
  final VoidCallback? onPrintSuccess;

  const PrintPreviewDialog({
    super.key,
    required this.document,
    required this.defaultPrinter,
    this.onPrintSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ပုံနှိပ်ရန် အစမ်းကြည့်ရှုခြင်း (Print Preview)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Target: $defaultPrinter • Format: ${document.paperFormat}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Preview Paper Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F1712)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      document.content,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: document.paperFormat == '58mm'
                            ? 10.5
                            : (document.paperFormat == '80mm' ? 11.5 : 12.5),
                        height: 1.35,
                        color: isDark ? Colors.green[300] : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: document.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Print layout copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('စာသားကူးယူရန် (Copy)'),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('မလုပ်တော့ပါ (Cancel)'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.primaryGreen,
                              content: Text(
                                'Sent to $defaultPrinter successfully! (Printing...)',
                                style: const TextStyle(color: Colors.white),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          onPrintSuccess?.call();
                        },
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('ပုံနှိပ်မည် (Print)'),
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
