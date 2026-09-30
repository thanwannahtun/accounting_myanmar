import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../logic/settings/settings_cubit.dart';
import '../../../../logic/settings/settings_state.dart';

class PrintersSettingsScreen extends StatelessWidget {
  const PrintersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Printers Setup (ပရင်တာ ဆက်တင်များ)'),
        actions: [
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              return IconButton(
                tooltip: 'Scan for Printers',
                onPressed: state.isScanningPrinters
                    ? null
                    : () => context.read<SettingsCubit>().scanPrinters(),
                icon: state.isScanningPrinters
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          final printers = state.availablePrinters;
          final defaultPrinter = state.defaultPrinter;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width * 0.05,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.print,
                        color: AppColors.primaryGreen,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Device Scanning & Printer Management',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'USB Thermal Printers, Bluetooth Mobile Printers နှင့် Network LAN ပရင်တာများကို ချိတ်ဆက် အသုံးပြုနိုင်ပါသည်။',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Scan Button Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Devices (${printers.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: state.isScanningPrinters
                          ? null
                          : () => context.read<SettingsCubit>().scanPrinters(),
                      icon: state.isScanningPrinters
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: Text(
                        state.isScanningPrinters
                            ? 'Scanning...'
                            : 'Scan Devices',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Printers List
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: printers.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final printer = printers[index];
                      final isSelected = printer == defaultPrinter;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              (isSelected
                                      ? AppColors.primaryGreen
                                      : Colors.grey)
                                  .withValues(alpha: 0.12),
                          child: Icon(
                            Icons.print,
                            color: isSelected
                                ? AppColors.primaryGreen
                                : Colors.grey,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          printer,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          isSelected
                              ? 'Active Default Printer (လက်ရှိရွေးချယ်ထားသော ပရင်တာ)'
                              : 'Ready to connect',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? AppColors.primaryGreen
                                : Colors.grey,
                          ),
                        ),
                        trailing: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? AppColors.primaryGreen
                              : Colors.grey,
                          size: 22,
                        ),
                        onTap: () {
                          context.read<SettingsCubit>().selectDefaultPrinter(
                            printer,
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Test Print Action
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Print (စမ်းသပ်ပုံနှိပ်ခြင်း)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ရွေးချယ်ထားသော "$defaultPrinter" ပေါ်သို့ စမ်းသပ်စလစ် ထုတ်ကြည့်နိုင်ပါသည်။',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Test print sent to $defaultPrinter successfully!',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.receipt_long, size: 18),
                          label: const Text('Send Test Receipt'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
