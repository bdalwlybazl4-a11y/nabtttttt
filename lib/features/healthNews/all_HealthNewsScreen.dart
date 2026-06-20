import 'package:flutter/material.dart';
import '../../services/health_News_Service.dart';
import 'newsDetailScreen.dart';

class AllHealthNewsScreen extends StatelessWidget {
  final List<HealthNewsItem> newsList;

  const AllHealthNewsScreen({super.key, required this.newsList});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          backgroundColor: isDarkMode? Colors.grey[900]: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 2,
          title: const Text("جميع الأخبار الصحية")),
      body: ListView.builder(
        itemCount: newsList.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final news = newsList[index];
          return Card(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: isDarkMode ? 0 : 3,
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NewsDetailScreen(news: news)),
                );
              },
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (news.imageUrl.isNotEmpty)
                    ? Image.network(news.imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                    : Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.article)),
              ),
              title: Text(news.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(news.source, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ),
          );
        },
      ),
    );
  }
}
