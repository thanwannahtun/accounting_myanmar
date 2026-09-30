import 'package:equatable/equatable.dart';

import '../../core/bloc_utils/bloc_status.dart';
import '../../data/models/ai_message.dart';

class AiAssistantState extends Equatable {
  final BlocStatus status;
  final List<AiMessage> messages;
  final bool hasApiKey;
  final String? apiKey;
  final String selectedModel;
  final bool requiresApiKeyPrompt;
  final String? pendingPrompt;
  final String? errorMessage;

  const AiAssistantState({
    this.status = BlocStatus.initial,
    this.messages = const [],
    this.hasApiKey = false,
    this.apiKey,
    this.selectedModel = 'gemini-3.8-flash',
    this.requiresApiKeyPrompt = false,
    this.pendingPrompt,
    this.errorMessage,
  });

  AiAssistantState copyWith({
    BlocStatus? status,
    List<AiMessage>? messages,
    bool? hasApiKey,
    String? apiKey,
    String? selectedModel,
    bool? requiresApiKeyPrompt,
    String? pendingPrompt,
    String? errorMessage,
  }) {
    return AiAssistantState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      requiresApiKeyPrompt: requiresApiKeyPrompt ?? this.requiresApiKeyPrompt,
      pendingPrompt: pendingPrompt ?? this.pendingPrompt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    messages,
    hasApiKey,
    apiKey,
    selectedModel,
    requiresApiKeyPrompt,
    pendingPrompt,
    errorMessage,
  ];
}
