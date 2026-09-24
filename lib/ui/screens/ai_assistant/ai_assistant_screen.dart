import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc_utils/bloc_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/ai/ai_assistant_cubit.dart';
import '../../../logic/ai/ai_assistant_state.dart';
import '../../../logic/settings/settings_cubit.dart';
import 'add_api_key_dialog.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showApiKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AddApiKeyDialog(
        onSave: (key) async {
          await context.read<AiAssistantCubit>().saveApiKeyAndResume(key);
          if (context.mounted) {
            await context.read<SettingsCubit>().saveGeminiApiKey(key);
          }
        },
        onCancel: () {
          context.read<AiAssistantCubit>().cancelApiKeyPrompt();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<AiAssistantCubit, AiAssistantState>(
      listener: (context, state) {
        if (state.requiresApiKeyPrompt) {
          _showApiKeyDialog(context);
        }
        _scrollToBottom();
      },
      builder: (context, state) {
        final messages = state.messages;
        final isLoading = state.status == BlocStatus.loading;

        return Scaffold(
          appBar: AppBar(
            title: Text('AI စာရင်းကိုင် လက်ထောက် (AI Assistant)'),
            actions: [
              IconButton(
                tooltip: 'API Key ပြင်ဆင်ရန်',
                icon: Icon(
                  Icons.key,
                  color: state.hasApiKey
                      ? AppColors.primaryGreen
                      : Colors.orange,
                  size: 20,
                ),
                onPressed: () => _showApiKeyDialog(context),
              ),
              IconButton(
                tooltip: 'စကားဝိုင်း အသစ်စတင်ရန် (Clear)',
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () =>
                    context.read<AiAssistantCubit>().clearConversation(),
              ),
            ],
          ),
          body: Column(
            children: [
              // API Key Warning banner if not set
              if (!state.hasApiKey)
                InkWell(
                  onTap: () => _showApiKeyDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.orange.withOpacity(0.15),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gemini API Key မထည့်ရသေးပါ။ နှိပ်၍ API Key ထည့်သွင်းပါ။',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.orange,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

              // Chat Messages List
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.sizeOf(context).width * 0.05,
                    vertical: 16,
                  ),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == messages.length && isLoading) {
                      return _buildLoadingBubble(isDark);
                    }

                    final msg = messages[index];
                    return _buildMessageBubble(msg, isDark);
                  },
                ),
              ),

              // Suggestion chips (only when messages length is small)
              if (messages.length <= 2)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.sizeOf(context).width * 0.05,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      _buildSuggestionChip('Double-entry စာရင်းရေးနည်း'),
                      _buildSuggestionChip('COGS ရောင်းကုန်စရိတ်ဆိုတာဘာလဲ?'),
                      _buildSuggestionChip('Balance Sheet ညီအောင်စစ်နည်း'),
                      _buildSuggestionChip('ကြိုပေးစရိတ် Amortize လုပ်နည်း'),
                    ],
                  ),
                ),

              // Bottom Input Bar
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width * 0.05,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'စာရင်းရေးသွင်းပုံ၊ Debit/Credit နှင့် ပတ်သက်ပြီး မေးပါ...',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                        ),
                        onPressed: isLoading ? null : _sendMessage,
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    context.read<AiAssistantCubit>().submitPrompt(text);
  }

  Widget _buildSuggestionChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        onPressed: () {
          _inputController.text = label;
          _sendMessage();
        },
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool isDark) {
    final isUser = msg.isUser as bool;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.primaryGreen
                : (isDark ? const Color(0xFF14241B) : const Color(0xFFEBF3ED)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isUser ? 14 : 2),
              bottomRight: Radius.circular(isUser ? 2 : 14),
            ),
            border: isUser
                ? null
                : Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
          ),
          child: SelectableText(
            msg.text,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isUser
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14241B) : const Color(0xFFEBF3ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryGreen,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'စဉ်းစားနေပါသည်... (Thinking...)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
