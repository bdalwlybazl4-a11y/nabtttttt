import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;

  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _workPlaceController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDoctor = false;

  String? _photoURL;
  String? _profileImageBase64;
  File? _newImageFile;

  Color get _surface => Theme.of(context).cardColor;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  Color get _primary => Theme.of(context).colorScheme.primary;
  Color get _text => Theme.of(context).colorScheme.onSurface;
  Color get _muted => Theme.of(context).colorScheme.onSurface.withOpacity(.64);
  Color get _border => Theme.of(context).dividerColor.withOpacity(0.35);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await _firestore.collection('users').doc(widget.userId).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _nameController.text = (data['fullName'] ?? data['name'] ?? '').toString();
        _phoneController.text = (data['phone'] ?? data['phoneNumber'] ?? '').toString();
        _genderController.text = (data['gender'] ?? '').toString();
        _ageController.text = (data['age'] ?? '').toString();
        _workPlaceController.text = (data['workPlace'] ?? data['clinicName'] ?? '').toString();
        _isDoctor = data['accountType'] == 'doctor';
        _photoURL = (data['photoURL'] ?? '').toString();
        _profileImageBase64 = (data['profileImageBase64'] ?? '').toString();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على بيانات المستخدم')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 35,
      maxWidth: 420,
      maxHeight: 420,
    );
    if (pickedFile != null) {
      setState(() => _newImageFile = File(pickedFile.path));
    }
  }

  Future<_ProfileImageSaveResult> _saveProfileImage(File image) async {
    final bytes = await image.readAsBytes();

    // Firebase Storage is blocked on Spark projects for many apps. To avoid upload-session
    // crashes, profile photos are saved as a compact Firestore fallback by default.
    return _ProfileImageSaveResult(
      photoURL: null,
      profileImageBase64: base64Encode(bytes),
      usedFirestoreFallback: true,
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? uploadedPhotoURL = _photoURL;
      String? fallbackBase64 = _profileImageBase64;
      var usedFallback = false;

      if (_newImageFile != null) {
        final imageResult = await _saveProfileImage(_newImageFile!);
        uploadedPhotoURL = imageResult.photoURL ?? '';
        fallbackBase64 = imageResult.profileImageBase64 ?? '';
        usedFallback = imageResult.usedFirestoreFallback;
      }

      final updatedData = <String, dynamic>{
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _genderController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'photoURL': uploadedPhotoURL,
        'profileImageBase64': fallbackBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isDoctor) {
        updatedData['workPlace'] = _workPlaceController.text.trim();
      }

      await _firestore.collection('users').doc(widget.userId).set(updatedData, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(usedFallback
              ? 'تم حفظ الصورة بنجاح داخل Firestore بدون استخدام Firebase Storage'
              : 'تم تحديث الملف الشخصي بنجاح'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التحديث: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    _workPlaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _primary,
        elevation: 0,
        centerTitle: true,
        title: const Text('تعديل الملف الشخصي'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageHeader(),
                const SizedBox(height: 18),
                _buildFormCard(),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ التعديلات'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 58,
                backgroundColor: _primary.withOpacity(0.12),
                backgroundImage: _avatarProvider(),
                child: _avatarProvider() == null ? Icon(Icons.person_rounded, size: 48, color: _primary) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: _primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _pickImage,
                    child: Padding(
                      padding: const EdgeInsets.all(11),
                      child: Icon(Icons.camera_alt_rounded, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('صورة الملف الشخصي', style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            'اختر صورة واضحة وسيتم حفظ نسخة مضغوطة مباشرة داخل ملفك الشخصي.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  ImageProvider? _avatarProvider() {
    if (_newImageFile != null) return FileImage(_newImageFile!);
    if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      return MemoryImage(base64Decode(_profileImageBase64!));
    }
    if (_photoURL != null && _photoURL!.isNotEmpty) return NetworkImage(_photoURL!);
    return null;
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildField(_nameController, 'الاسم الكامل', Icons.person_rounded, validator: (value) => value == null || value.isEmpty ? 'الرجاء إدخال الاسم' : null),
          const SizedBox(height: 12),
          _buildField(_phoneController, 'رقم الهاتف', Icons.phone_rounded, keyboardType: TextInputType.phone, validator: (value) => value == null || value.isEmpty ? 'الرجاء إدخال رقم الهاتف' : null),
          const SizedBox(height: 12),
          _buildField(_genderController, 'الجنس', Icons.wc_rounded, validator: (value) => value == null || value.isEmpty ? 'الرجاء إدخال الجنس' : null),
          const SizedBox(height: 12),
          _buildField(
            _ageController,
            'العمر',
            Icons.cake_rounded,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'الرجاء إدخال العمر';
              final age = int.tryParse(value);
              if (age == null || age <= 0) return 'الرجاء إدخال عمر صحيح';
              return null;
            },
          ),
          if (_isDoctor) ...[
            const SizedBox(height: 12),
            _buildField(_workPlaceController, 'مكان العمل', Icons.business_center_rounded, validator: (value) => value == null || value.isEmpty ? 'الرجاء إدخال مكان العمل' : null),
          ],
        ],
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: _text, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primary),
        filled: true,
        fillColor: Color.lerp(Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer, .35)!.withOpacity(0.24),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primary, width: 1.4)),
      ),
    );
  }
}

class _ProfileImageSaveResult {
  final String? photoURL;
  final String? profileImageBase64;
  final bool usedFirestoreFallback;

  const _ProfileImageSaveResult({
    required this.photoURL,
    required this.profileImageBase64,
    required this.usedFirestoreFallback,
  });
}