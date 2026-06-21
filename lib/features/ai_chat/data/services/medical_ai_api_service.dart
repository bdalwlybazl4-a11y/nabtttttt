import 'dart:io';

import 'package:dio/dio.dart';

import '../models/ai_chat_message.dart';
import '../models/medical_intake.dart';

class MedicalAiApiService {
  static const String _geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY');
  static const String _geminiApiKeyLower =
      String.fromEnvironment('gemini_api_key');
  static const String _medicalAiBaseUrl =
      String.fromEnvironment('MEDICAL_AI_BASE_URL');
  static const String _geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  final Dio _dio;
  final String? baseUrl;
  final String? apiKey;
  final String model;

  MedicalAiApiService({
    Dio? dio,
    this.baseUrl = _medicalAiBaseUrl,
    String? apiKey,
    this.model = _geminiModel,
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
    final key = (apiKey ?? '').trim();

    _debug('Gemini Key Exists: ${key.isNotEmpty}');
    _debug('Gemini Key Length: ${key.length}');

    if (configuredUrl.isNotEmpty) {
      return _sendToCustomMedicalAiBackend(
        configuredUrl: configuredUrl,
        key: key,
        intake: intake,
        history: history,
        message: message,
      );
    }

    if (key.isEmpty) {
      return 'لم يتم ضبط مفتاح Gemini. شغّل التطبيق باستخدام --dart-define=GEMINI_API_KEY=YOUR_KEY فقط، ولا يحتاج الذكاء الاصطناعي إلى NEWS_API_KEY.';
    }

    final geminiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
    final payload = {
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text': 'بيانات الحالة:\n${intake.toPrompt()}\n\n'
                  'سجل مختصر:\n${history.map((e) => '${e.isUser ? 'المستخدم' : 'المساعد'}: ${e.content}').join('\n')}\n\n'
                  'سؤال المستخدم:\n$message',
            }
          ],
        }
      ],
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 900,
      },
    };

    try {
      _debug('Gemini Request URL: $geminiUrl');
      _debug('Gemini Request Model: $model');
      _debug('Gemini Request Body: $payload');

      final response = await _dio.post(
        geminiUrl,
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': key,
          },
        ),
      );

      _debug('Gemini Status Code: ${response.statusCode}');
      _debug('Gemini Response Body: ${response.data}');

      final reply = _extractGeminiReply(response.data);
      if (reply.isEmpty) {
        return 'وصل الطلب إلى Gemini لكن لم يصل رد نصي مفهوم. رد Google: ${response.data}';
      }
      return reply;
    } on DioException catch (e) {
      return _formatDioError(e, serviceName: 'Gemini');
    } on SocketException catch (e) {
      _debug('Gemini SocketException: $e');
      return 'تعذر الاتصال بالإنترنت أو بخوادم Gemini: ${e.message}';
    } catch (e) {
      _debug('Gemini Unknown Error: $e');
      return 'حدث خطأ غير متوقع أثناء الاتصال بـ Gemini: $e';
    }
  }

  Future<String> _sendToCustomMedicalAiBackend({
    required String configuredUrl,
    required String key,
    required MedicalIntake intake,
    required List<AiChatMessage> history,
    required String message,
  }) async {
    try {
      _debug('Medical AI Backend URL: $configuredUrl');
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
            'Content-Type': 'application/json',
            if (key.isNotEmpty) 'Authorization': 'Bearer $key',
          },
        ),
      );

      _debug('Medical AI Backend Status Code: ${response.statusCode}');
      _debug('Medical AI Backend Response Body: ${response.data}');

      return (response.data['reply'] ??
              response.data['message'] ??
              response.data['choices']?[0]?['message']?['content'] ??
              '')
          .toString();
    } on DioException catch (e) {
      return _formatDioError(e, serviceName: 'الخادم الطبي المخصص');
    } on SocketException catch (e) {
      _debug('Medical AI Backend SocketException: $e');
      return 'تعذر الاتصال بالإنترنت أو بالخادم الطبي المخصص: ${e.message}';
    }
  }

  String _extractGeminiReply(dynamic data) {
    if (data is! Map) return '';
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';
    final content = candidates.first['content'];
    if (content is! Map) return '';
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return '';
    return parts
        .map((part) => part is Map ? part['text'] : null)
        .whereType<String>()
        .join('\n')
        .trim();
  }

  String _formatDioError(DioException e, {required String serviceName}) {
    final statusCode = e.response?.statusCode;
    final responseBody = e.response?.data;
    final googleMessage = _extractApiErrorMessage(responseBody);
    final requestUrl = e.requestOptions.uri.toString();

    _debug('$serviceName Request URL: $requestUrl');
    _debug('$serviceName Status Code: $statusCode');
    _debug('$serviceName DioException Type: ${e.type}');
    _debug('$serviceName Error Response: $responseBody');
    _debug('$serviceName Error Message: ${e.message}');

    if (statusCode == 401 || statusCode == 403) {
      return _formatAuthenticationError(
        statusCode: statusCode,
        googleMessage: googleMessage,
        fallbackMessage: e.message,
      );
    }
    if (statusCode == 404) {
      return 'رابط أو نموذج Gemini غير موجود برمز 404. السبب الفعلي: ${googleMessage.isNotEmpty ? googleMessage : e.message}. النموذج الحالي: $model.';
    }
    if (statusCode == 429) {
      return 'تم تجاوز حد طلبات Gemini برمز 429. السبب الفعلي: ${googleMessage.isNotEmpty ? googleMessage : e.message}.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'خطأ من خوادم $serviceName برمز $statusCode. السبب الفعلي: ${googleMessage.isNotEmpty ? googleMessage : e.message}.';
    }
    if (statusCode == 400) {
      return 'رفضت Google تنسيق طلب Gemini برمز 400. السبب الفعلي: ${googleMessage.isNotEmpty ? googleMessage : e.message}.';
    }

    return 'تعذر الاتصال بـ $serviceName. السبب الفعلي: ${googleMessage.isNotEmpty ? googleMessage : e.message ?? e.type.name}.';
  }

  String _formatAuthenticationError({
    required int? statusCode,
    required String googleMessage,
    required String? fallbackMessage,
  }) {
    final actualMessage = googleMessage.isNotEmpty
        ? googleMessage
        : (fallbackMessage ?? 'لم ترسل Google تفاصيل إضافية.');

    return 'رفضت Google طلب Gemini برمز $statusCode. '
        'السبب الفعلي من Google: $actualMessage. '
        'هذا يعني أن المفتاح لم يُقبل كمفتاح Gemini صالح لهذا الطلب، وليس مشكلة Firebase أو NEWS_API_KEY. '
        'تأكد من إنشاء المفتاح من Google AI Studio كمفتاح Gemini API/Auth key أو من تقييد مفتاح Google Cloud القياسي على Generative Language API، '
        'ثم شغّل التطبيق هكذا: flutter run --dart-define=GEMINI_API_KEY=YOUR_REAL_GEMINI_KEY. '
        'إذا كان المفتاح من النوع القياسي وغير مقيّد فقد ترفضه Gemini API حالياً؛ أنشئ مفتاحاً جديداً من AI Studio أو أضف قيود API مناسبة.';
  }

  String _extractApiErrorMessage(dynamic data) {
    if (data is Map) {
      final error = data['error'];
      if (error is Map) {
        final code = error['code'];
        final status = error['status'];
        final message = error['message'];
        return [
          if (code != null) 'code=$code',
          if (status != null) 'status=$status',
          if (message != null) 'message=$message',
        ].join(' | ');
      }
      return data.toString();
    }
    return data?.toString() ?? '';
  }

  void _debug(String message) {
    // ignore: avoid_print
    print(message);
  }

  String get _systemPrompt =>
      'أنت مساعد طبي عربي داخل تطبيق نبض. قدم إجابة منظمة وواضحة، نبه للحالات الطارئة، ولا تقدم تشخيصاً نهائياً أو وصفة دوائية خطرة.';
}
