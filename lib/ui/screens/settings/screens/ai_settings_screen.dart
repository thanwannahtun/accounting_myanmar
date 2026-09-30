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
  String _selectedModel = 'gemini-3.8-flash';

  static const List<Map<String, String>> _availableModels = [
    {
      'id': 'gemini-3.8-flash',
      'title': 'Gemini 3.8 Flash (Recommended Flagship)',
      'badge': 'Flagship',
      'desc': 'အသစ်ဆုံး Flagship Flash - မြန်ဆန်၊ တိကျ၊ စာရင်းအင်းအတွက် အသင့်တော်ဆုံး',
    },
    {
      'id': 'gemini-3.7-flash',
      'title': 'Gemini 3.7 Flash',
      'badge': 'High Perf',
      'desc': 'စွမ်းဆောင်ရည်မြင့် High-Performance Flash Tier',
    },
    {
      'id': 'gemini-3.6-flash',
      'title': 'Gemini 3.6 Flash',
      'badge': 'Balanced',
      'desc': 'တည်ငြိမ်ပြီး စာရင်းတွက်ချက်မှု မြန်ဆန်သော Model',
    },
    {
      'id': 'gemini-3.5-flash',
      'title': 'Gemini 3.5 Flash',
      'badge': 'Mid-Tier',
      'desc': 'Mid-Tier Stable Production Model',
    },
    {
      'id': 'gemini-3.5-flash-lite',
      'title': 'Gemini 3.5 Flash Lite',
      'badge': 'Lite',
      'desc': 'Fastest / Cost-Effective Class (အလွန်မြန်ဆန်ပေါ့ပါး)',
    },
    {
      'id': 'gemini-3.1-flash-lite',
      'title': 'Gemini 3.1 Flash Lite',
      'badge': 'Ultra-Lite',
      'desc': 'Ultra Lightweight Efficiency Tier',
    },
  ];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsCubit>().state;
    _apiKeyController.text = settings.geminiApiKey ?? '';
    _selectedModel = settings.selectedAiModel;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveModel(String model) async {
    final clean = model.trim();
    if (clean.isEmpty) return;
    setState(() => _selectedModel = clean);
    await context.read<SettingsCubit>().selectAiModel(clean);
    if (mounted) {
      await context.read<AiAssistantCubit>().setModel(clean);
    }
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          if (state.selectedAiModel.isNotEmpty &&
              state.selectedAiModel != _selectedModel) {
            setState(() {
              _selectedModel = state.selectedAiModel;
            });
          }
        },
        builder: (context, state) {
          final hasKey =
              state.geminiApiKey != null && state.geminiApiKey!.isNotEmpty;
          final activeModel = state.selectedAiModel.isNotEmpty
              ? state.selectedAiModel
              : _selectedModel;

          // Find info of the currently active model
          final activeModelInfo = _availableModels.firstWhere(
            (m) => m['id'] == activeModel,
            orElse: () => {
              'id': activeModel,
              'title': activeModel,
              'badge': 'Custom',
              'desc': 'Custom specified AI Model identifier',
            },
          );

          // Build dropdown items ensuring activeModel is present
          final dropdownItems = <DropdownMenuItem<String>>[];
          final knownIds = <String>{};

          for (final item in _availableModels) {
            knownIds.add(item['id']!);
            dropdownItems.add(
              DropdownMenuItem(
                value: item['id'],
                child: Text(
                  item['title']!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            );
          }

          if (!knownIds.contains(activeModel)) {
            dropdownItems.insert(
              0,
              DropdownMenuItem(
                value: activeModel,
                child: Text(
                  '$activeModel (Custom)',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            );
          }

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
                        Icons.smart_toy_outlined,
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
                              'စာရင်းရေးသွင်းမှု၊ Debit/Credit စစ်ဆေးမှုနှင့် အခွန်အခ သဘောတရားများကို ကူညီဖြေကြားပေးမည့် စနစ် ဖြစ်ပါသည်။',
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

                // Gemini API Key card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
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
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (hasKey
                                            ? AppColors.primaryGreen
                                            : Colors.orange)
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasKey
                                        ? Icons.check_circle_outline
                                        : Icons.warning_amber_rounded,
                                    size: 13,
                                    color: hasKey
                                        ? AppColors.primaryGreen
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hasKey
                                        ? 'Configured (သိမ်းထားပြီး)'
                                        : 'Not Set (မထည့်ရသေး)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: hasKey
                                          ? AppColors.primaryGreen
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'API Key အား စက်တွင်း Encrypted Storage (Windows Credential / Android Encrypted Storage) တွင် လုံခြုံစွာသိမ်းဆည်းပါသည်။',
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
                            prefixIcon: const Icon(Icons.key, size: 18),
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
                              Expanded(
                                child: TextButton.icon(
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
                                    'ဖျက်မည်',
                                    style: TextStyle(color: Colors.red),
                                  ),
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

                // AI Model Selection Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            const Text(
                              'AI Model Selection',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check,
                                    size: 13,
                                    color: AppColors.primaryGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Active: $activeModel',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'စာရင်းရေးသွင်းရာတွင် အသုံးပြုလိုသော Gemini Model ဗားရှင်းကို ရွေးချယ်နိုင်ပါသည်။',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 14),

                        DropdownButtonFormField<String>(
                          key: ValueKey(activeModel),
                          initialValue: activeModel,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Selected Gemini Model',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          items: dropdownItems,
                          onChanged: (val) {
                            if (val != null) {
                              _saveModel(val);
                            }
                          },
                        ),

                        const SizedBox(height: 12),

                        // Active Model details info box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      activeModelInfo['badge'] ?? 'Model',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      activeModelInfo['title'] ?? activeModel,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                activeModelInfo['desc'] ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _saveModel(_selectedModel),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text(
                                'Save Model (မော်ဒယ် သိမ်းမည်)',
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
          );
        },
      ),
    );
  }
}
