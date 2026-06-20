import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digl/features/admin/models/admin_models.dart';
import 'package:digl/features/admin/services/admin_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorRequestDetailsScreen extends StatefulWidget {
  final DoctorRequest request;

  const DoctorRequestDetailsScreen({super.key, required this.request});

  @override
  State<DoctorRequestDetailsScreen> createState() => _DoctorRequestDetailsScreenState();
}

class _DoctorRequestDetailsScreenState extends State<DoctorRequestDetailsScreen> {
  late DoctorRequest _request;
  bool _isLoading = false;
  final _rejectionReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('تفاصيل طلب الطبيب'),
        backgroundColor: const Color(0xFF3A86FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'البيانات الشخصية',
              icon: Icons.person_rounded,
              children: [
                if (_request.profileImageUrl.isNotEmpty) ...[
                  _buildImagePreview('الصورة الشخصية', _request.profileImageUrl),
                  const SizedBox(height: 10),
                ],
                _buildInfoRow('الاسم الكامل', _request.fullName),
                _buildInfoRow('البريد الإلكتروني', _request.email),
                _buildInfoRow('رقم الهاتف', _request.phoneNumber),
                _buildInfoRow('تاريخ إنشاء الطلب', _formatDate(_request.createdAt)),
                _buildInfoRow('حالة الحساب', _statusMeta(_request.status).label),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'البيانات المهنية',
              icon: Icons.badge_rounded,
              children: [
                _buildInfoRow('التخصص', _request.specialty),
                if (_request.medicalDegree.isNotEmpty && !_looksLikeUrl(_request.medicalDegree))
                  _buildInfoRow('المؤهل العلمي', _request.medicalDegree),
                _buildInfoRow('سنوات الخبرة', _request.yearsOfExperience),
                _buildInfoRow('اسم العيادة', _request.clinicName),
                _buildInfoRow('عنوان العيادة', _request.clinicAddress),
                if (_request.bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('نبذة تعريفية', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(_request.bio, style: const TextStyle(height: 1.5)),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'الوثائق والإثباتات',
              icon: Icons.description_rounded,
              children: [
                if (_request.licenseDocumentBase64.isNotEmpty) ...[
                  _buildSectionLabel('معاينة وثيقة إثبات المهنة'),
                  _buildBase64ImagePreview(
                    'وثيقة إثبات المهنة',
                    _request.licenseDocumentBase64,
                  ),
                  const SizedBox(height: 10),
                ] else if (_request.medicalLicense.isNotEmpty) ...[
                  if (_isImageUrl(_request.medicalLicense)) ...[
                    _buildSectionLabel('معاينة صورة إثبات المهنة'),
                    _buildImagePreview('وثيقة إثبات المهنة', _request.medicalLicense),
                    const SizedBox(height: 10),
                  ],
                  _buildDocumentItem('وثيقة إثبات المهنة', _request.medicalLicense),
                ],
                if (_request.medicalDegree.isNotEmpty && _looksLikeUrl(_request.medicalDegree))
                  _buildDocumentItem('شهادة التخرج', _request.medicalDegree),
                ..._request.documentUrls
                    .where((url) => url.isNotEmpty && url != _request.medicalLicense)
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) => _buildDocumentItem('وثيقة إضافية ${entry.key + 1}', entry.value)),
                if (_request.licenseDocumentBase64.isEmpty && _request.medicalLicense.isEmpty && _request.licenseDocumentName.isNotEmpty)
                  _buildUploadWarning(),
                if (_request.licenseDocumentBase64.isEmpty && _request.medicalLicense.isEmpty && _request.medicalDegree.isEmpty && _request.documentUrls.isEmpty && _request.licenseDocumentName.isEmpty)
                  Text('لا توجد وثائق محفوظة لهذا الطلب.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionButtons(),
            if (_request.status != 'pending') _buildReviewInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusMeta = _statusMeta(_request.status);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusMeta.color, statusMeta.color.withOpacity(0.78)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: statusMeta.color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusMeta.icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusMeta.label,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (_request.rejectionReason.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'سبب الرفض: ${_request.rejectionReason}',
                      style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.92)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildUploadWarning() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_rounded, color: colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تم اختيار وثيقة الإثبات: ${_request.licenseDocumentName}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _request.licenseUploadError.isNotEmpty
                      ? _request.licenseUploadError
                      : 'تعذر رفع الوثيقة إلى Firebase Storage. يرجى مراجعة إعدادات التخزين ثم طلب إعادة رفع الوثيقة.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String title, String url) {
    final isImage = _isImageUrl(url);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'تم الرفع وجاهز للمراجعة',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'فتح بالحجم الكامل',
            icon: Icon(Icons.open_in_new_rounded, color: colorScheme.primary),
            onPressed: () => _openAttachment(title, url),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String title, String url) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openAttachment(title, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: colorScheme.primaryContainer.withOpacity(0.45),
              alignment: Alignment.center,
              child: Text(
                'تعذر تحميل الصورة',
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBase64ImagePreview(String title, String base64Value) {
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final bytes = base64Decode(base64Value);

      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openBase64Attachment(title, base64Value),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 260, maxHeight: 520),
            width: double.infinity,
            color: colorScheme.surface,
            child: InteractiveViewer(
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildBase64PreviewError(),
              ),
            ),
          ),
        ),
      );
    } catch (_) {
      return _buildBase64PreviewError();
    }
  }

  Widget _buildBase64PreviewError() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.error.withOpacity(0.25)),
      ),
      child: Text(
        'تعذر عرض الوثيقة المحفوظة كصورة.',
        textAlign: TextAlign.center,
        style: TextStyle(color: colorScheme.onErrorContainer),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  bool _looksLikeUrl(String value) => value.startsWith('http://') || value.startsWith('https://');

  bool _isImageUrl(String url) {
    final lower = Uri.decodeFull(url).toLowerCase();
    return lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('.png') || lower.contains('image%2f');
  }

  Future<void> _openBase64Attachment(String title, String base64Value) async {
    if (base64Value.isEmpty) return;

    try {
      final bytes = base64Decode(base64Value);
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(title),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('تعذر عرض الوثيقة المحفوظة كصورة.'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر قراءة الوثيقة المحفوظة.')),
      );
    }
  }

  Future<void> _openAttachment(String title, String url) async {
    if (url.isEmpty) return;

    if (_isImageUrl(url)) {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(title),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('تعذر تحميل الصورة'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الوثيقة. تحقق من الرابط أو صلاحيات الوصول.')),
      );
    }
  }

  String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return 'غير محدد';
    return '${date.day}/${date.month}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value.isEmpty ? 'غير محدد' : value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_request.status != 'approved') ...[
          ElevatedButton.icon(
            onPressed: _approveRequest,
            icon: const Icon(Icons.verified_rounded),
            label: const Text('الموافقة على الطلب'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2CB67D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_request.status != 'rejected') ...[
          OutlinedButton.icon(
            onPressed: _showRejectDialog,
            icon: const Icon(Icons.close_rounded),
            label: Text(_request.status == 'approved' ? 'إلغاء تفعيل الطبيب' : 'رفض الطلب'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE63946),
              side: const BorderSide(color: Color(0xFFE63946)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: _deleteDoctor,
          icon: const Icon(Icons.delete_forever_rounded),
          label: const Text('حذف الطبيب نهائياً'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade900,
            side: BorderSide(color: Colors.red.shade900),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewInfo() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.55),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('معلومات المراجعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildInfoRow('المراجع', _request.reviewedBy),
            _buildInfoRow(
              'تاريخ المراجعة',
              '${_request.reviewedAt.day}/${_request.reviewedAt.month}/${_request.reviewedAt.year}',
            ),
          ],
        ),
      ),
    );
  }

  _StatusMeta _statusMeta(String status) {
    switch (status) {
      case 'pending':
        return const _StatusMeta(label: 'قيد الانتظار - بانتظار المراجعة', color: Color(0xFFFFA62B), icon: Icons.hourglass_bottom_rounded);
      case 'approved':
        return const _StatusMeta(label: 'تمت الموافقة على الطلب', color: Color(0xFF2CB67D), icon: Icons.verified_rounded);
      case 'rejected':
        return const _StatusMeta(label: 'تم رفض الطلب', color: Color(0xFFE63946), icon: Icons.cancel_rounded);
      default:
        return const _StatusMeta(label: 'حالة غير معروفة', color: Colors.grey, icon: Icons.help_outline_rounded);
    }
  }

  Future<void> _approveRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: const Text('هل أنت متأكد من الموافقة على طلب هذا الطبيب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('نعم')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final admin = FirebaseAuth.instance.currentUser;
      if (admin == null) throw Exception('لم يتم العثور على المسؤول');

      final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(admin.uid).get();

      final adminName = adminDoc.data()?['fullName'] ?? 'مسؤول';

      await AdminService.approveDoctorRequest(_request.id, admin.uid, adminName);
      _request = _request.copyWith(status: 'approved', reviewedBy: admin.uid, reviewedAt: DateTime.now(), rejectionReason: '');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الموافقة على الطلب بنجاح'), backgroundColor: Color(0xFF2CB67D)),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_request.status == 'approved' ? 'إلغاء تفعيل الطبيب' : 'رفض الطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_request.status == 'approved' ? 'الرجاء إدخال سبب إلغاء التفعيل:' : 'الرجاء إدخال سبب الرفض:'),
            const SizedBox(height: 12),
            TextField(
              controller: _rejectionReasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب سبب الرفض...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              if (_rejectionReasonController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context);
              _rejectRequest();
            },
            child: Text(_request.status == 'approved' ? 'إلغاء التفعيل' : 'رفض'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectRequest() async {
    setState(() => _isLoading = true);

    try {
      final admin = FirebaseAuth.instance.currentUser;
      if (admin == null) throw Exception('لم يتم العثور على المسؤول');

      final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(admin.uid).get();

      final adminName = adminDoc.data()?['fullName'] ?? 'مسؤول';

      final reason = _rejectionReasonController.text.trim();
      final wasApproved = _request.status == 'approved';
      if (wasApproved) {
        await AdminService.deactivateDoctor(_request.doctorId, admin.uid, adminName, reason);
      } else {
        await AdminService.rejectDoctorRequest(
          _request.id,
          admin.uid,
          adminName,
          reason,
        );
      }
      _request = _request.copyWith(status: 'rejected', reviewedBy: admin.uid, reviewedAt: DateTime.now(), rejectionReason: reason);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasApproved ? 'تم إلغاء تفعيل الطبيب بنجاح' : 'تم رفض الطلب بنجاح'),
          backgroundColor: const Color(0xFFE63946),
        ),
      );

      _rejectionReasonController.clear();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteDoctor() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الطبيب'),
        content: const Text('سيتم حذف بيانات الطبيب وطلبه من قاعدة البيانات. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final admin = FirebaseAuth.instance.currentUser;
      if (admin == null) throw Exception('لم يتم العثور على المسؤول');

      final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(admin.uid).get();
      final adminName = adminDoc.data()?['fullName'] ?? 'مسؤول';

      await AdminService.deleteDoctor(_request.doctorId, admin.uid, adminName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الطبيب بنجاح'), backgroundColor: Color(0xFFE63946)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

}

class _StatusMeta {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusMeta({required this.label, required this.color, required this.icon});
}