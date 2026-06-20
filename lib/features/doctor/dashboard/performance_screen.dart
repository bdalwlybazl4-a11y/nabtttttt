import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, int> performanceData = {};

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    final doctorId = _auth.currentUser?.uid;
    if (doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول لعرض بيانات الأداء'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final snap = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      int pendingCount = 0;
      int attendedCount = 0;
      int cancelledCount = 0;

      for (var doc in snap.docs) {
        final appointmentDate = (doc['date'] as Timestamp?)?.toDate();
        if (appointmentDate == null || appointmentDate.isBefore(monthStart)) {
          continue;
        }
        final status = doc['status'] as String? ?? 'pending';
        if (status == 'pending') pendingCount++;
        if (status == 'attended') attendedCount++;
        if (status == 'cancelled') cancelledCount++;
      }

      setState(() {
        performanceData = {
          'جديد': pendingCount,
          'تم الحضور': attendedCount,
          'ملغى': cancelledCount,
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل بيانات الأداء: $e'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأداء الشهري'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPerformanceData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات الأداء الشهري',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: performanceData.isEmpty
                  ? const Center(child: Text('لا توجد بيانات للعرض'))
                  : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (performanceData.values.reduce((a, b) => a > b ? a : b) * 1.2)
                      .toDouble(),
                  barGroups: performanceData.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.value.toDouble(),
                          color: data.key == 'جديد'
                              ? AppTheme.positiveGreen
                              : data.key == 'تم الحضور'
                              ? AppTheme.primaryBlue
                              : AppTheme.alertRed,
                          width: 25,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            performanceData.keys.elementAt(value.toInt()),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard(
                  'إجمالي المواعيد',
                  '${performanceData.values.isEmpty ? 0 : performanceData.values.reduce((a, b) => a + b)}',
                  Icons.calendar_today,
                  AppTheme.primaryBlue,
                ),
                _buildStatCard(
                  'نسبة الحضور',
                  '${performanceData.isEmpty ? 0 : (performanceData['تم الحضور']! / (performanceData.values.reduce((a, b) => a + b) == 0 ? 1 : performanceData.values.reduce((a, b) => a + b)) * 100).toStringAsFixed(1)}%',
                  Icons.bar_chart,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
