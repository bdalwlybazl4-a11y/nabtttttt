import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج بيانات المسؤول
class AdminUser {
  final String id;
  final String email;
  final String password; // يتم التعامل معها عبر Firebase Auth
  final String fullName;
  final String role; // super_admin, admin
  final String phoneNumber;
  final String profileImage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> permissions;

  AdminUser({
    required this.id,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    required this.phoneNumber,
    required this.profileImage,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.permissions,
  });

  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser(
      id: doc.id,
      email: data['email'] ?? '',
      password: '', // لا نخزن كلمة المرور
      fullName: data['fullName'] ?? '',
      role: data['role'] ?? 'admin',
      phoneNumber: data['phoneNumber'] ?? data['phone'] ?? '',
      profileImage: data['profileImage'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      permissions: List<String>.from(data['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'permissions': permissions,
    };
  }
}

/// نموذج طلب تسجيل الطبيب
class DoctorRequest {
  final String id;
  final String doctorId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String specialty;
  final String medicalLicense; // رابط الملف القديم
  final String licenseDocumentBase64; // وثيقة الترخيص محفوظة كـ Base64
  final String licenseDocumentName; // اسم ملف الإثبات
  final String licenseUploadStatus;
  final String licenseUploadError;
  final String medicalDegree; // شهادة التخرج
  final String profileImageUrl; // الصورة الشخصية
  final String clinicName;
  final String clinicAddress;
  final List<String> documentUrls; // الوثائق الإضافية
  final String status; // pending, approved, rejected
  final String rejectionReason;
  final DateTime createdAt;
  final DateTime reviewedAt;
  final String reviewedBy;
  final double rating;
  final int reviewCount;
  final String bio;
  final List<String> specialties;
  final String yearsOfExperience;

  DoctorRequest({
    required this.id,
    required this.doctorId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.specialty,
    required this.medicalLicense,
    required this.licenseDocumentBase64,
    required this.licenseDocumentName,
    required this.licenseUploadStatus,
    required this.licenseUploadError,
    required this.medicalDegree,
    required this.profileImageUrl,
    required this.clinicName,
    required this.clinicAddress,
    required this.documentUrls,
    required this.status,
    required this.rejectionReason,
    required this.createdAt,
    required this.reviewedAt,
    required this.reviewedBy,
    required this.rating,
    required this.reviewCount,
    required this.bio,
    required this.specialties,
    required this.yearsOfExperience,
  });


  static String _normalizeStatus(dynamic status) {
    final value = (status ?? 'pending').toString().trim().toLowerCase();
    if (value == 'approved' || value == 'approve') return 'approved';
    if (value == 'rejected' || value == 'reject') return 'rejected';
    return 'pending';
  }

  static DateTime _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  factory DoctorRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DoctorRequest(
      id: doc.id,
      doctorId: data['doctorId'] ?? data['uid'] ?? doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? data['phone'] ?? '',
      specialty: data['specialty'] ?? data['specialtyName'] ?? '',
      medicalLicense: data['medicalLicense'] ?? data['licenseDocumentUrl'] ?? '',
      licenseDocumentBase64: data['licenseDocumentBase64'] ?? '',
      licenseDocumentName: data['licenseDocument'] ?? '',
      licenseUploadStatus: data['licenseUploadStatus'] ?? '',
      licenseUploadError: data['licenseUploadError'] ?? '',
      medicalDegree: data['medicalDegree'] ?? data['qualification'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? data['photoURL'] ?? '',
      clinicName: data['clinicName'] ?? '',
      clinicAddress: data['clinicAddress'] ?? '',
      documentUrls: List<String>.from(data['documentUrls'] ?? []),
      status: _normalizeStatus(data['verificationStatus'] ?? data['doctorRequestStatus'] ?? data['accountStatus'] ?? data['status'] ?? (data['isVerified'] == true ? 'approved' : 'pending')),
      rejectionReason: data['rejectionReason'] ?? '',
      createdAt: _timestampToDate(data['createdAt']),
      reviewedAt: data['reviewedAt'] != null
          ? _timestampToDate(data['reviewedAt'])
          : DateTime.fromMillisecondsSinceEpoch(0),
      reviewedBy: data['reviewedBy'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      bio: data['bio'] ?? '',
      specialties: List<String>.from(data['specialties'] ?? []),
      yearsOfExperience: data['yearsOfExperience'] ?? '0',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'specialty': specialty,
      'medicalLicense': medicalLicense,
      'licenseDocumentUrl': medicalLicense,
      'licenseDocumentBase64': licenseDocumentBase64,
      'licenseDocument': licenseDocumentName,
      'licenseUploadStatus': licenseUploadStatus,
      'licenseUploadError': licenseUploadError,
      'medicalDegree': medicalDegree,
      'profileImageUrl': profileImageUrl,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'documentUrls': documentUrls,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': FieldValue.serverTimestamp(),
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewedBy,
      'rating': rating,
      'reviewCount': reviewCount,
      'bio': bio,
      'specialties': specialties,
      'yearsOfExperience': yearsOfExperience,
    };
  }

  DoctorRequest copyWith({
    String? id,
    String? doctorId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? specialty,
    String? medicalLicense,
    String? licenseDocumentBase64,
    String? licenseDocumentName,
    String? licenseUploadStatus,
    String? licenseUploadError,
    String? medicalDegree,
    String? profileImageUrl,
    String? clinicName,
    String? clinicAddress,
    List<String>? documentUrls,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    double? rating,
    int? reviewCount,
    String? bio,
    List<String>? specialties,
    String? yearsOfExperience,
  }) {
    return DoctorRequest(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      specialty: specialty ?? this.specialty,
      medicalLicense: medicalLicense ?? this.medicalLicense,
      licenseDocumentBase64: licenseDocumentBase64 ?? this.licenseDocumentBase64,
      licenseDocumentName: licenseDocumentName ?? this.licenseDocumentName,
      licenseUploadStatus: licenseUploadStatus ?? this.licenseUploadStatus,
      licenseUploadError: licenseUploadError ?? this.licenseUploadError,
      medicalDegree: medicalDegree ?? this.medicalDegree,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      documentUrls: documentUrls ?? this.documentUrls,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
    );
  }
}

/// نموذج لإحصائيات الإدارة
class AdminStats {
  final int totalDoctors;
  final int pendingRequests;
  final int approvedDoctors;
  final int rejectedRequests;
  final int totalPatients;
  final int totalAppointments;
  final double averageDoctorRating;
  final int totalConsultations;
  final int totalHealthAssessments;
  final Map<String, int> topSpecialties;
  final Map<String, int> topDoctors;

  AdminStats({
    required this.totalDoctors,
    required this.pendingRequests,
    required this.approvedDoctors,
    required this.rejectedRequests,
    required this.totalPatients,
    required this.totalAppointments,
    required this.averageDoctorRating,
    required this.totalConsultations,
    this.totalHealthAssessments = 0,
    this.topSpecialties = const {},
    this.topDoctors = const {},
  });

  factory AdminStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminStats(
      totalDoctors: data['totalDoctors'] ?? 0,
      pendingRequests: data['pendingRequests'] ?? 0,
      approvedDoctors: data['approvedDoctors'] ?? 0,
      rejectedRequests: data['rejectedRequests'] ?? 0,
      totalPatients: data['totalPatients'] ?? 0,
      totalAppointments: data['totalAppointments'] ?? 0,
      averageDoctorRating: (data['averageDoctorRating'] ?? 0).toDouble(),
      totalConsultations: data['totalConsultations'] ?? 0,
      totalHealthAssessments: data['totalHealthAssessments'] ?? 0,
      topSpecialties: Map<String, int>.from(data['topSpecialties'] ?? const {}),
      topDoctors: Map<String, int>.from(data['topDoctors'] ?? const {}),
    );
  }
}
