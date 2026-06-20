import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digl/services/user_role_service.dart';
import '../../data/models/medical_intake.dart';
import '../../data/repositories/medical_ai_repository.dart';
import '../../data/services/medical_ai_api_service.dart';
import '../providers/medical_ai_chat_provider.dart';

class MedicalAiChatScreen extends StatefulWidget {
  const MedicalAiChatScreen({super.key});
  @override
  State<MedicalAiChatScreen> createState() => _MedicalAiChatScreenState();
}

class _MedicalAiChatScreenState extends State<MedicalAiChatScreen> {
  static const String _savedIntakeKey = 'medical_ai_saved_intake';
  final _formKey = GlobalKey<FormState>();
  final _problem = TextEditingController();
  final _started = TextEditingController();
  final _age = TextEditingController();
  final _duration = TextEditingController();
  final _message = TextEditingController();
  String _gender = 'ذكر';
  String _severity = 'متوسطة';
  MedicalIntake? _intake;
  bool _isLoadingSavedIntake = true;

  @override
  void initState() {
    super.initState();
    _loadSavedIntake();
  }

  @override
  void dispose() { _problem.dispose(); _started.dispose(); _age.dispose(); _duration.dispose(); _message.dispose(); super.dispose(); }

  Future<void> _loadSavedIntake() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedIntakeKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final intake = MedicalIntake.fromMap(jsonDecode(raw) as Map<String, dynamic>);
        if (intake.problem.trim().isNotEmpty && mounted) {
          setState(() => _intake = intake);
        }
      } catch (_) {
        await prefs.remove(_savedIntakeKey);
      }
    }
    if (mounted) setState(() => _isLoadingSavedIntake = false);
  }

  Future<void> _saveIntake(MedicalIntake intake) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedIntakeKey, jsonEncode(intake.toMap()));
  }

  Future<void> _startNewChat(BuildContext providerContext) async {
    providerContext.read<MedicalAiChatProvider>().clearMessages();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedIntakeKey);
    if (!mounted) return;
    _problem.clear();
    _started.clear();
    _age.clear();
    _duration.clear();
    _message.clear();
    setState(() => _intake = null);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MedicalAiChatProvider(MedicalAiRepository(apiService: MedicalAiApiService()))..loadLocalHistory(),
      child: FutureBuilder<bool>(
        future: UserRoleService.isPatient(),
        builder: (context, roleSnapshot) {
          if (roleSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (roleSnapshot.data != true) {
            return Scaffold(
              appBar: AppBar(title: const Text('مساعد نبض AI')),
              body: const SafeArea(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('المساعد الذكي متاح لحسابات المرضى فقط.', textAlign: TextAlign.center),
                  ),
                ),
              ),
            );
          }
          if (_isLoadingSavedIntake) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
          title: const Text('مساعد نبض AI'),
          actions: [IconButton(tooltip: 'محادثة جديدة', onPressed: () => _startNewChat(context), icon: const Icon(Icons.add_comment_rounded))],
        ),
        body: SafeArea(child: _intake == null ? _buildIntake(context) : _buildChat(context)),
      );
        },
      ),
    );
  }

  Widget _buildIntake(BuildContext context) => Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
    Text('لنبدأ بسياق طبي مختصر', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
    const SizedBox(height: 16),
    TextFormField(controller: _problem, decoration: const InputDecoration(labelText: 'ما المشكلة أو الأعراض؟', prefixIcon: Icon(Icons.sick_outlined)), validator: _required),
    const SizedBox(height: 12), TextFormField(controller: _started, decoration: const InputDecoration(labelText: 'متى بدأت؟'), validator: _required),
    const SizedBox(height: 12), TextFormField(controller: _age, decoration: const InputDecoration(labelText: 'العمر'), keyboardType: TextInputType.number, validator: (v){ final n=int.tryParse(v??''); return n==null||n<=0?'أدخل عمر صحيح':null;}),
    const SizedBox(height: 12), DropdownButtonFormField(value: _gender, decoration: const InputDecoration(labelText: 'الجنس'), items: ['ذكر','أنثى'].map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(), onChanged: (v)=>setState(()=>_gender=v!)),
    const SizedBox(height: 12), TextFormField(controller: _duration, decoration: const InputDecoration(labelText: 'مدة الأعراض'), validator: _required),
    const SizedBox(height: 12), DropdownButtonFormField(value: _severity, decoration: const InputDecoration(labelText: 'شدة الحالة'), items: ['خفيفة','متوسطة','شديدة','طارئة'].map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(), onChanged: (v)=>setState(()=>_severity=v!)),
    const SizedBox(height: 20), Consumer<MedicalAiChatProvider>(builder: (context, provider, _) => ElevatedButton.icon(onPressed: provider.isLoading ? null : () async { if(!_formKey.currentState!.validate()) return; final intake=MedicalIntake(problem:_problem.text.trim(), symptomStart:_started.text.trim(), age:int.parse(_age.text.trim()), gender:_gender, duration:_duration.text.trim(), severity:_severity); provider.clearMessages(); await _saveIntake(intake); if (!mounted) return; setState(()=>_intake=intake); await provider.buildInitialRecommendation(intake); }, icon: const Icon(Icons.auto_awesome), label: const Text('ابدأ المحادثة'))),
  ]));

  Widget _buildChat(BuildContext context) => Consumer<MedicalAiChatProvider>(builder: (context, provider, _) => AnimatedPadding(
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Column(children: [
    if (provider.error != null) MaterialBanner(content: Text(provider.error!), actions: [TextButton(onPressed: provider.clearError, child: const Text('حسناً'))]),
    Expanded(child: ListView.builder(reverse: false, padding: const EdgeInsets.fromLTRB(12, 12, 12, 8), itemCount: provider.messages.length, itemBuilder: (_, i){ final m=provider.messages[i]; return Align(alignment: m.isUser?Alignment.centerRight:Alignment.centerLeft, child: Container(constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width*.82), margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: m.isUser?Theme.of(context).colorScheme.primaryContainer:Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (m.attachmentType == 'image' && m.attachmentPath != null) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(m.attachmentPath!), height: 150, fit: BoxFit.cover)), Text(m.content)]))); })),
    if (provider.isLoading) const Padding(padding: EdgeInsets.all(8), child: Row(children: [SizedBox(width: 18,height:18,child:CircularProgressIndicator(strokeWidth:2)), SizedBox(width: 10), Text('المساعد يكتب...')])) ,
    SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 8), child: Row(children: [
      IconButton(tooltip: 'رفع صورة', onPressed: provider.isLoading ? null : () async { final x = await ImagePicker().pickImage(source: ImageSource.gallery); if (x != null) provider.sendAttachment(_intake!, x.path, 'image'); }, icon: const Icon(Icons.image_outlined)),
      IconButton(tooltip: 'رفع ملف', onPressed: provider.isLoading ? null : () async { final f = await FilePicker.platform.pickFiles(); final path=f?.files.single.path; if (path != null) provider.sendAttachment(_intake!, path, 'file'); }, icon: const Icon(Icons.attach_file)),
      Expanded(child: TextField(controller: _message, minLines: 1, maxLines: 4, decoration: const InputDecoration(hintText: 'اكتب سؤالك...', border: OutlineInputBorder()))),
      IconButton.filled(tooltip: 'إرسال', onPressed: provider.isLoading ? null : () { final text=_message.text; _message.clear(); provider.send(_intake!, text); }, icon: const Icon(Icons.send_rounded)),
    ]))),
  ])));

  String? _required(String? v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null;
}
