import 'package:flutter/material.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _bookingFeeController = TextEditingController();
  final _workDays = <String>{};
  String? _licenseFileName;

  final List<String> days = [
    'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _specialtyController.dispose();
    _qualificationController.dispose();
    _licenseNumberController.dispose();
    _bookingFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل طبيب جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('البيانات الأساسية', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'الرجاء إدخال الاسم' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'الرجاء إدخال البريد الإلكتروني' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (v) => v == null || v.length < 6 ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المعلومات المهنية', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _specialtyController,
                        decoration: const InputDecoration(
                          labelText: 'التخصص',
                          prefixIcon: Icon(Icons.medical_services),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'الرجاء إدخال التخصص' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _qualificationController,
                        decoration: const InputDecoration(
                          labelText: 'المؤهلات',
                          prefixIcon: Icon(Icons.school),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _licenseNumberController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الترخيص الطبي',
                          prefixIcon: Icon(Icons.confirmation_number),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'الرجاء إدخال رقم الترخيص' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bookingFeeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'قيمة الحجز',
                          hintText: 'مثال: 100',
                          suffixText: 'ريال',
                          prefixIcon: Icon(Icons.payments),
                        ),
                        validator: (v) {
                          final fee = double.tryParse((v ?? '').trim());
                          return fee == null || fee <= 0 ? 'الرجاء إدخال قيمة الحجز' : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: تحميل وثيقة الترخيص
                              setState(() {
                                _licenseFileName = 'license.pdf';
                              });
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('تحميل الترخيص'),
                          ),
                          const SizedBox(width: 12),
                          if (_licenseFileName != null)
                            Text(_licenseFileName!, style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('أيام العمل', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: days.map((d) => FilterChip(
                          label: Text(d),
                          selected: _workDays.contains(d),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _workDays.add(d);
                              } else {
                                _workDays.remove(d);
                              }
                            });
                          },
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && _licenseFileName != null && _workDays.isNotEmpty) {
                    // TODO: إرسال الطلب وانتظار الموافقة
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('تم إرسال الطلب'),
                        content: const Text('سيتم مراجعة بياناتك خلال 24 ساعة. سيتم إشعارك عند التفعيل.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('حسناً'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text('إرسال الطلب'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
