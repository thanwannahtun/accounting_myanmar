import 'package:dio/dio.dart';

import '../../models/ai_message.dart';

class GeminiAiService {
  final Dio _dio;

  GeminiAiService({Dio? dio}) : _dio = dio ?? Dio();

  static const String _defaultModel = 'gemini-3.8-flash';
  static const String _systemPrompt =
      'Act as an expert accountant and financial advisor specialized in Myanmar business accounting and international double-entry standards. '
      'Provide clear, accurate, practical answers regarding journal entries, debit/credit mechanisms, Chart of Accounts, P&L (Income Statement), '
      'Balance Sheet, cash flow, and tax considerations for Myanmar SMEs. '
      'You can answer in Burmese (Unicode) or English depending on user question language. '
      'Keep answers clean, professional, and well-structured with markdown headings, bullet points, and formulas where appropriate.'
      'Do not reference or do not give the example app names like Xero, QuickBooks that user might away from our app (only tell them if they explicitly tell you)'
      'Accounting Myanmar (The app that current user is using now) သည် မြန်မာနိုင်ငံရှိ စီးပွားရေးလုပ်ငန်းများ၊ စာရင်းကိုင်ပညာရှင်များနှင့် စာရင်းကိုင်ပညာကို အစပြုလေ့လာလိုသူများအတွက် နိုင်ငံတကာ စံချိန်မီ "နှစ်ဘက်သွင်း စာရင်းကိုင်စနစ် (Double-Entry Bookkeeping)" ဖြင့် အစအဆုံး တည်ဆောက်ထားသော ခေတ်မီ ဘဏ္ဍာရေး အက်ပလီကေးရှင်း ဖြစ်ပါသည်။';

  Future<String> sendMessage({
    required String apiKey,
    required List<AiMessage> history,
    String model = _defaultModel,
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw Exception('Gemini API Key is missing. Please provide a valid key.');
    }

    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$cleanKey';

    final contents = history.map((m) {
      return {
        'role': m.role == 'user' ? 'user' : 'model',
        'parts': [
          {'text': m.text},
        ],
      };
    }).toList();

    final payload = {
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt},
        ],
      },
      'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 2048},
    };

    try {
      final response = await _dio.post(
        url,
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['candidates'] != null &&
          (data['candidates'] as List).isNotEmpty) {
        final candidate = data['candidates'][0] as Map<String, dynamic>;
        final content = candidate['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text'] as String?;
          if (text != null && text.isNotEmpty) {
            return text;
          }
        }
      }
      return 'တောင်းပန်ပါတယ်။ ဖြေကြားချက်ရယူရာတွင် အခက်အခဲရှိနေပါသည်။ (No response text received from AI)';
    } on DioException catch (e) {
      final errMsg = e.response?.data?['error']?['message'] ?? e.message;
      throw Exception('Gemini API Error: $errMsg');
    } catch (e) {
      throw Exception('Network or parsing error: $e');
    }
  }

  Future<bool> testApiKey(String apiKey) async {
    try {
      await sendMessage(
        apiKey: apiKey,
        history: [
          AiMessage(
            role: 'user',
            text: 'Hello test',
            timestamp: DateTime.now(),
          ),
        ],
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
