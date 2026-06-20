import 'package:flutter/material.dart';

import '../../services/health_News_Service.dart';
import 'all_HealthNewsScreen.dart';
import 'newsDetailScreen.dart';

class MedicalTipsWidget extends StatefulWidget {
  const MedicalTipsWidget({super.key});

  @override
  State<MedicalTipsWidget> createState() => _MedicalTipsWidgetState();
}

class _MedicalTipsWidgetState extends State<MedicalTipsWidget> {
  List<HealthNewsItem> chronicTips = [];
  List<HealthNewsItem> nutritionTips = [];
  List<HealthNewsItem> preventionTips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    chronicTips = await HealthNewsService.fetchChronicDiseaseTips();
    nutritionTips = await HealthNewsService.fetchNutritionTips();
    preventionTips = await HealthNewsService.fetchPreventionTips();

    setState(() => isLoading = false);
  }

  Widget _buildHorizontalTips(String title, List<HealthNewsItem> tips) {
    if (tips.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AllHealthNewsScreen(newsList: tips,),
                    ),
                  );
                },
                child: const Text("عرض الكل"),
              )
            ],
          ),


        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewsDetailScreen(news: tip),
                    ),
                  );
                },
                child: Container(
                  width: 260,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDarkMode?Colors.grey[900]:Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: tip.imageUrl.isNotEmpty
                            ? Image.network(
                          tip.imageUrl,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          tip.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          tip.source,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHorizontalTips('نصائح للأمراض المزمنة', chronicTips),

        const SizedBox(height: 20),

        _buildHorizontalTips('الغذاء المفيد', nutritionTips),

        const SizedBox(height: 20),

        _buildHorizontalTips('الوقاية من الأمراض المعدية', preventionTips),
      ],
    );
  }
}
