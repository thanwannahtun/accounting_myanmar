import 'package:equatable/equatable.dart';

class AiMessage extends Equatable {
  final String role; // 'user' or 'model'
  final String text;
  final DateTime timestamp;

  const AiMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  bool get isUser => role == 'user';

  @override
  List<Object?> get props => [role, text, timestamp];
}
