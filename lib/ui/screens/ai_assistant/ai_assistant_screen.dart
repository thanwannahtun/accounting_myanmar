import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/bloc_utils/bloc_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/ai_message.dart';
import '../../../logic/ai/ai_assistant_cubit.dart';
import '../../../logic/ai/ai_assistant_state.dart';
import '../../../logic/settings/settings_cubit.dart';
import '../settings/screens/ai_settings_screen.dart';
import 'add_api_key_dialog.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  bool _showScrollToBottom = false;
  int? _copiedIndex;
  Timer? _copyResetTimer;

  static const List<String> _quickSuggestions = [
    'Double-entry စာရင်းရေးနည်း ဥပမာပြပါ',
    'COGS ရောင်းကုန်စရိတ် တွက်ချက်ပုံ',
    'Debit နှင့် Credit အခြေခံသဘောတရား',
    'Balance Sheet မညီပါက မည်သို့စစ်ဆေးရမည်နည်း?',
    'ကြိုတင်ပေးစရိတ် (Prepaid Expense) ရေးသွင်းပုံ',
    'ပုံသေပိုင်ပစ္စည်း တန်ဖိုးလျော့ (Depreciation) တွက်နည်း',
    'ကုန်ရောင်းဝင်ငွေနှင့် အခွန်စာရင်း ရေးသွင်းပုံ',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final isFarFromBottom = (maxScroll - currentScroll) > 200;

    if (isFarFromBottom != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = isFarFromBottom;
      });
    }
  }

  @override
  void dispose() {
    _copyResetTimer?.cancel();
    _inputController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _inputFocusNode.dispose();
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

  void _copyToClipboard(String text, int index) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() {
      _copiedIndex = index;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('စာသားများကို ကူးယူပြီးပါပြီ (Copied to clipboard)'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    _copyResetTimer?.cancel();
    _copyResetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _copiedIndex == index) {
        setState(() {
          _copiedIndex = null;
        });
      }
    });
  }

  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text(
              'စကားဝိုင်း ရှင်းလင်းမည်လား?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'လက်ရှိ AI စကားဝိုင်းမှတ်တမ်း အားလုံးကို ရှင်းလင်းပစ်လိုပါသလား? ရှင်းလင်းပြီးပါက ပြန်လည်ရယူ၍ မရနိုင်ပါ။',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('မရှင်းလင်းပါ (Cancel)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AiAssistantCubit>().clearConversation();
            },
            child: const Text('ရှင်းလင်းမည် (Clear)'),
          ),
        ],
      ),
    );
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

  void _sendMessage([String? textToSend]) {
    final text = (textToSend ?? _inputController.text).trim();
    if (text.isEmpty) return;
    _inputController.clear();
    context.read<AiAssistantCubit>().submitPrompt(text);
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
        final activeModel = state.selectedModel;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AI စာရင်းကိုင် လက်ထောက်',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Model: $activeModel',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              // Active Model quick chip / button
              Tooltip(
                message:
                    'AI Model: $activeModel (နှိပ်၍ ဆက်တင်များ ပြင်ဆင်ရန်)',
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiSettingsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.tune,
                          size: 14,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            activeModel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // API Key status button
              IconButton(
                tooltip: state.hasApiKey
                    ? 'API Key သိမ်းဆည်းထားပြီး (နှိပ်၍ ပြင်ဆင်ရန်)'
                    : 'API Key မထည့်ရသေးပါ',
                icon: Icon(
                  Icons.key,
                  color: state.hasApiKey
                      ? AppColors.primaryGreen
                      : Colors.orange,
                  size: 20,
                ),
                onPressed: () => _showApiKeyDialog(context),
              ),

              // Clear conversation button
              IconButton(
                tooltip: 'စကားဝိုင်း ရှင်းလင်းရန် (Clear)',
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                onPressed: messages.length <= 1
                    ? null
                    : () => _showClearConfirmationDialog(context),
              ),
            ],
          ),
          floatingActionButton: _showScrollToBottom
              ? FloatingActionButton.small(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  tooltip: 'အောက်ဆုံးသို့ သွားရန်',
                  onPressed: _scrollToBottom,
                  child: const Icon(Icons.arrow_downward, size: 18),
                )
              : null,
          body: Column(
            children: [
              // API Key Warning banner if not set
              if (!state.hasApiKey)
                InkWell(
                  onTap: () => _showApiKeyDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    color: Colors.orange.withValues(alpha: 0.15),
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
                    horizontal: MediaQuery.sizeOf(context).width * 0.04,
                    vertical: 16,
                  ),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    if (index == messages.length && isLoading) {
                      return _buildLoadingBubble(isDark);
                    }

                    final msg = messages[index];
                    final isLastModelMsg =
                        !msg.isUser &&
                        (index == messages.length - 1 ||
                            (isLoading && index == messages.length - 1));

                    return _buildMessageItem(
                      msg: msg,
                      index: index,
                      isDark: isDark,
                      isLastModelMsg: isLastModelMsg,
                      isLoading: isLoading,
                    );
                  },
                ),
              ),

              // Quick Suggestion Chips (when messages are few or user is exploring)
              if (messages.length <= 3 && !isLoading)
                Container(
                  height: 44,
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.sizeOf(context).width * 0.04,
                    ),
                    itemCount: _quickSuggestions.length,
                    itemBuilder: (context, i) {
                      final suggestion = _quickSuggestions[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          avatar: const Icon(
                            Icons.auto_awesome,
                            size: 13,
                            color: AppColors.primaryGreen,
                          ),
                          label: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                          onPressed: () {
                            _inputController.text = suggestion;
                            _sendMessage(suggestion);
                          },
                        ),
                      );
                    },
                  ),
                ),

              // Bottom Input Bar
              _buildInputBar(isDark, isLoading),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar(bool isDark, bool isLoading) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width * 0.04,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.enter): () {
                    if (!isLoading) _sendMessage();
                  },
                },
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'စာရင်းရေးသွင်းပုံ၊ Debit/Credit နှင့် ပတ်သက်ပြီး မေးပါ... (Enter နှိပ်၍ ပေးပို့နိုင်ပါသည်)',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  disabledBackgroundColor: AppColors.primaryGreen.withValues(
                    alpha: 0.4,
                  ),
                ),
                onPressed: isLoading ? null : () => _sendMessage(),
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem({
    required AiMessage msg,
    required int index,
    required bool isDark,
    required bool isLastModelMsg,
    required bool isLoading,
  }) {
    final isUser = msg.isUser;
    final formattedTime = DateFormat('hh:mm a').format(msg.timestamp);
    final isCopied = _copiedIndex == index;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width > 800
              ? 720
              : MediaQuery.of(context).size.width * 0.88,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Header: Role icon, name, timestamp
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUser) ...[
                    const Icon(
                      Icons.smart_toy_outlined,
                      size: 15,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'AI Assistant',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'သင် (You)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),

            // Bubble body
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryGreen
                    : (isDark
                          ? const Color(0xFF14241B)
                          : const Color(0xFFF4F9F5)),
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
                            : AppColors.primaryGreen.withValues(alpha: 0.15),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: isUser
                  ? SelectableText(
                      msg.text,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    )
                  : _buildFormattedMarkdown(msg.text, isDark),
            ),

            // Action footer for Model messages (Copy, Regenerate)
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Copy button
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => _copyToClipboard(msg.text, index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCopied ? Icons.check : Icons.copy_rounded,
                              size: 13,
                              color: isCopied
                                  ? AppColors.primaryGreen
                                  : (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600]),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCopied ? 'Copied' : 'Copy',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCopied
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCopied
                                    ? AppColors.primaryGreen
                                    : (isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Regenerate / Retry button (on latest model response)
                    if (isLastModelMsg) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: isLoading
                            ? null
                            : () => context
                                  .read<AiAssistantCubit>()
                                  .retryLastPrompt(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Regenerate',
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
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedMarkdown(String text, bool isDark) {
    final theme = Theme.of(context);

    return MarkdownBody(
      data: text,
      selectable: true,
      onTapLink: (linkText, href, title) {
        if (href != null) {
          final uri = Uri.tryParse(href);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: TextStyle(
          fontFamily: 'Pyidaungsu',
          fontSize: 13.5,
          height: 1.6,
          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
        ),
        h1: const TextStyle(
          fontFamily: 'Pyidaungsu',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryGreen,
          height: 1.4,
        ),
        h2: TextStyle(
          fontFamily: 'Pyidaungsu',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          height: 1.4,
        ),
        h3: TextStyle(
          fontFamily: 'Pyidaungsu',
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF86EFAC) : AppColors.primaryGreen,
          height: 1.35,
        ),
        h4: TextStyle(
          fontFamily: 'Pyidaungsu',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey[200] : Colors.grey[800],
        ),
        strong: const TextStyle(fontWeight: FontWeight.bold),
        em: const TextStyle(fontStyle: FontStyle.italic),
        listBullet: const TextStyle(
          fontFamily: 'Pyidaungsu',
          fontSize: 13.5,
          color: AppColors.primaryGreen,
          fontWeight: FontWeight.bold,
        ),
        blockquote: TextStyle(
          fontFamily: 'Pyidaungsu',
          fontSize: 13,
          height: 1.5,
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
        blockquoteDecoration: BoxDecoration(
          color: isDark
              ? AppColors.primaryGreen.withValues(alpha: 0.12)
              : AppColors.primaryGreen.withValues(alpha: 0.06),
          border: const Border(
            left: BorderSide(color: AppColors.primaryGreen, width: 3),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
          backgroundColor: isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFE2E8F0),
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B131E) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        tableBorder: TableBorder.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
          borderRadius: BorderRadius.circular(6),
        ),
        tableHead: TextStyle(
          fontFamily: 'Pyidaungsu',
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        tableHeadCellsDecoration: BoxDecoration(
          color: isDark
              ? AppColors.primaryGreen.withValues(alpha: 0.18)
              : AppColors.primaryGreen.withValues(alpha: 0.08),
        ),
        tableBody: const TextStyle(
          fontFamily: 'Pyidaungsu',
          fontSize: 12.5,
          height: 1.4,
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
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
          color: isDark ? const Color(0xFF14241B) : const Color(0xFFF4F9F5),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
