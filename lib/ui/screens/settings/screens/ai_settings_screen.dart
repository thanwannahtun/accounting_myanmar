import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../logic/ai/ai_assistant_cubit.dart';
import '../../../../logic/settings/settings_cubit.dart';
import '../../../../logic/settings/settings_state.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscure = true;
  String _selectedModel = 'gemini-2.5-flash';

  @override
  void initState() {
    super.initState();
    final currentKey = context.read<SettingsCubit>().state.geminiApiKey ?? '';
    _apiKeyController.text = currentKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Configuration (AI ဆက်တင်များ)')),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          final hasKey =
              state.geminiApiKey != null && state.geminiApiKey!.isNotEmpty;

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
                    color: AppColors.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.smart_toy,
                        color: AppColors.primaryGreen,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Google Gemini AI Integration',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'စာရင်းရေးသွင်းမှုနှင့် အခွန်အခ သဘောတရားများကို ကူညီဖြေကြားပေးမည့် စနစ် ဖြစ်ပါသည်။',
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

                const SizedBox(height: 24),

                // Gemini API Key card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Gemini API Key',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (hasKey
                                            ? AppColors.primaryGreen
                                            : Colors.orange)
                                        .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                hasKey
                                    ? 'Configured (လုံခြုံစွာသိမ်းထားပြီး)'
                                    : 'Not Set (မထည့်ရသေး)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: hasKey
                                      ? AppColors.primaryGreen
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'API Key အား စက်တွင်း Encrypted Storage (Windows Credential / Android Encrypted Storage) တွင် သိမ်းဆည်းပါသည်။',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _apiKeyController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            hintText: 'AIzaSy...',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (hasKey)
                              TextButton.icon(
                                onPressed: () async {
                                  await context
                                      .read<SettingsCubit>()
                                      .removeGeminiApiKey();
                                  if (context.mounted) {
                                    await context
                                        .read<AiAssistantCubit>()
                                        .removeApiKey();
                                    _apiKeyController.clear();
                                  }
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'ဖျက်မည် (Remove)',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final key = _apiKeyController.text.trim();
                                if (key.isNotEmpty) {
                                  await context
                                      .read<SettingsCubit>()
                                      .saveGeminiApiKey(key);
                                  if (context.mounted) {
                                    await context
                                        .read<AiAssistantCubit>()
                                        .saveApiKeyAndResume(key);
                                  }
                                }
                              },
                              icon: const Icon(Icons.save, size: 18),
                              label: const Text('Save API Key'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // AI Model Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Model Selection',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Default: gemini-2.5-flash (Fast, accurate, cost-effective for accounting)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedModel,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'gemini-2.5-flash',
                              child: Text('Gemini 2.5 Flash (Recommended)'),
                            ),
                            DropdownMenuItem(
                              value: 'gemini-1.5-flash',
                              child: Text('Gemini 1.5 Flash'),
                            ),
                            DropdownMenuItem(
                              value: 'gemini-1.5-pro',
                              child: Text('Gemini 1.5 Pro (Deep Reasoning)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _selectedModel = val);
                          },
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
