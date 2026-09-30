import 'package:accountingmyanmar/core/bloc_utils/bloc_status.dart';
import 'package:accountingmyanmar/core/secure_storage_service.dart';
import 'package:accountingmyanmar/data/models/account.dart';
import 'package:accountingmyanmar/data/models/ai_message.dart';
import 'package:accountingmyanmar/data/models/journal_entry.dart';
import 'package:accountingmyanmar/data/models/print_config.dart';
import 'package:accountingmyanmar/data/models/user_profile.dart';
import 'package:accountingmyanmar/data/repositories/account/account_repository_interface.dart';
import 'package:accountingmyanmar/data/repositories/ai/ai_assistant_repository_interface.dart';
import 'package:accountingmyanmar/data/repositories/journal/journal_entry_repository_interface.dart';
import 'package:accountingmyanmar/data/repositories/settings/settings_repository_interface.dart';
import 'package:accountingmyanmar/logic/ai/ai_assistant_cubit.dart';
import 'package:accountingmyanmar/logic/settings/settings_cubit.dart';
import 'package:accountingmyanmar/ui/screens/ai_assistant/ai_assistant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAiAssistantRepository implements AiAssistantRepositoryInterface {
  String? apiKey;
  String currentModel = 'gemini-3.8-flash';
  List<AiMessage>? lastHistory;
  String? lastModelUsed;

  @override
  Future<String?> getApiKey() async => apiKey;

  @override
  Future<void> saveApiKey(String key) async {
    apiKey = key;
  }

  @override
  Future<void> removeApiKey() async {
    apiKey = null;
  }

  @override
  Future<String> getSelectedModel() async => currentModel;

  @override
  Future<void> saveSelectedModel(String model) async {
    currentModel = model;
  }

  @override
  Future<String> sendMessage({
    required List<AiMessage> history,
    String? model,
  }) async {
    lastHistory = history;
    lastModelUsed = model ?? currentModel;
    return '### Sample Response\n\n- Point 1\n- Point 2\n\n**Debit**: Cash 1,000';
  }

  @override
  Future<bool> testApiKey(String key) async => true;
}

class FakeSettingsRepository implements SettingsRepositoryInterface {
  final Map<String, String> _settings = {};

  @override
  Future<void> clearAllData() async {}

  @override
  Future<void> clearSampleData() async {}

  @override
  Future<List<int>> exportDatabaseBytes() async => [];

  @override
  Future<int> getDatabaseSizeInBytes() async => 1024;

  @override
  Future<String> getDatabasePath() async => '/mock/path/db.sqlite';

  @override
  Future<String> getDefaultPrinter() async => 'Default Printer';

  @override
  Future<PrintConfig> getPrintConfig() async => const PrintConfig();

  @override
  Future<String?> getSetting(String key) async => _settings[key];

  @override
  Future<UserProfile> getUserProfile() async => const UserProfile();

  @override
  Future<bool> hasData() async => true;

  @override
  Future<void> importDatabaseFromBytes(List<int> bytes) async {}

  @override
  Future<bool> isSampleDataLoaded() async => false;

  @override
  Future<void> loadSampleData() async {}

  @override
  Future<void> setDefaultPrinter(String printerName) async {}

  @override
  Future<void> setSetting(String key, String value) async {
    _settings[key] = value;
  }

  @override
  Future<void> savePrintConfig(PrintConfig config) async {}

  @override
  Future<void> saveUserProfile(UserProfile profile) async {}
}

class FakeAccountRepository implements AccountRepositoryInterface {
  @override
  Future<List<Account>> getAccounts() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeJournalRepository implements JournalEntryRepositoryInterface {
  @override
  Future<List<JournalEntry>> getJournalEntries() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AI Model Configuration & Selection Tests', () {
    test('SettingsCubit updates and stores selected AI model', () async {
      final settingsRepo = FakeSettingsRepository();
      final accountRepo = FakeAccountRepository();
      final journalRepo = FakeJournalRepository();

      final cubit = SettingsCubit(
        settingsRepository: settingsRepo,
        accountRepository: accountRepo,
        journalRepository: journalRepo,
        secureStorage: SecureStorageService.inMemory(),
      );

      await cubit.init();
      expect(cubit.state.selectedAiModel, 'gemini-3.8-flash');

      await cubit.selectAiModel('gemini-3.5-flash-lite');
      expect(cubit.state.selectedAiModel, 'gemini-3.5-flash-lite');
      expect(
        await settingsRepo.getSetting('selected_ai_model'),
        'gemini-3.5-flash-lite',
      );
    });

    test(
      'AiAssistantCubit changes model and sends with selected model',
      () async {
        final repo = FakeAiAssistantRepository();
        repo.apiKey = 'fake_key';

        final cubit = AiAssistantCubit(repo);
        await cubit.init();

        expect(cubit.state.selectedModel, 'gemini-3.8-flash');

        // Change model
        await cubit.setModel('gemini-3.7-flash');
        expect(cubit.state.selectedModel, 'gemini-3.7-flash');
        expect(repo.currentModel, 'gemini-3.7-flash');

        // Submit prompt
        await cubit.submitPrompt('Double-entry test prompt');
        expect(repo.lastModelUsed, 'gemini-3.7-flash');
        expect(cubit.state.status, BlocStatus.success);
        expect(
          cubit.state.messages.length,
          3,
        ); // initial welcome + user + model reply
      },
    );

    test(
      'AiAssistantCubit retryLastPrompt resubmits user prompt correctly',
      () async {
        final repo = FakeAiAssistantRepository();
        repo.apiKey = 'fake_key';

        final cubit = AiAssistantCubit(repo);
        await cubit.init();

        await cubit.submitPrompt('What is debit?');
        expect(cubit.state.messages.length, 3);
        expect(cubit.state.messages[1].text, 'What is debit?');

        // Change model and retry
        await cubit.setModel('gemini-3.5-flash');
        await cubit.retryLastPrompt();

        expect(repo.lastModelUsed, 'gemini-3.5-flash');
        expect(cubit.state.messages.length, 3);
        expect(cubit.state.messages[1].text, 'What is debit?');
      },
    );
  });

  group('AI Assistant UI & Markdown Formatting Tests', () {
    testWidgets('Renders MarkdownBody and Copy button for AI response', (
      tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            return null;
          }
          return null;
        },
      );

      final repo = FakeAiAssistantRepository();
      repo.apiKey = 'fake_key';
      final aiCubit = AiAssistantCubit(repo);
      await aiCubit.init();

      final settingsRepo = FakeSettingsRepository();
      final accountRepo = FakeAccountRepository();
      final journalRepo = FakeJournalRepository();
      final settingsCubit = SettingsCubit(
        settingsRepository: settingsRepo,
        accountRepository: accountRepo,
        journalRepository: journalRepo,
        secureStorage: SecureStorageService.inMemory(),
      );
      await settingsCubit.init();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AiAssistantCubit>.value(value: aiCubit),
            BlocProvider<SettingsCubit>.value(value: settingsCubit),
          ],
          child: const MaterialApp(home: AiAssistantScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify initial welcome message uses MarkdownBody
      expect(find.byType(MarkdownBody), findsOneWidget);

      // Verify Copy button is present
      expect(find.text('Copy'), findsOneWidget);

      // Verify model badge is displayed in AppBar
      expect(find.text('Model: gemini-3.8-flash'), findsOneWidget);

      // Verify Quick Suggestions are visible
      expect(find.text('Double-entry စာရင်းရေးနည်း ဥပမာပြပါ'), findsOneWidget);

      // Tap Copy button
      await tester.tap(find.text('Copy'));
      await tester.pump();
      expect(find.text('Copied'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
