import 'package:flutter/material.dart';
import 'package:digl/core/config/theme.dart';
import 'package:translator/translator.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final _controller = TextEditingController();
  final List<Map<String, String>> messages = [
    {'ar': 'مرحباً دكتور، لدي ألم في الصدر.', 'en': 'Hello doctor, I have chest pain.'},
    {'ar': 'منذ متى تشعر بهذا الألم؟', 'en': 'How long have you had this pain?'},
  ];
  String _selectedLang = 'ar';

  void _translateAndAddMessage() async {
    if (_controller.text.isNotEmpty) {
      final translator = GoogleTranslator();
      final translation = await translator.translate(_controller.text, to: _selectedLang == 'ar' ? 'en' : 'ar');
      setState(() {
        messages.add({
          _selectedLang: _controller.text,
          _selectedLang == 'ar' ? 'en' : 'ar': translation.text,
        });
        _controller.clear();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الترجمة الفورية'),
        actions: [
          DropdownButton<String>(
            value: _selectedLang,
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Colors.white),
            dropdownColor: AppTheme.primaryBlue,
            items: const [
              DropdownMenuItem(value: 'ar', child: Text('العربية', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Colors.white))),
            ],
            onChanged: (val) => setState(() => _selectedLang = val!),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, i) => Align(
                alignment: i % 2 == 0 ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: i % 2 == 0 ? AppTheme.primaryBlue.withOpacity(0.1) : AppTheme.positiveGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(messages[i][_selectedLang]!, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _translateAndAddMessage,
                  child: const Icon(Icons.translate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
