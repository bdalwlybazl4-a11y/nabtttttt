import 'dart:convert';
import 'package:http/http.dart' as http;

class HealthNewsItem {
  final String title;
  final String description;
  final String content;
  final String source;
  final String imageUrl;
  final String url;

  HealthNewsItem({
    required this.title,
    required this.description,
    required this.content,
    required this.source,
    required this.imageUrl,
    required this.url,
  });

  factory HealthNewsItem.fromJson(Map<String, dynamic> json) {
    return HealthNewsItem(
      title: json['title'] ?? 'بدون عنوان',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      source: json['source']['name'] ?? 'مصدر غير معروف',
      imageUrl: json['urlToImage'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class HealthNewsService {
  static const String _apiKey = String.fromEnvironment('NEWS_API_KEY');
  static const String _bundledApiKey = '549d849192e84b2d9c96d5e29f8ff3c5';
  static const String _baseUrl = 'https://newsapi.org/v2/everything';

  static Future<List<HealthNewsItem>> fetchNews({required String query}) async {
    final apiKey = _apiKey.trim().isNotEmpty ? _apiKey.trim() : _bundledApiKey;

    if (apiKey.isEmpty) {
      print('NEWS_API_KEY غير مضبوط، سيتم تخطي جلب الأخبار الخارجية.');
      return [];
    }
    final url = Uri.parse('$_baseUrl?q=$query&language=ar&sortBy=publishedAt&pageSize=10&apiKey=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List articles = data['articles'];

        return articles
            .map((article) => HealthNewsItem.fromJson(article))
            .toList();
      } else {
        print('فشل في جلب الأخبار: ${response.statusCode}');
        if (response.statusCode == 429) {
          print('لقد تجاوزت الحد المسموح به لعدد الطلبات اليومي.');
          return [];
        }

        return [];
      }
    } catch (e) {
      print('حدث خطأ: $e');
      return [];
    }
  }

  // ✅ عدلنا هنا استعلامات لجلب نتائج مثل دالتك التي تعمل
// في HealthNewsService:
  static Future<List<HealthNewsItem>> fetchChronicDiseaseTips() =>
      fetchNews(query: 'السكري OR ضغط الدم OR الأمراض المزمنة');

  static Future<List<HealthNewsItem>> fetchNutritionTips() =>
      fetchNews(query: 'نصائح غذائية OR تغذية صحية OR غذاء مفيد');

  static Future<List<HealthNewsItem>> fetchPreventionTips() =>
      fetchNews(query: 'الوقاية من الأمراض OR نصائح طبية OR التعقيم');

  static Future<List<HealthNewsItem>> fetchMedicalNews() =>
      fetchNews(query: 'الصحة OR الطب OR الوقاية OR العلاج'); // ← نفس استعلامك الأصلي الناجح
}

// import 'package:http/http.dart' as http;
// import 'package:webfeed/webfeed.dart';
//
// class HealthNewsItem {
//   final String title;
//   final String description;
//   final String content;
//   final String source;
//   final String imageUrl;
//   final String url;
//
//   HealthNewsItem({
//     required this.title,
//     required this.description,
//     required this.content,
//     required this.source,
//     required this.imageUrl,
//     required this.url,
//   });
//
//   factory HealthNewsItem.fromRssItem(RssItem item) {
//     return HealthNewsItem(
//       title: item.title ?? 'بدون عنوان',
//       description: item.description ?? '',
//       content: item.content?.value ?? '',
//       source: item.source?.url ?? 'مصدر غير معروف',
//       imageUrl: item.enclosure?.url ?? '', // غالباً الصورة تكون في enclosure
//       url: item.link ?? '',
//     );
//   }
// }
//
// class HealthNewsService {
//   // استخدم أي خلاصة RSS عربية عن الصحة هنا (مثال: Healthline بالعربية أو غيره)
//   static const String _rssFeedUrl = 'https://www.aljazeera.net/aljazeerarss/all.rss'; // مثال، يمكنك استبدالها برابط خلاصة مناسبة
//
//   static Future<List<HealthNewsItem>> fetchNews() async {
//     try {
//       final response = await http.get(Uri.parse(_rssFeedUrl));
//       if (response.statusCode == 200) {
//         final feed = RssFeed.parse(response.body);
//         final items = feed.items ?? [];
//         return items.map((item) => HealthNewsItem.fromRssItem(item)).toList();
//       } else {
//         print('فشل في جلب الأخبار: ${response.statusCode}');
//         return [];
//       }
//     } catch (e) {
//       print('حدث خطأ: $e');
//       return [];
//     }
//   }
// }
