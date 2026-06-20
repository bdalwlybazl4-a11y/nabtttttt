import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../services/health_News_Service.dart';
import 'all_HealthNewsScreen.dart';
import 'newsDetailScreen.dart';

class MedicalNewsWidget extends StatefulWidget {
  const MedicalNewsWidget({super.key});

  @override
  State<MedicalNewsWidget> createState() => _MedicalNewsWidgetState();
}

class _MedicalNewsWidgetState extends State<MedicalNewsWidget> {
  List<HealthNewsItem> news = [];
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    final loadedNews = await HealthNewsService.fetchMedicalNews();
    if (!mounted) return;
    setState(() {
      news = loadedNews;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'آخر الأخبار الطبية',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllHealthNewsScreen(newsList: news),
                    ),
                  );
                },
                child: const Text("عرض الكل"),
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (news.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
              ),
              child: const Text(
                'لا توجد أخبار طبية متاحة حالياً. اسحب لتحديث الصفحة وحاول مرة أخرى.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SizedBox(
            height: 250,
            child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: news.length,
            itemBuilder: (context, index) {
              final article = news[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewsDetailScreen(news: article),
                    ),
                  );
                },
                child: Container(
                  width: 320,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.withOpacity(0.1),
                        blurRadius: isDarkMode ? 0 : 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: article.imageUrl.isNotEmpty
                              ? Image.network(article.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover)
                              : Container(
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),

                            Text(
                              article.source,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
              },
            ),
          ),
      ],
    );
  }
}
