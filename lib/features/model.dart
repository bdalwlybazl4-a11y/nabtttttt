import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserModel {
  final String uid;
  final String accountType;
  final String? age;
  final String email;
  final String fullName;
  final String gender;
  final String? phone;
  final String? photoURL;
  final String? mood;
  final bool isVerified;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Timestamp lastLogin;

  final String? specialty;
  final String? specialtyName;
  final String? licenseNumber;
  final String? licenseDocument;
  final String? licenseDocumentUrl;
  final String? verificationStatus;
  final bool? hasLicenseDocuments;
  final List<dynamic>? workplaces;

  final double? rating;
  final int? consultationCount;
  final bool? isAvailable;
  final bool? isOnline;
  final String? fcmToken;
  final Timestamp? lastSeen;
  final double? minSessionPrice;
  final double? maxSessionPrice;
  final double? bookingFee;
  final double? latitude;
  final double? longitude;
  final String? address;
  final int? reviewCount;

  UserModel({
    required this.uid,
    required this.accountType,
    this.age,
    required this.email,
    required this.fullName,
    required this.gender,
    this.phone,
    this.photoURL,
    this.mood,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLogin,
    this.specialty,
    this.specialtyName,
    this.licenseNumber,
    this.licenseDocument,
    this.licenseDocumentUrl,
    this.verificationStatus,
    this.hasLicenseDocuments,
    this.workplaces,
    this.rating,
    this.consultationCount = 0,
    this.isAvailable = false,
    this.isOnline = false,
    this.fcmToken,
    this.lastSeen,
    this.minSessionPrice,
    this.maxSessionPrice,
    this.bookingFee,
    this.latitude,
    this.longitude,
    this.address,
    this.reviewCount,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      accountType: data['accountType'] as String? ?? 'patient',
      age: data['age']?.toString(),
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? 'مستخدم جديد',
      gender: data['gender'] as String? ?? 'غير محدد',
      phone: data['phone'] as String?,
      photoURL: data['photoURL'] as String?,
      mood: data['mood'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
      lastLogin: data['lastLogin'] as Timestamp? ?? Timestamp.now(),
      specialty: data['specialty'] as String?,
      specialtyName: data['specialtyName'] as String?,
      licenseNumber: data['licenseNumber'] as String?,
      licenseDocument: data['licenseDocument'] as String?,
      licenseDocumentUrl: data['licenseDocumentUrl'] as String?,
      verificationStatus: data['verificationStatus'] as String?,
      hasLicenseDocuments: data['hasLicenseDocuments'] as bool?,
      workplaces: data['workplaces'] as List<dynamic>?,
      rating: (data['rating'] as num?)?.toDouble(),
      consultationCount: data['consultationCount'] as int? ?? 0,
      isAvailable: data['isAvailable'] as bool? ?? false,
      isOnline: data['isOnline'] as bool? ?? false,
      fcmToken: data['fcmToken'] as String?,
      lastSeen: data['lastSeen'] is Timestamp ? data['lastSeen'] : null,
      minSessionPrice: (data['minSessionPrice'] as num?)?.toDouble(),
      maxSessionPrice: (data['maxSessionPrice'] as num?)?.toDouble(),
      bookingFee: _toDouble(data['bookingFee'] ?? data['consultationFee'] ?? data['sessionPrice'] ?? data['minSessionPrice']),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      address: (data['address'] ?? data['clinicAddress'])?.toString(),
      reviewCount: data['reviewCount'] as int?,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic> toMap() {
    final map = {
      'accountType': accountType,
      'email': email,
      'fullName': fullName,
      'gender': gender,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLogin': lastLogin,
      'rating': rating,
      'consultationCount': consultationCount,
      'isAvailable': isAvailable,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
    };

    if (age != null) map['age'] = age;
    if (phone != null) map['phone'] = phone;
    if (photoURL != null) map['photoURL'] = photoURL;
    if (mood != null) map['mood'] = mood;
    if (specialty != null) map['specialty'] = specialty;
    if (specialtyName != null) map['specialtyName'] = specialtyName;
    if (licenseNumber != null) map['licenseNumber'] = licenseNumber;
    if (licenseDocument != null) map['licenseDocument'] = licenseDocument;
    if (licenseDocumentUrl != null) map['licenseDocumentUrl'] = licenseDocumentUrl;
    if (verificationStatus != null) map['verificationStatus'] = verificationStatus;
    if (hasLicenseDocuments != null) map['hasLicenseDocuments'] = hasLicenseDocuments;
    if (workplaces != null) map['workplaces'] = workplaces;
    if (fcmToken != null) map['fcmToken'] = fcmToken;
    if (minSessionPrice != null) map['minSessionPrice'] = minSessionPrice;
    if (maxSessionPrice != null) map['maxSessionPrice'] = maxSessionPrice;
    if (bookingFee != null) map['bookingFee'] = bookingFee;
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    if (address != null) map['address'] = address;
    if (reviewCount != null) map['reviewCount'] = reviewCount;

    return map;
  }

  bool get isDoctor => accountType == 'doctor';
  bool get isPatient => accountType == 'patient';
  bool get isAvailableForConsultation => isDoctor && isVerified ;

  String get displaySpecialty {
    if (isDoctor) {
      return specialtyName ?? specialty ?? 'تخصص غير محدد';
    }
    return '';
  }
}


class Workplace {
  final String name;
  final Map<String, List<Map<String, int>>> workDays;

  Workplace({
    required this.name,
    required this.workDays,
  });

  factory Workplace.fromMap(Map<String, dynamic> map) {
    final workDaysMap = <String, List<Map<String, int>>>{};

    if (map['workDays'] != null) {
      final dynamicWorkDays = map['workDays'] as Map<String, dynamic>;
      dynamicWorkDays.forEach((day, timeSlots) {
        final slots = <Map<String, int>>[];
        if (timeSlots is List) {
          for (var slot in timeSlots) {
            if (slot is Map) {
              slots.add({
                'startHour': slot['startHour'] as int,
                'startMinute': slot['startMinute'] as int,
                'endHour': slot['endHour'] as int,
                'endMinute': slot['endMinute'] as int,
              });
            }
          }
        }
        workDaysMap[day] = slots;
      });
    }

    return Workplace(
      name: map['name'] as String? ?? 'مكان غير معروف',
      workDays: workDaysMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'workDays': workDays,
    };
  }

  List<String> get availableDays => workDays.keys.toList();

  String get formattedWorkingHours {
    final days = workDays.keys.map((day) {
      final hours = workDays[day]?.first;
      if (hours != null) {
        final start = '${hours['startHour']}:${hours['startMinute']?.toString().padLeft(2, '0')}';
        final end = '${hours['endHour']}:${hours['endMinute']?.toString().padLeft(2, '0')}';
        return '$day: $start - $end';
      }
      return '$day: مغلق';
    }).toList();
    return days.join('\n');
  }
}




class Appointment {
  final String id;

  final String doctorId;
  final String doctorName;
  final String? doctorImageUrl;
  final String? doctorPhone; // ✅ رقم هاتف الطبيب

  final String userId;
  final String userName;
  final String? userImageUrl;
  final String? userPhone; // ✅ رقم هاتف المريض

  final String specialtyName;
  final String workplace;
  final String payment;
  final String paymentStatus;
  late final String status;
  final String time;

  final Timestamp date;
  final Timestamp createdAt;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    this.doctorImageUrl,
    this.doctorPhone,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    this.userPhone,
    required this.specialtyName,
    required this.workplace,
    required this.payment,
    this.paymentStatus = 'unpaid',
    required this.status,
    required this.time,
    required this.date,
    required this.createdAt,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Appointment(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? 'طبيب غير معروف',
      doctorImageUrl: data['doctorImageUrl'],
      doctorPhone: data['doctorPhone'], // ✅

      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'مريض غير معروف',
      userImageUrl: data['userImageUrl'],
      userPhone: data['userPhone'], // ✅

      specialtyName: data['specialtyName'] ?? 'تخصص غير معروف',
      workplace: data['workplace'] ?? 'مكان غير معروف',
      payment: data['payment'] ?? data['paymentMethod'] ?? 'غير محدد',
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      status: data['status'] ?? 'pending',
      time: data['time'] ?? '--:--',
      date: data['date'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorImageUrl': doctorImageUrl,
      'doctorPhone': doctorPhone, // ✅

      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'userPhone': userPhone, // ✅

      'specialtyName': specialtyName,
      'workplace': workplace,
      'payment': payment,
      'paymentStatus': paymentStatus,
      'status': status,
      'time': time,
      'date': date,
      'createdAt': createdAt,
    };
  }

  String get formattedDate => DateFormat('dd MMM yyyy', 'ar').format(date.toDate());
  String get formattedTime => time;
}



// نموذج الادوية

class Medication {
  final String id;
  final String name;
  final String dose;
  final String schedule;
  final String next;
  final String userId;
  final List<dynamic> history;
  final String type;
  final String duration;
  final String note;
  final Timestamp createdAt;
  final List<String> times; // ✅ الأوقات الجديدة


  Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.schedule,
    required this.next,
    required this.userId,
    required this.history,
    required this.type,
    required this.duration,
    required this.note,
    required this.createdAt,
    required this.times,

  });

  /// إنشاء النموذج من Firebase
  factory Medication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Medication(
      id: doc.id,
      name: data['name'] ?? 'دواء غير معروف',
      dose: data['dose'] ?? '',
      schedule: data['schedule'] ?? '',
      next: data['next'] ?? '',
      userId: data['userId'] ?? '',
      history: data['history'] ?? [],
      type: data['type'] ?? '',
      duration: data['duration'] ?? '',
      note: data['note'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      times: List<String>.from(data['times'] ?? []), // ✅ قراءة الأوقات

    );
  }

  /// تحويل إلى خريطة لحفظها في Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dose': dose,
      'schedule': schedule,
      'next': next,
      'userId': userId,
      'history': history,
      'type': type,
      'duration': duration,
      'note': note,
      'createdAt': createdAt,
      'times': times, // ✅ حفظ الأوقات

    };
  }
}




class ConsultationModel {
  final String id;
  final String type;
  final String? doctorId;
  final String userId;
  final String? message;
  final Timestamp createdAt;
  final Timestamp? lastMessageTime; // إضافة هذا الحقل
  final bool isActive;
  final String? status;
  final String? doctorName;
  final String? doctorImage;
  final String? userName;
  final String? userImage;
  final String? specialty;
  final String? doctorFcmToken;
  final String? userFcmToken;
  final List<String>? seenBy;
  final bool? hasNewMessage;
  final String? newMessageFor; // إضافة هذا الحقل
  final Map<String, int>? unreadCount; // إضافة هذا الحقل

  ConsultationModel({
    required this.id,
    required this.type,
    this.doctorId,
    required this.userId,
    this.message,
    required this.createdAt,
    this.lastMessageTime,
    this.isActive = true,
    this.status = 'pending',
    this.doctorName,
    this.doctorImage,
    this.userName,
    this.userImage,
    this.specialty,
    this.doctorFcmToken,
    this.userFcmToken,
    this.seenBy,
    this.hasNewMessage = false,
    this.newMessageFor,
    this.unreadCount,
  });

  factory ConsultationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw StateError('Document data is null for ConsultationModel');
    }

    return ConsultationModel(
      id: doc.id,
      type: data['type'] as String? ?? 'group',
      doctorId: data['doctorId'] as String?,
      userId: data['userId'] as String? ?? '',
      message: data['message'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      lastMessageTime: _parseOptionalTimestamp(data['lastMessageTime']),
      isActive: data['isActive'] as bool? ?? true,
      status: data['status'] as String? ?? 'pending',
      doctorName: data['doctorName'] as String?,
      doctorImage: data['doctorImage'] as String?,
      userName: data['userName'] as String?,
      userImage: data['userImage'] as String?,
      specialty: data['specialty'] as String?,
      doctorFcmToken: data['doctorFcmToken'] as String?,
      userFcmToken: data['userFcmToken'] as String?,
      seenBy: (data['seenBy'] as List?)?.map((e) => e.toString()).toList(),
      hasNewMessage: data['hasNewMessage'] as bool? ?? false,
      newMessageFor: data['newMessageFor'] as String?,
      unreadCount: _parseUnreadCount(data['unreadCount']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'doctorId': doctorId,
      'userId': userId,
      'message': message,
      'createdAt': createdAt,
      'lastMessageTime': lastMessageTime,
      'isActive': isActive,
      'status': status,
      'doctorName': doctorName,
      'doctorImage': doctorImage,
      'userName': userName,
      'userImage': userImage,
      'specialty': specialty,
      'doctorFcmToken': doctorFcmToken,
      'userFcmToken': userFcmToken,
      'seenBy': seenBy,
      'hasNewMessage': hasNewMessage,
      'newMessageFor': newMessageFor,
      'unreadCount': unreadCount,
    };
  }

  bool get isInstant => type == 'instant';
  bool get isGroup => type == 'group';

  static Timestamp _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    return Timestamp.now();
  }

  static Timestamp? _parseOptionalTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    return null;
  }

  static Map<String, int>? _parseUnreadCount(dynamic value) {
    if (value is Map) {
      final Map<String, int> result = {};
      value.forEach((key, value) {
        if (key is String && value is int) {
          result[key] = value;
        }
      });
      return result;
    }
    return null;
  }

  // دالة مساعدة للحصول على عدد الرسائل غير المقروءة للمستخدم
  int getUnreadCountForUser(String userId) {
    return unreadCount?[userId] ?? 0;
  }

  // دالة مساعدة للتحقق إذا كانت هناك رسائل جديدة للمستخدم
  bool hasNewMessagesForUser(String userId) {
    return hasNewMessage == true && newMessageFor == userId;
  }
}


//نموذج استشارة فديو
class VideoConsultationModel {
  final String id;              // معرف المكالمة
  final String doctorId;        // معرف الطبيب
  final String userId;          // معرف المستخدم (المريض)
  final String callRoomId;      // معرف غرفة المكالمة (مثلاً من zego أو jitsi)
  final DateTime startTime;     // وقت بداية المكالمة
  final DateTime? endTime;      // وقت نهاية المكالمة (اختياري)
  final String status;          // حالة المكالمة: pending, active, ended
  final String? doctorFcmToken; // توكن إشعارات للطبيب
  final String? userFcmToken;   // توكن إشعارات للمريض

  VideoConsultationModel({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.callRoomId,
    required this.startTime,
    this.endTime,
    this.status = 'pending',
    this.doctorFcmToken,
    this.userFcmToken,
  });

  factory VideoConsultationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return VideoConsultationModel(
      id: documentId,
      doctorId: map['doctorId'] as String,
      userId: map['userId'] as String,
      callRoomId: map['callRoomId'] as String,
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
      status: map['status'] as String? ?? 'pending',
      doctorFcmToken: map['doctorFcmToken'] as String?,
      userFcmToken: map['userFcmToken'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'userId': userId,
      'callRoomId': callRoomId,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'doctorFcmToken': doctorFcmToken,
      'userFcmToken': userFcmToken,
    };
  }
}



class LocalNotificationModel {
  final String title;
  final String body;
  final DateTime scheduledTime;
  final String type; // "medicine", "appointment", etc.

  LocalNotificationModel({
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime.toIso8601String(),
      'type': type,
    };
  }

  factory LocalNotificationModel.fromMap(Map<String, dynamic> map) {
    return LocalNotificationModel(
      title: map['title'],
      body: map['body'],
      scheduledTime: DateTime.parse(map['scheduledTime']),
      type: map['type'],
    );
  }
}



//نموذج الاشعارات

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? consultationId;
  final String? senderId;
  final String? senderName;
  final bool isRead;
  final Timestamp createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.consultationId,
    this.senderId,
    this.senderName,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      type: data['type'] as String? ?? 'general',
      title: data['title'] as String? ?? 'إشعار جديد',
      body: data['body'] as String? ?? '',
      consultationId: data['consultationId'] as String?,
      senderId: data['senderId'] as String?,
      senderName: data['senderName'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'body': body,
      'consultationId': consultationId,
      'senderId': senderId,
      'senderName': senderName,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }
}
