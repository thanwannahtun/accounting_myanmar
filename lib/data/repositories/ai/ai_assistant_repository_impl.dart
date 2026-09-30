import '../../../core/secure_storage_service.dart';
import '../../models/ai_message.dart';
import '../../services/ai/gemini_ai_service.dart';
import 'ai_assistant_repository_interface.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepositoryInterface {
  final GeminiAiService _aiService;
  final SecureStorageService _secureStorage;

  static const String _geminiApiKeyStorageKey = 'gemini_api_key_secure_storage';
  static const String _geminiModelStorageKey = 'selected_gemini_model';
  static const String defaultModel = 'gemini-3.8-flash';

  AiAssistantRepositoryImpl({
    GeminiAiService? aiService,
    SecureStorageService? secureStorage,
  }) : _aiService = aiService ?? GeminiAiService(),
       _secureStorage = secureStorage ?? SecureStorageService.instance;

  @override
  Future<String?> getApiKey() async {
    return _secureStorage.read(_geminiApiKeyStorageKey);
  }

  @override
  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(_geminiApiKeyStorageKey, apiKey.trim());
  }

  @override
  Future<void> removeApiKey() async {
    await _secureStorage.delete(_geminiApiKeyStorageKey);
  }

  @override
  Future<String> getSelectedModel() async {
    final model = await _secureStorage.read(_geminiModelStorageKey);
    if (model != null && model.trim().isNotEmpty) {
      return model.trim();
    }
    return defaultModel;
  }

  @override
  Future<void> saveSelectedModel(String model) async {
    final clean = model.trim();
    if (clean.isNotEmpty) {
      await _secureStorage.write(_geminiModelStorageKey, clean);
    }
  }

  @override
  Future<String> sendMessage({
    required List<AiMessage> history,
    String? model,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('NO_API_KEY');
    }
    final activeModel = (model != null && model.trim().isNotEmpty)
        ? model.trim()
        : await getSelectedModel();

    return _aiService.sendMessage(
      apiKey: apiKey,
      history: history,
      model: activeModel,
    );
  }

  @override
  Future<bool> testApiKey(String apiKey) {
    return _aiService.testApiKey(apiKey);
  }
}
