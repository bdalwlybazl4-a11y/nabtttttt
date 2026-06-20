import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/health_News_Service.dart';

class NewsDetailScreen extends StatelessWidget {
  final HealthNewsItem news;

  const NewsDetailScreen({super.key, required this.news});

  /// فحص إن كان النص مفيدًا فعلاً وليس اختصارات أو تواريخ
  bool _isValidContent(String? text) {
    if (text == null || text.trim().isEmpty) return false;

    final cleaned = text.trim().toLowerCase();
    return cleaned.length > 50 &&
        !cleaned.startsWith('•') &&
        !cleaned.contains('… [+') &&
        !cleaned.contains('published') &&
        !cleaned.contains('نشرت') &&
        !RegExp(r'^\d{1,2}/\d{1,2}/\d{2,4}$').hasMatch(cleaned);
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentToShow = _isValidContent(news.content)
        ? news.content
        : (_isValidContent(news.description) ? news.description : null);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          backgroundColor: isDarkMode? Colors.grey[900]: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 2,
          title: Text(news.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  news.imageUrl,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 200,
                    child: Center(child: Icon(Icons.broken_image, size: 60)),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              news.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              news.source,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (contentToShow != null)
              Text(
                contentToShow,
                style: Theme.of(context).textTheme.bodyLarge,
              )
            else
              const Text(
                'لا يوجد محتوى مفيد متاح. يمكنك قراءة المزيد من المصدر.',
                style: TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),
            if (news.url.isNotEmpty)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _launchURL(context, news.url),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('قراءة من المصدر'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
