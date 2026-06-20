import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digl/features/medical_profile/models/health_profile_model.dart';
import 'package:digl/features/medical_profile/presentation/pages/suggested_doctor_screen.dart';

class DiagnosisResultScreen extends StatefulWidget {
  final DiagnosisResult diagnosis;
  final HealthProfile healthProfile;

  const DiagnosisResultScreen({
    super.key,
    required this.diagnosis,
    required this.healthProfile,
  });

  @override
  State<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> {
  late bool _isHighRisk;

  @override
  void initState() {
    super.initState();
    _isHighRisk = widget.diagnosis.severity == 'high';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // منع الرجوع للخلف
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نتائج التشخيص'),
          centerTitle: true,
          backgroundColor: const Color(0xFF3A86FF),
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDiagnosisCard(),
              const SizedBox(height: 24),
              _buildImmediateActionsCard(),
              const SizedBox(height: 24),
              if (!_isHighRisk) _buildSpecialtiesCard(),
              if (!_isHighRisk) const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosisCard() {
    Color cardColor;
    IconData icon;

    if (widget.diagnosis.severity == 'high') {
      cardColor = Colors.red;
      icon = Icons.priority_high;
    } else if (widget.diagnosis.severity == 'medium') {
      cardColor = Colors.orange;
      icon = Icons.warning;
    } else {
      cardColor = Colors.green;
      icon = Icons.check_circle;
    }

    return Card(
      elevation: 4,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              widget.diagnosis.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              widget.diagnosis.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImmediateActionsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Color(0xFF3A86FF), size: 24),
                SizedBox(width: 8),
                Text(
                  'النصائح الفورية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.diagnosis.immediateActions.map((action) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialtiesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_hospital, color: Color(0xFF3A86FF), size: 24),
                SizedBox(width: 8),
                Text(
                  'التخصصات المقترحة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.diagnosis.suggestedSpecialties.map((specialty) {
                return Chip(
                  label: Text(specialty),
                  backgroundColor: const Color(0xFF3A86FF).withOpacity(0.2),
                  labelStyle: const TextStyle(
                    color: Color(0xFF3A86FF),
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isHighRisk)
          ElevatedButton.icon(
            onPressed: () {
              // اتصل برقم الطوارئ
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('يرجى الاتصال برقم الطوارئ: 911'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            icon: const Icon(Icons.call, color: Colors.white),
            label: const Text('اتصل برقم الطوارئ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        if (!_isHighRisk) ...[
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => SuggestedDoctorScreen(
                    specialties: widget.diagnosis.suggestedSpecialties,
                    patientAge: widget.healthProfile.age,
                    patientGender: widget.healthProfile.gender,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('اختر طبيب متخصص'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A86FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            },
            icon: const Icon(Icons.home),
            label: const Text('العودة إلى الرئيسية'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ],
    );
  }
}
