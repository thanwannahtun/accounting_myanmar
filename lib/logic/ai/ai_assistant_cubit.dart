import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc_utils/bloc_status.dart';
import '../../data/models/ai_message.dart';
import '../../data/repositories/ai/ai_assistant_repository_interface.dart';
import 'ai_assistant_state.dart';

class AiAssistantCubit extends Cubit<AiAssistantState> {
  final AiAssistantRepositoryInterface _repository;

  static const String _welcomeMessage =
      'မင်္ဂလာပါ။ ကျွန်တော်ကတော့ AI စာရင်းကိုင် အကူအညီပေးရေး လက်ထောက် (AI Accounting Assistant) ဖြစ်ပါတယ်။ '
      'စာရင်းရေးသွင်းပုံများ၊ Double Entry စာရင်းစစ်နည်းများ၊ Debit/Credit သဘောတရားများနှင့် ဘဏ္ဍာရေးအစီရင်ခံစာများအကြောင်း သိလိုသမျှကို မြန်မာလို (သို့မဟုတ်) အင်္ဂလိပ်လို အသေးစိတ် မေးမြန်းနိုင်ပါတယ်။';

  AiAssistantCubit(this._repository) : super(const AiAssistantState());

  Future<void> init() async {
    final key = await _repository.getApiKey();
    final hasKey = key != null && key.trim().isNotEmpty;

    final initialMessages = [
      AiMessage(
        role: 'model',
        text: _welcomeMessage,
        timestamp: DateTime.now(),
      ),
    ];

    emit(state.copyWith(
      status: BlocStatus.initial,
      hasApiKey: hasKey,
      apiKey: key,
      messages: initialMessages,
      requiresApiKeyPrompt: false,
    ));
  }

  Future<void> submitPrompt(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || state.status == BlocStatus.loading) return;

    final key = await _repository.getApiKey();
    final hasKey = key != null && key.trim().isNotEmpty;

    if (!hasKey) {
      emit(state.copyWith(
        requiresApiKeyPrompt: true,
        pendingPrompt: prompt,
      ));
      return;
    }

    final userMessage = AiMessage(
      role: 'user',
      text: prompt,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<AiMessage>.from(state.messages)..add(userMessage);

    emit(state.copyWith(
      status: BlocStatus.loading,
      messages: updatedMessages,
      pendingPrompt: null,
      errorMessage: null,
    ));

    try {
      final replyText = await _repository.sendMessage(history: updatedMessages);
      final modelMessage = AiMessage(
        role: 'model',
        text: replyText,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        status: BlocStatus.success,
        messages: List<AiMessage>.from(updatedMessages)..add(modelMessage),
      ));
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: errorMsg,
        messages: List<AiMessage>.from(updatedMessages)
          ..add(
            AiMessage(
              role: 'model',
              text: 'တောင်းပန်ပါတယ်။ အခုချိန်တွင် ဖြေကြားပေးရန် အခက်အခဲရှိနေပါသည်။ ($errorMsg)',
              timestamp: DateTime.now(),
            ),
          ),
      ));
    }
  }

  Future<void> saveApiKeyAndResume(String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) return;

    await _repository.saveApiKey(cleanKey);
    final promptToRun = state.pendingPrompt;

    emit(state.copyWith(
      hasApiKey: true,
      apiKey: cleanKey,
      requiresApiKeyPrompt: false,
      pendingPrompt: null,
    ));

    if (promptToRun != null && promptToRun.isNotEmpty) {
      await submitPrompt(promptToRun);
    }
  }

  void cancelApiKeyPrompt() {
    emit(state.copyWith(
      requiresApiKeyPrompt: false,
      pendingPrompt: null,
    ));
  }

  Future<void> removeApiKey() async {
    await _repository.removeApiKey();
    emit(state.copyWith(
      hasApiKey: false,
      apiKey: null,
    ));
  }

  void clearConversation() {
    emit(state.copyWith(
      messages: [
        AiMessage(
          role: 'model',
          text: _welcomeMessage,
          timestamp: DateTime.now(),
        ),
      ],
      errorMessage: null,
    ));
  }
}
