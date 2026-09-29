import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/route_util/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../cubit/theme_mode/theme_mode_cubit.dart';
import '../../../logic/settings/settings_cubit.dart';
import '../../../logic/settings/settings_state.dart';
import 'screens/ai_settings_screen.dart';
import 'screens/print_config_screen.dart';
import 'screens/printers_settings_screen.dart';
import 'screens/profile_settings_screen.dart';
import 'screens/storage_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings (ဆက်တင်များ)')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final profile = state.userProfile;

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width * 0.05,
              vertical: 16,
            ),
            children: [
              // Business Profile Banner Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primaryGreen.withValues(
                          alpha: 0.15,
                        ),
                        child: const Icon(
                          Icons.business,
                          color: AppColors.primaryGreen,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.companyName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${profile.ownerName} • ${profile.businessType}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fiscal Year: ${profile.fiscalYear} | Currency: ${profile.currency}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Section: Core System Settings
              _buildSectionTitle('CORE SETTINGS (အဓိက စနစ်ဆက်တင်များ)', isDark),
              Card(
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.smart_toy,
                      iconColor: AppColors.primaryGreen,
                      title: 'AI Configuration (AI ဆက်တင်များ)',
                      subtitle:
                          state.geminiApiKey != null &&
                              state.geminiApiKey!.isNotEmpty
                          ? 'Gemini API Key: Configured (သိမ်းဆည်းပြီး)'
                          : 'Gemini API Key: Not configured (မထည့်ရသေး)',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AiSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      icon: Icons.storage,
                      iconColor: AppColors.assetBlue,
                      title: 'Storage & Database (ဒေတာဘေ့စ် စီမံခန့်ခွဲမှု)',
                      subtitle: 'Load sample data, clear sample, backup warning, SQLite stats',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StorageSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      icon: Icons.person_outline,
                      iconColor: AppColors.equityPurple,
                      title: 'Profile Management (လုပ်ငန်းပရိုဖိုင်)',
                      subtitle:
                          'Company details, owner name, phone, email, currency',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section: Printing & Hardware
              _buildSectionTitle(
                'PRINTING & HARDWARE (ပုံနှိပ်ခြင်းနှင့် စက်ပစ္စည်း)',
                isDark,
              ),
              Card(
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.print,
                      iconColor: Colors.teal,
                      title: 'Printers Configuration (ပရင်တာ ချိတ်ဆက်မှု)',
                      subtitle: 'Active: ${state.defaultPrinter}',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrintersSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      icon: Icons.receipt_long,
                      iconColor: Colors.deepOrange,
                      title:
                          'Print Format Configuration (ပုံနှိပ်ပုံစံ ဆက်တင်)',
                      subtitle:
                          'Header, slogan, footer, paper format (${state.printConfig.paperFormat}), signatures',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrintConfigScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section: App Appearance & Language
              _buildSectionTitle(
                'PREFERENCES (အသွင်အပြင်နှင့် ဘာသာစကား)',
                isDark,
              ),
              Card(
                child: Column(
                  children: [
                    BlocBuilder<ThemeModeCubit, ThemeMode>(
                      builder: (context, themeMode) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber.withValues(
                              alpha: 0.12,
                            ),
                            child: const Icon(
                              Icons.brightness_6,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ),
                          title: const Text(
                            'Theme Mode (အရောင်ပုံစံ)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Current: ${themeMode.name.toUpperCase()}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: DropdownButton<ThemeMode>(
                            value: themeMode,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text('System'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text('Light'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text('Dark'),
                              ),
                            ],
                            onChanged: (mode) {
                              if (mode != null) {
                                context.read<ThemeModeCubit>().toggleTheme(
                                  mode,
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withValues(
                          alpha: 0.12,
                        ),
                        child: const Icon(
                          Icons.language,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Language (ဘာသာစကား)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Current: မြန်မာ (Unicode) / English',
                        style: TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(
                        Icons.check,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section: Knowledge Base & Guides
              _buildSectionTitle(
                'KNOWLEDGE BASE & GUIDES (ဗဟုသုတနှင့် လမ်းညွှန်များ)',
                isDark,
              ),
              Card(
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.auto_stories,
                      iconColor: AppColors.primaryGreen,
                      title: 'Accounting Articles (စာရင်းကိုင် ဆောင်းပါးများ)',
                      subtitle:
                          'Beginner guides, Debit vs Credit, Balance Sheet, P&L, Double Entry & Tech',
                      onTap: () {
                        Navigator.of(context).pushNamed(RouteNames.articles);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section: App About
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppColors.primaryGreen,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Accounting Myanmar v1.0.0',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Clean Green Architecture • Double-Entry Bookkeeping Standard • Local SQLite Engine with MySQL Cloud Sync Compatibility',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.12),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
