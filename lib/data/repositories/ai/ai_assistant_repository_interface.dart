import '../../models/ai_message.dart';

abstract class AiAssistantRepositoryInterface {
  Future<String?> getApiKey();
  Future<void> saveApiKey(String apiKey);
  Future<void> removeApiKey();
  Future<String> getSelectedModel();
  Future<void> saveSelectedModel(String model);
  Future<String> sendMessage({
    required List<AiMessage> history,
    String? model,
  });
  Future<bool> testApiKey(String apiKey);
}
