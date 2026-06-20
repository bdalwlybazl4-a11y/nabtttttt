import 'package:dio/dio.dart';
import 'package:digl/firebase_options.dart';
import '../models/ai_chat_message.dart';
import '../models/medical_intake.dart';

class MedicalAiApiService {
  static const String _geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY');
  static const String _geminiApiKeyLower =
      String.fromEnvironment('gemini_api_key');
  static const String _medicalAiBaseUrl =
      String.fromEnvironment('MEDICAL_AI_BASE_URL');

  final Dio _dio;
  final String? baseUrl;
  final String? apiKey;

  MedicalAiApiService({
    Dio? dio,
    this.baseUrl = _medicalAiBaseUrl,
    String? apiKey,
  })  : apiKey = apiKey ?? _resolveDefaultApiKey(),
        _dio = dio ?? Dio();

  static String _resolveDefaultApiKey() {
    if (_geminiApiKey.trim().isNotEmpty) return _geminiApiKey.trim();
    if (_geminiApiKeyLower.trim().isNotEmpty) return _geminiApiKeyLower.trim();
    return '';
  }

  Future<String> sendMedicalMessage({
    required MedicalIntake intake,
    required List<AiChatMessage> history,
    required String message,
  }) async {
    final configuredUrl = (baseUrl ?? '').trim();

    if (configuredUrl.isNotEmpty) {
      final response = await _dio.post(
        configuredUrl,
        data: {
          'system': _systemPrompt,
          'intake': intake.toPrompt(),
          'message': message,
          'history': history.map((e) => e.toMap(firestore: false)).toList(),
        },
        options: Options(
          headers: {
            if ((apiKey ?? '').isNotEmpty) 'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      return (
          response.data['reply'] ??
              response.data['message'] ??
              response.data['choices']?[0]?['message']?['content'] ??
              ''
      ).toString();
    }

    final key = (apiKey ?? '').trim();

    if (key.isEmpty) {
      return 'لم يتم ضبط مفتاح الذكاء الاصطناعي بعد. شغّل التطبيق باستخدام --dart-define=GEMINI_API_KEY=YOUR_KEY لتفعيل الردود. لن يتم إرسال رسالتك لأي خدمة خارجية حتى يتم ضبط المفتاح.';
    }

    final geminiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key';

    Response<dynamic> response;
    try {
      response = await _dio.post(
        geminiUrl,
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                  '$_systemPrompt\n\n'
                      'بيانات الحالة:\n${intake.toPrompt()}\n\n'
                      'سجل مختصر:\n${history.map((e) => '${e.isUser ? 'المستخدم' : 'المساعد'}: ${e.content}').join('\n')}\n\n'
                      'سؤال المستخدم:\n$message',
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'maxOutputTokens': 900,
          },
        },
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return 'تعذر الاتصال بخدمة الذكاء الاصطناعي لأن مفتاح Gemini غير مقبول أو لا يملك صلاحية Generative Language API. تأكد من تشغيل التطبيق باستخدام --dart-define=GEMINI_API_KEY=YOUR_REAL_GEMINI_KEY بدون مسافات، ومن تفعيل Gemini API لهذا المفتاح.';
      }
      if (statusCode == 400) {
        return 'تعذر إرسال الطلب إلى Gemini. تحقق من أن مفتاح API صحيح وأن خدمة Gemini مفعلة في Google AI Studio أو Google Cloud.';
      }
      return 'تعذر الاتصال بخدمة الذكاء الاصطناعي حالياً. حاول مرة أخرى لاحقاً.';
    }

    final reply = (
        response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            ''
    ).toString().trim();

    if (reply.isEmpty) {
      return 'وصل الطلب إلى خدمة الذكاء الاصطناعي لكن لم يصل رد مفهوم. حاول إعادة صياغة السؤال.';
    }

    return reply;
  }

  String get _systemPrompt =>
      'أنت مساعد طبي عربي داخل تطبيق نبض. قدم إجابة منظمة وواضحة، نبه للحالات الطارئة، ولا تقدم تشخيصاً نهائياً أو وصفة دوائية خطرة.';
}
