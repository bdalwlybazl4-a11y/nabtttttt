import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import '../../../../core/config/medical_theme.dart';
import '../../../../core/widgets/premium_ui.dart';
import '../widgets/message_reactions_widget.dart';
import '../../services/message_reactions_service.dart';

class ConsultationScreen extends StatefulWidget {
  final String consultationId;
  final String doctorUid;
  final String patientUid;
  final String doctorName;
  final String patientName;
  final bool isDoctor;
  final String doctorImage;
  final String userImage;

  const ConsultationScreen({
    Key? key,
    required this.consultationId,
    required this.doctorUid,
    required this.patientUid,
    required this.isDoctor,
    required this.doctorImage,
    required this.userImage,
    required this.doctorName,
    required this.patientName,
  }) : super(key: key);

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  // ✅ Logging Tag
  static const String _logTag = '💬 [Consultation Screen]';
  static const bool _preferInlineAttachments = true;

  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final picker = ImagePicker();

  // State variables
  Map<String, dynamic>? doctorData;
  Map<String, dynamic>? patientData;
  File? selectedMedia;
  String? mediaType;
  String? fileName;
  DocumentSnapshot? replyToMessage;
  bool isSending = false;
  final Map<String, GlobalKey> _messageKeys = {};
  String? _replyingToMessageId;
  String? _highlightedMessageId;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  DocumentSnapshot? _lastMessage;
  DocumentSnapshot? _lastLoadedMessage;
  final Set<String> _visibleMessages = {};
  bool _shouldScrollToBottom = true;
  bool _isInitialLoad = true;
  bool _isFirstBuild = true;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _recordingPath;
  String? _playingMessageId;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  final Map<String, String> _inlineAudioFiles = {};
  bool _cloudStorageBlocked = false;

  @override
  void initState() {
    super.initState();
    _logInfo('📱 تم فتح شاشة الاستشارة');
    _logDebug('معرف الاستشارة: ${widget.consultationId}');
    _initializeChat();
    _updateSeenStatus();
    _updateLastSeenTime();
  }

  // عند ظهور الشاشة
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSeenStatus();
  }

  void _initializeChat() {
    _logDebug('جاري تهيئة المحادثة...');
    _loadUsersData();
    _markDeliveredMessages();
    _setupRealTimeUpdates();
    _scrollController.addListener(_scrollListener);
    _configureAudioPlayer();
    _logSuccess('✅ تم تهيئة المحادثة');
  }

  void _configureAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        setState(() {
          _playingMessageId = null;
          _audioPosition = Duration.zero;
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((value) {
      if (mounted) {
        setState(() => _audioDuration = value);
      }
    });
    _audioPlayer.onPositionChanged.listen((value) {
      if (mounted) {
        setState(() => _audioPosition = value);
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final threshold = _scrollController.position.maxScrollExtent - 100;
      if (_scrollController.offset < threshold) {
        _shouldScrollToBottom = false;
      }
    }
  }

  // ========== DATA MANAGEMENT ==========

  Future<void> _loadUsersData() async {
    try {
      _logDebug('📥 جاري تحميل بيانات المستخدمين...');
      _logDebug('الطبيب UID: ${widget.doctorUid}');
      _logDebug('المريض UID: ${widget.patientUid}');

      final doctorSnap = await _firestore.collection('users').doc(widget.doctorUid).get();
      final patientSnap = await _firestore.collection('users').doc(widget.patientUid).get();

      if (mounted) {
        setState(() {
          doctorData = doctorSnap.data();
          patientData = patientSnap.data();
        });

        _logSuccess('✅ تم تحميل بيانات المستخدمين بنجاح');
      }
    } catch (e) {
      _logError('فشل تحميل بيانات المستخدم: $e');
      _showErrorSnackbar('فشل في تحميل بيانات المستخدم');
    }
  }

  // تحديث حالة رؤية الرسائل
  void _updateSeenStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('consultations')
          .doc(widget.consultationId)
          .update({
        'seenBy': FieldValue.arrayUnion([user.uid]),
        'hasNewMessage': false,
        'lastSeenByUser': {
          user.uid: FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      debugPrint('Error updating seen status: $e');
    }
  }

  void _setupRealTimeUpdates() {
    _firestore
        .collection('consultations')
        .doc(widget.consultationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && mounted) {
        final lastMsg = snapshot.docs.first;
        final data = lastMsg.data() as Map<String, dynamic>;

        if (data['senderId'] != _auth.currentUser?.uid) {
          if (data['status'] == 'sent') {
            lastMsg.reference.update({'status': 'delivered'});
          }

          if (_isNearBottom()) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        }
      }
    });
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return false;
    final position = _scrollController.position;
    return position.pixels >= position.maxScrollExtent - 200;
  }

  Future<void> _markDeliveredMessages() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // جلب جميع الرسائل ثم فلترتها محلياً
      final allMessages = await _firestore
          .collection('consultations')
          .doc(widget.consultationId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in allMessages.docs) {
        final data = doc.data();
        if (data['senderId'] != user.uid && data['status'] == 'sent') {
          batch.update(doc.reference, {'status': 'delivered'});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as delivered: $e');
    }
  }

  // ========== MESSAGES MANAGEMENT ==========

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;

    setState(() => _isLoadingMore = true);

    try {
      final query = _firestore
          .collection('consultations')
          .doc(widget.consultationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastLoadedMessage ?? _lastMessage!)
          .limit(15);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() => _hasMoreMessages = false);
      } else {
        _lastLoadedMessage = snapshot.docs.last;
      }
    } catch (e) {
      _showErrorSnackbar('فشل في تحميل المزيد من الرسائل');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _scrollToBottom({bool animated = true}) async {
    if (!_scrollController.hasClients) return;

    // انتظار صغير لضمان أن الـ ListView قد تم بناؤه بالكامل
    await Future.delayed(const Duration(milliseconds: 100));

    if (animated) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _scrollToMessage(String messageId) async {
    // محاولة التمرير مباشرة إذا كانت الرسالة محملة
    if (_messageKeys.containsKey(messageId)) {
      final context = _messageKeys[messageId]!.currentContext;
      if (context != null) {
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.35,
        );

        // إبراز الرسالة مؤقتاً
        if (mounted) {
          setState(() => _highlightedMessageId = messageId);
          await Future.delayed(const Duration(seconds: 3));
          if (mounted) setState(() => _highlightedMessageId = null);
        }
        return;
      }
    }

    // إذا لم تكن الرسالة محملة، نحمل المزيد من الرسائل
    bool found = false;
    int attempts = 0;
    while (!found && _hasMoreMessages && attempts < 5) {
      attempts++;
      await _loadMoreMessages();
      await Future.delayed(const Duration(milliseconds: 300));

      if (_messageKeys.containsKey(messageId)) {
        final context = _messageKeys[messageId]!.currentContext;
        if (context != null) {
          await Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.35,
          );
          found = true;

          // إبراز الرسالة
          if (mounted) {
            setState(() => _highlightedMessageId = messageId);
            await Future.delayed(const Duration(seconds: 3));
            if (mounted) setState(() => _highlightedMessageId = null);
          }
        }
      }
    }

    if (!found) {
      _showErrorSnackbar('لم يتم العثور على الرسالة');
    }
  }

  void _onReplyToMessage(DocumentSnapshot message) {
    setState(() {
      replyToMessage = message;
      _replyingToMessageId = message.id;
    });
  }

  void _handleMessageVisibility(String messageId, bool isVisible) {
    if (isVisible) {
      _visibleMessages.add(messageId);
      _markMessageAsRead(messageId);
    } else {
      _visibleMessages.remove(messageId);
    }
  }

  Future<void> _markMessageAsRead(String messageId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messageRef = _firestore
        .collection('consultations')
        .doc(widget.consultationId)
        .collection('messages')
        .doc(messageId);

    final message = await messageRef.get();
    final data = message.data() as Map<String, dynamic>?;

    if (data != null &&
        data['senderId'] != user.uid &&
        data['status'] != 'read') {
      await messageRef.update({'status': 'read'});
    }
  }

  Future<void> _handleLongPress(DocumentSnapshot msg) async {
    final data = msg.data() as Map<String, dynamic>;
    if (data['senderId'] != _auth.currentUser?.uid) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الرسالة'),
        content: const Text('هل تريد حذف الرسالة من الطرفين؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await msg.reference.delete();
      } catch (e) {
        _showErrorSnackbar('فشل في حذف الرسالة');
      }
    }
  }

  // ========== MESSAGE SENDING ==========

Future<DocumentSnapshot<Map<String, dynamic>>> _consultationDoc() =>
      _firestore.collection('consultations').doc(widget.consultationId).get();

  bool _isBlockedData(Map<String, dynamic>? data) {
    final blockedBy = (data?['blockedBy'] as List?)?.cast<String>() ?? const <String>[];
    return blockedBy.isNotEmpty;
  }

  Future<bool> _ensureChatNotBlocked() async {
    final snapshot = await _consultationDoc();
    final data = snapshot.data();
    if (_isBlockedData(data)) {
      final blockedBy = ((data?['blockedBy'] as List?)?.cast<String>() ?? const <String>[]);
      final current = _auth.currentUser?.uid;
      final message = blockedBy.contains(current)
          ? 'لقد قمت بحظر هذه المحادثة. قم بإلغاء الحظر لإرسال رسائل جديدة.'
          : 'لا يمكن إرسال رسائل جديدة لأن الطرف الآخر قام بحظر هذه المحادثة.';
      _showErrorSnackbar(message);
      return false;
    }
    return true;
  }

  Future<void> _toggleBlockConversation({required bool block}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('consultations').doc(widget.consultationId).set({
      'blockedBy': block ? FieldValue.arrayUnion([user.uid]) : FieldValue.arrayRemove([user.uid]),
      'isBlocked': block,
      'blockUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _showSuccessSnackbar(block ? 'تم حظر المستخدم. لن يستطيع أي طرف إرسال رسائل.' : 'تم إلغاء الحظر ويمكن متابعة المحادثة.');
  }

  // عند إرسال رسالة جديدة، تحديث حالة الرسائل الجديدة
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty && selectedMedia == null) return;
    if (isSending) return;

    setState(() {
      isSending = true;
      _shouldScrollToBottom = true;
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() => isSending = false);
      return;
    }
    if (!await _ensureChatNotBlocked()) {
      setState(() => isSending = false);
      return;
    }

    String? downloadUrl;
    String? inlineAudioBase64;
    String? inlineFileBase64;
    String type = 'text';

    try {
      if (selectedMedia != null && mediaType != null) {
        type = mediaType!;
        final skipCloudUpload = _preferInlineAttachments || _cloudStorageBlocked;
        downloadUrl = skipCloudUpload ? null : await _uploadFile();

        final shouldUseInlineFallback = _preferInlineAttachments ||
            _cloudStorageBlocked ||
            downloadUrl == null ||
            (_lastUploadError != null &&
                _isStoragePlanRestricted(_lastUploadError!));

        if (type == 'audio' && shouldUseInlineFallback) {
          inlineAudioBase64 = await _encodeInlineAudio(selectedMedia!);
          if (inlineAudioBase64.isEmpty) {
            throw Exception('inline_audio_encoding_failed');
          }
          type = 'audio_inline';
          downloadUrl = null;
        } else if (type != 'audio' && shouldUseInlineFallback) {
          inlineFileBase64 = await _encodeInlineFile(selectedMedia!);
          if (inlineFileBase64.isEmpty) {
            throw Exception('inline_file_encoding_failed');
          }
          type = '${type}_inline';
          downloadUrl = null;
        }

        if (downloadUrl == null && inlineAudioBase64 == null && inlineFileBase64 == null) {
          throw Exception('failed_to_upload_and_inline_fallback');
        } else {
          if (downloadUrl == null && _lastUploadError != null && mounted) {
            _showErrorSnackbar('تعذر الرفع للسحابة، تم الإرسال كمرفق داخل الرسالة');
          }
        }
      }

      await _firestore
          .collection('consultations')
          .doc(widget.consultationId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderName': '${widget.isDoctor ? 'الطبيب' : 'المريض'}: ${getUserName(widget.isDoctor ? doctorData : patientData, widget.isDoctor)}',
        'senderImage': getUserImageUrl(widget.isDoctor ? doctorData : patientData),
        'text': _messageController.text.trim(),
        'fileUrl': downloadUrl,
        'audioBase64': inlineAudioBase64,
        'fileBase64': inlineFileBase64,
        'fileName': fileName,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'replyTo': replyToMessage?.id,
      });

      await _updateLastMessage();

      // تحديث حالة الرسائل الجديدة للمستخدم الآخر مع نظام العد
      final otherUserId = widget.isDoctor ? widget.patientUid : widget.doctorUid;
      await _firestore
          .collection('consultations')
          .doc(widget.consultationId)
          .update({
        'hasNewMessage': true,
        'newMessageFor': otherUserId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'seenBy': FieldValue.arrayRemove([otherUserId]), // إزالة المستخدم الآخر من seenBy
        'unreadCount.$otherUserId': FieldValue.increment(1), // زيادة العداد للمستخدم الآخر
      });

      _resetMessageState();

      await Future.delayed(const Duration(milliseconds: 200));
      await _scrollToBottom();
    } catch (e) {
      setState(() => isSending = false);
      _showErrorSnackbar('فشل في إرسال الرسالة');
    }
  }

  Future<void> _startRecording() async {
    try {
      final micGranted = await _requestMicrophonePermission();
      if (!micGranted) {
        _showErrorSnackbar('يلزم إذن الميكروفون لتسجيل الرسائل الصوتية');
        return;
      }

      if (await _audioRecorder.hasPermission()) {
        final path = '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,

          ),
          path: path,
        );
        if (mounted) {
          setState(() {
            _isRecording = true;
            _recordingPath = path;
          });
        }
      } else {
        _showErrorSnackbar('يلزم إذن الميكروفون لتسجيل الرسائل الصوتية');
      }
    } catch (e) {
      _logError('تعذر بدء التسجيل الصوتي: $e');
      _showErrorSnackbar('تعذر بدء التسجيل الصوتي');
    }
  }

  Future<void> _stopAndAttachRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (!mounted) return;
      setState(() => _isRecording = false);
      if (path == null) return;
      final recordingFile = File(path);
      if (!await recordingFile.exists()) {
        _showErrorSnackbar('تعذر العثور على ملف التسجيل');
        return;
      }
      setState(() {
        selectedMedia = recordingFile;
        mediaType = 'audio';
        fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      });
      _showSuccessSnackbar('تم إرفاق التسجيل الصوتي، يمكنك كتابة رسالة ثم الإرسال');
    } catch (e) {
      _logError('تعذر إرسال التسجيل الصوتي: $e');
      if (mounted) setState(() => _isRecording = false);
      _showErrorSnackbar('تعذر إرفاق التسجيل الصوتي');
    }
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecording) {
      await _stopAndAttachRecording();
      return;
    }
    await _startRecording();
  }

  Future<void> _playOrPauseAudio({
    required String messageId,
    String? audioUrl,
    String? inlineAudioBase64,
  }) async {
    try {
      if (_playingMessageId == messageId) {
        await _audioPlayer.pause();
        setState(() => _playingMessageId = null);
        return;
      }
      if (audioUrl == null && inlineAudioBase64 == null) {
        _showErrorSnackbar('لا يوجد ملف صوتي للتشغيل');
        return;
      }
      await _audioPlayer.stop();
      if (audioUrl != null && audioUrl.isNotEmpty) {
        final localPath = await _downloadRemoteAudioToFile(
          messageId: messageId,
          audioUrl: audioUrl,
        );

        if (localPath != null) {
          await _audioPlayer.play(DeviceFileSource(localPath));
        } else if (inlineAudioBase64 != null) {
          final path = await _createInlineAudioFile(
            messageId: messageId,
            base64Data: inlineAudioBase64,
          );
          await _audioPlayer.play(DeviceFileSource(path));
        } else {
          _showErrorSnackbar('تعذر تحميل الملف الصوتي من الرابط');
          return;
        }
      } else {
        final path = await _createInlineAudioFile(
          messageId: messageId,
          base64Data: inlineAudioBase64!,
        );
        await _audioPlayer.play(DeviceFileSource(path));
      }
      setState(() => _playingMessageId = messageId);
    } catch (_) {
      _showErrorSnackbar('تعذر تشغيل الرسالة الصوتية');
    }
  }

  Future<String?> _downloadRemoteAudioToFile({
    required String messageId,
    required String audioUrl,
  }) async {
    try {
      final response = await http.get(Uri.parse(audioUrl));
      if (response.statusCode != 200) return null;

      final path = '${Directory.systemTemp.path}/remote_voice_$messageId.m4a';
      final file = File(path);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      _inlineAudioFiles['remote_$messageId'] = path;
      return path;
    } catch (_) {
      return null;
    }
  }

  bool _isStoragePlanRestricted(Object e) {
    final message = e.toString().toLowerCase();
    return message.contains('code\": 402') ||
        message.contains('httpresult: 402') ||
        message.contains('http result code and inner exception') ||
        message.contains('-13000') ||
        message.contains('spark pricing plan') ||
        message.contains('no longer supports') ||
        message.contains('terminated the upload session');
  }

  Object? _lastUploadError;

  Future<String> _encodeInlineAudio(File audioFile) async {
    final bytes = await audioFile.readAsBytes();
    return base64Encode(bytes);
  }

  Future<String> _encodeInlineFile(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<String> _createInlineAudioFile({
    required String messageId,
    required String base64Data,
  }) async {
    if (_inlineAudioFiles.containsKey(messageId)) {
      return _inlineAudioFiles[messageId]!;
    }

    final bytes = base64Decode(base64Data);
    final path = '${Directory.systemTemp.path}/inline_voice_$messageId.m4a';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    _inlineAudioFiles[messageId] = path;
    return path;
  }
  Future<String?> _uploadFile() async {
    if (_cloudStorageBlocked) return null;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    _lastUploadError = null;

    try {
      if (selectedMedia == null || !await selectedMedia!.exists()) {
        throw Exception('selected_media_not_found');
      }

      final extension = selectedMedia!.path.split('.').last.toLowerCase();
      final contentType = _resolveContentType(mediaType, extension);
      final ref = FirebaseStorage.instance.ref(
        'consultations/${widget.consultationId}/files/${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );

      final uploadTask = ref.putFile(
        selectedMedia!,
        SettableMetadata(contentType: contentType),
      );

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }

      return downloadUrl;
    } catch (e) {
      _lastUploadError = e;
      if (_isStoragePlanRestricted(e)) {
        _cloudStorageBlocked = true;
      }
      _logError('فشل رفع الملف: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
      return null;
    }
  }

  Future<void> _updateLastMessage() async {
    await _firestore
        .collection('consultations')
        .doc(widget.consultationId)
        .update({
      'lastMessage': _messageController.text.trim().isNotEmpty
          ? _messageController.text.trim()
          : fileName ?? 'ملف مرفق',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  void _resetMessageState() {
    setState(() {
      _messageController.clear();
      selectedMedia = null;
      mediaType = null;
      fileName = null;
      replyToMessage = null;
      isSending = false;
    });
  }

  // تحديث وقت الرؤية الأخير عند فتح المحادثة
  Future<void> _updateLastSeenTime() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('consultations')
          .doc(widget.consultationId)
          .update({
        'seenBy': FieldValue.arrayUnion([user.uid]),
        'lastSeenByUser.${user.uid}': FieldValue.serverTimestamp(),
        'hasNewMessage': false,
        'newMessageFor': null,
        'unreadCount.${user.uid}': 0,
      });
    } catch (e) {
      debugPrint('Error updating last seen time: $e');
    }
  }

  // دالة محسنة لحساب عدد الرسائل غير المقروءة
  Stream<int> _getUnreadMessagesCount(String consultationId, String userId) {
    return _firestore
        .collection('consultations')
        .doc(consultationId)
        .snapshots()
        .asyncMap((consultationDoc) async {
      final consultationData = consultationDoc.data() as Map<String, dynamic>?;

      if (consultationData == null) return 0;

      // الطريقة الأولى: استخدام نظام العد المخزن في مستند الاستشارة
      final unreadCountMap = consultationData['unreadCount'] as Map<String, dynamic>? ?? {};
      final storedUnreadCount = (unreadCountMap[userId] as int? ?? 0);

      // إذا كان النظام المخزن يعمل، نستخدمه
      if (storedUnreadCount > 0) {
        return storedUnreadCount;
      }

      // الطريقة الثانية: الحساب من الرسائل (كحل بديل)
      try {
        final messagesSnapshot = await _firestore
            .collection('consultations')
            .doc(consultationId)
            .collection('messages')
            .where('timestamp', isGreaterThan: Timestamp.now().toDate().subtract(const Duration(days: 30)))
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();

        int calculatedCount = 0;
        final lastSeenTime = await _getLastSeenTime(consultationData, userId);

        for (var doc in messagesSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final messageTime = (data['timestamp'] as Timestamp).toDate();

          // إذا كانت الرسالة من المستخدم الآخر وبعد وقت الرؤية الأخير
          if (data['senderId'] != userId) {
            if (lastSeenTime == null || messageTime.isAfter(lastSeenTime)) {
              calculatedCount++;
            } else {
              break; // توقف عند الوصول لرسائل قديمة تم رؤيتها
            }
          }
        }

        return calculatedCount;
      } catch (e) {
        debugPrint('Error calculating unread count: $e');
        return storedUnreadCount;
      }
    });
  }

// دالة مساعدة للحصول على وقت الرؤية الأخير
  Future<DateTime?> _getLastSeenTime(Map<String, dynamic> consultationData, String userId) async {
    try {
      final seenBy = consultationData['seenBy'] as List<dynamic>?;

      // إذا كان المستخدم لم ير المحادثة مطلقاً
      if (seenBy == null || !seenBy.contains(userId)) {
        return null;
      }

      // محاولة الحصول من lastSeenByUser إذا كان موجوداً
      final lastSeenByUser = consultationData['lastSeenByUser'] as Map<String, dynamic>?;
      if (lastSeenByUser != null && lastSeenByUser[userId] != null) {
        final lastSeenTimestamp = lastSeenByUser[userId] as Timestamp;
        return lastSeenTimestamp.toDate();
      }

      // استخدام وقت إنشاء المحادثة كبديل
      final createdAt = consultationData['createdAt'] as Timestamp?;
      return createdAt?.toDate();
    } catch (e) {
      debugPrint('Error getting last seen time: $e');
      return null;
    }
  }

  // ========== CALL HANDLING ==========

  /// ✅ بدء مكالمة فيديو
  Future<void> _initiateVideoCall(BuildContext context) async {
    try {
      _logInfo('📹 محاولة بدء مكالمة فيديو...');
      _logDebug('⏳ جاري التحقق من الجاهزية...');

      // تأخير صغير لضمان تهيئة Zego بشكل كامل
      await Future.delayed(const Duration(milliseconds: 500));

      if (widget.isDoctor) {
        _logDebug('👨‍⚕️ الدور: طبيب');
        if (patientData == null) {
          _logError('❌ بيانات المريض غير متوفرة');
          _showErrorSnackbar('خطأ: بيانات المريض غير متوفرة');
          return;
        }

        _logDebug('📱 المستقبل: ${widget.patientName}');
        _logDebug('🔑 معرف المكالمة: ${widget.consultationId}');

        await ZegoUIKitPrebuiltCallInvitationService().send(
          invitees: [
            ZegoCallUser(
              widget.patientUid,
              widget.patientName,
            ),
          ],
          isVideoCall: true,
          callID: widget.consultationId,
        );
      } else {
        _logDebug('👤 الدور: مريض');
        if (doctorData == null) {
          _logError('❌ بيانات الطبيب غير متوفرة');
          _showErrorSnackbar('خطأ: بيانات الطبيب غير متوفرة');
          return;
        }

        _logDebug('📱 المستقبل: ${widget.doctorName}');
        _logDebug('🔑 معرف المكالمة: ${widget.consultationId}');

        await ZegoUIKitPrebuiltCallInvitationService().send(
          invitees: [
            ZegoCallUser(
              widget.doctorUid,
              widget.doctorName,
            ),
          ],
          isVideoCall: true,
          callID: widget.consultationId,
        );
      }

      _logSuccess('✅ تم إرسال دعوة مكالمة فيديو بنجاح! في انتظار الرد...');
      _showSuccessSnackbar('✅ تم إرسال الدعوة\n⏳ في انتظار رد المستقبل...');
    } catch (e) {
      _logError('❌ خطأ في بدء مكالمة فيديو: $e');
      String errorMsg = 'فشل إرسال الدعوة';

      // معالجة خاصة للأخطاء
      if (e.toString().contains('107026')) {
        errorMsg = '❌ المستقبل غير متاح\n\nتأكد من تسجيله الدخول';
      } else if (e.toString().contains('timeout')) {
        errorMsg = '⏱️ انتهت مهلة الزمن\nحاول مجدداً';
      }

      _showErrorSnackbar(errorMsg);
    }
  }

  /// ✅ بدء مكالمة صوتية
  Future<void> _initiateAudioCall(BuildContext context) async {
    try {
      _logInfo('📞 محاولة بدء مكالمة صوتية...');
      _logDebug('⏳ جاري التحقق من الجاهزية...');

      // تأخير صغير لضمان تهيئة Zego بشكل كامل
      await Future.delayed(const Duration(milliseconds: 500));

      if (widget.isDoctor) {
        _logDebug('👨‍⚕️ الدور: طبيب');
        if (patientData == null) {
          _logError('❌ بيانات المريض غير متوفرة');
          _showErrorSnackbar('خطأ: بيانات المريض غير متوفرة');
          return;
        }

        _logDebug('📱 المستقبل: ${widget.patientName}');
        _logDebug('🔑 معرف المكالمة: ${widget.consultationId}');

        await ZegoUIKitPrebuiltCallInvitationService().send(
          invitees: [
            ZegoCallUser(
              widget.patientUid,
              widget.patientName,
            ),
          ],
          isVideoCall: false,
          callID: widget.consultationId,
        );
      } else {
        _logDebug('👤 الدور: مريض');
        if (doctorData == null) {
          _logError('❌ بيانات الطبيب غير متوفرة');
          _showErrorSnackbar('خطأ: بيانات الطبيب غير متوفرة');
          return;
        }

        _logDebug('📱 المستقبل: ${widget.doctorName}');
        _logDebug('🔑 معرف المكالمة: ${widget.consultationId}');

        await ZegoUIKitPrebuiltCallInvitationService().send(
          invitees: [
            ZegoCallUser(
              widget.doctorUid,
              widget.doctorName,
            ),
          ],
          isVideoCall: false,
          callID: widget.consultationId,
        );
      }

      _logSuccess('✅ تم إرسال دعوة مكالمة صوتية بنجاح! في انتظار الرد...');
      _showSuccessSnackbar('✅ تم إرسال الدعوة\n⏳ في انتظار رد المستقبل...');
    } catch (e) {
      _logError('❌ خطأ في بدء مكالمة صوتية: $e');
      String errorMsg = 'فشل إرسال الدعوة';

      // معالجة خاصة للأخطاء
      if (e.toString().contains('107026')) {
        errorMsg = '❌ المستقبل غير متاح\n\nتأكد من تسجيله الدخول';
      } else if (e.toString().contains('timeout')) {
        errorMsg = '⏱️ انتهت مهلة الزمن\nحاول مجدداً';
      }

      _showErrorSnackbar(errorMsg);
    }
  }

  // ========== MEDIA HANDLING ==========

  Future<void> _pickMedia(String type) async {
    try {
      final hasPermission = await _ensureMediaPermission(type);
      if (!hasPermission) {
        _showErrorSnackbar('تم رفض صلاحية الوصول للوسائط');
        return;
      }

      if (type == 'image') {
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          setState(() {
            selectedMedia = File(picked.path);
            mediaType = 'image';
            fileName = picked.name;
          });
        }
      } else if (type == 'video') {
        final picked = await picker.pickVideo(source: ImageSource.gallery);
        if (picked != null) {
          setState(() {
            selectedMedia = File(picked.path);
            mediaType = 'video';
            fileName = picked.name;
          });
        }
      } else if (type == 'file') {
        final result = await FilePicker.platform.pickFiles();
        if (result != null && result.files.single.path != null) {
          setState(() {
            selectedMedia = File(result.files.single.path!);
            mediaType = 'file';
            fileName = result.files.single.name;
          });
        }
      } else if (type == 'camera') {
        final picked = await picker.pickImage(source: ImageSource.camera);
        if (picked != null) {
          setState(() {
            selectedMedia = File(picked.path);
            mediaType = 'image';
            fileName = picked.name;
          });
        }
      }
    } catch (e) {
      _logError('فشل اختيار الملف: $e');
      _showErrorSnackbar('فشل في اختيار الملف');
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;

    status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> _ensureMediaPermission(String type) async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    if (type == 'camera') {
      final camera = await Permission.camera.request();
      return camera.isGranted;
    }

    if (Platform.isAndroid) {
      // ImagePicker/Photo Picker على أندرويد غالباً يدير صلاحية المعرض بنفسه.
      // لا نمنع المستخدم مسبقاً إلا في الكاميرا.
      return true;
    }

    if (Platform.isIOS) {
      final photos = await Permission.photos.request();
      return photos.isGranted || photos.isLimited;
    }
    return true;
  }

  String _resolveContentType(String? type, String extension) {
    switch (type) {
      case 'image':
        return 'image/$extension';
      case 'video':
        return 'video/$extension';
      case 'audio':
        return extension == 'aac' ? 'audio/aac' : 'audio/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.image, color: Colors.blue),
                  ),
                  title: const Text('صورة من المعرض'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia('image');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.videocam, color: Colors.purple),
                  ),
                  title: const Text('فيديو من المعرض'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia('video');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.insert_drive_file, color: Colors.green),
                  ),
                  title: const Text('ملف من الجهاز'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia('file');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.orange),
                  ),
                  title: const Text('التقاط صورة'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia('camera');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========== UI COMPONENTS ==========

  Widget _buildStatusIcon(String? status, bool isMe, ThemeData theme) {
    final color = isMe ? theme.disabledColor : theme.disabledColor;
    switch (status) {
      case 'read':
        return Icon(Icons.done_all, size: 16, color: MedicalTheme.primaryMedicalBlue);
      case 'delivered':
        return Icon(Icons.done_all, size: 16, color: color);
      default:
        return Icon(Icons.done, size: 16, color: color);
    }
  }

  Widget _buildReplyPreview(DocumentSnapshot? replyMsg, ThemeData theme, bool isDarkMode) {
    if (replyMsg == null) return const SizedBox.shrink();
    final data = replyMsg.data() as Map<String, dynamic>;
    final type = data['type'] as String? ?? 'text';
    final content = data['text'] as String? ?? data['fileName'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? MedicalTheme.primaryMedicalBlueLight.withOpacity(0.1)
            : MedicalTheme.primaryMedicalBlue.withOpacity(0.05),
        border: Border(
          top: BorderSide(
            color: isDarkMode ? MedicalTheme.dividerDark : MedicalTheme.dividerLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 20, color: MedicalTheme.primaryMedicalBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              type == 'text' ? content : '📎 $content',
              style: const TextStyle(
                color: MedicalTheme.primaryMedicalBlue,
                fontFamily: 'Tajawal',
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: MedicalTheme.darkGray500),
            onPressed: () => setState(() => replyToMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _previewMedia(ThemeData theme, bool isDarkMode) {
    if (selectedMedia == null || mediaType == null) return const SizedBox();

    Widget preview;
    if (mediaType == 'image') {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(selectedMedia!, height: 100, fit: BoxFit.cover),
      );
    } else if (mediaType == 'video') {
      preview = Row(
        children: [
          Icon(Icons.videocam, size: 30, color: theme.primaryColor),
          const SizedBox(width: 8),
          Text('فيديو مرفق', style: theme.textTheme.bodyMedium),
        ],
      );
    } else {
      preview = Row(
        children: [
          Icon(Icons.insert_drive_file, size: 30, color: theme.primaryColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fileName ?? 'ملف مرفق',
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (_isUploading)
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[300],
            color: theme.primaryColor,
          ),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(child: preview),
              IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error),
                onPressed: () {
                  setState(() {
                    selectedMedia = null;
                    mediaType = null;
                    fileName = null;
                    _isUploading = false;
                    _uploadProgress = 0.0;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput(ThemeData theme, bool isDarkMode) {
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(30);
    final canSend = _messageController.text.trim().isNotEmpty || selectedMedia != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(isDarkMode ? .92 : .98),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyToMessage != null)
            _buildReplyPreview(replyToMessage, theme, isDarkMode),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ========== زر المرفقات المحسّن ==========
              Container(
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                decoration: BoxDecoration(
                  color: Color.lerp(colorScheme.primaryContainer, colorScheme.secondaryContainer, .35)!.withOpacity(isDarkMode ? .36 : .72),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showAttachmentMenu(context),
                    borderRadius: BorderRadius.circular(40),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.attach_file_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ========== مربع الإدخال المحسّن ==========
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color.lerp(colorScheme.primaryContainer, colorScheme.secondaryContainer, .35)!.withOpacity(isDarkMode ? .36 : .72),
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textInputAction: TextInputAction.newline,
                          maxLines: null,
                          minLines: 1,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: 'اكتب رسالة...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.disabledColor.withOpacity(0.5),
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          onChanged: (value) {
                            setState(() {}); // تحديث لتغيير حالة الزر
                          },
                          onSubmitted: (_) {
                            if (!isSending && _messageController.text.isNotEmpty) {
                              _sendMessage();
                            }
                          },
                        ),
                      ),

                      // ========== زر الإرسال الواضح والمحسّن ==========
                      Container(
                        margin: const EdgeInsets.only(left: 4, bottom: 2),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(scale: animation, child: child);
                          },
                          child: isSending
                              ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(
                                  theme.primaryColor,
                                ),
                              ),
                            ),
                          )
                              : Material(
                            color: canSend ? colorScheme.primary : Color.lerp(colorScheme.primaryContainer, colorScheme.secondaryContainer, .35)!,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              key: const ValueKey("send_button"),
                              onTap: canSend ? _sendMessage : null,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(9),
                                child: Icon(
                                  Icons.send_rounded,
                                  color: theme.colorScheme.onPrimary,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!canSend)
                        Container(
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? theme.colorScheme.error.withOpacity(0.15)
                                : colorScheme.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _toggleVoiceRecording,
                            tooltip: _isRecording ? 'إيقاف وإرفاق التسجيل' : 'تسجيل صوتي',
                            icon: Icon(
                              _isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                              color: _isRecording ? colorScheme.error : colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(DocumentSnapshot doc, ThemeData theme, bool isDarkMode) {
    final colorScheme = theme.colorScheme;
    final them = colorScheme;
    final msg = doc.data() as Map<String, dynamic>;
    final msgId = doc.id;
    final isMe = msg['senderId'] == _auth.currentUser?.uid;
    final status = msg['status'] as String?;
    final senderImage = msg['senderImage'] as String? ?? '';
    final text = msg['text'] as String? ?? '';
    final type = msg['type'] as String? ?? 'text';
    final fileUrl = msg['fileUrl'] as String?;
    final fileName = msg['fileName'] as String? ?? '';
    final time = msg['timestamp'] != null
        ? DateFormat('hh:mm a', 'ar').format((msg['timestamp'] as Timestamp).toDate())
        : '';
    final dynamic replyToField = msg['replyTo'];
    final String? replyToId = (replyToField is String) ? replyToField : null;

    final isHighlighted = _highlightedMessageId == msgId;

    if (!_messageKeys.containsKey(msgId)) {
      _messageKeys[msgId] = GlobalKey();
    }

    Widget content;
    final inlineAudioBase64 = msg['audioBase64'] as String?;
    final inlineFileBase64 = msg['fileBase64'] as String?;
    final hasRemoteFile = fileUrl != null && fileUrl.isNotEmpty;
    final hasInlineAudio = inlineAudioBase64 != null && inlineAudioBase64.isNotEmpty;
    final hasInlineFile = inlineFileBase64 != null && inlineFileBase64.isNotEmpty;

    if ((type == 'image' ||
        type == 'video' ||
        type == 'file' ||
        type == 'audio' ||
        type == 'audio_inline' ||
        type == 'image_inline' ||
        type == 'video_inline' ||
        type == 'file_inline') &&
        (hasRemoteFile || hasInlineAudio || hasInlineFile)) {
      List<Widget> contentWidgets = [];

      if (text.isNotEmpty) {
        contentWidgets.add(Text(text, style: theme.textTheme.bodyMedium));
        contentWidgets.add(const SizedBox(height: 8));
      }

      if (type == 'image' || type == 'image_inline') {
        contentWidgets.add(
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                if (hasRemoteFile) {
                  _showFullScreenImage(fileUrl, context);
                }
              },
              child: hasRemoteFile
                  ? Image.network(
                fileUrl,
                width: 250,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 250,
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 250,
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              )
                  : hasInlineFile
                  ? Image.memory(
                base64Decode(inlineFileBase64!),
                width: 250,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 250,
                  height: 200,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Text('تعذر عرض الصورة'),
                ),
              )
                  : Container(
                width: 250,
                height: 200,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: const Text('صورة غير متاحة'),
              ),
            ),
          ),
        );
      } else if (type == 'video' || type == 'video_inline') {
        contentWidgets.add(
          InkWell(
            onTap: () {
              if (hasRemoteFile) {
                _showVideoDialog(fileUrl, context);
              }
            },
            child: Container(
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_filled,
                      size: 50,
                      color: theme.primaryColor),
                  const SizedBox(height: 8),
                  Text(hasRemoteFile ? 'فيديو مرفق' : 'فيديو مرفق (محلي فقط)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.primaryColor,
                      )),
                ],
              ),
            ),
          ),
        );
      } else if (type == 'file' || type == 'file_inline') {
        contentWidgets.add(
          InkWell(
            onTap: () async {
              if (fileUrl != null && fileUrl.isNotEmpty) {
                await launchUrl(Uri.parse(fileUrl));
              } else {
                _showErrorSnackbar('الملف مخزن محلياً داخل الرسالة');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insert_drive_file,
                      size: 30,
                      color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fileName,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium),
                        Text('اضغط لفتح الملف',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.disabledColor,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (type == 'audio' || type == 'audio_inline') {
        contentWidgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Color.lerp(colorScheme.primaryContainer, colorScheme.secondaryContainer, .35)!.withOpacity(isDarkMode ? .36 : .72),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _playOrPauseAudio(
                        messageId: msgId,
                        audioUrl: hasRemoteFile ? fileUrl : null,
                        inlineAudioBase64: hasInlineAudio ? inlineAudioBase64 : null,
                      ),
                      icon: Icon(
                        _playingMessageId == msgId
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: theme.primaryColor,
                        size: 30,
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: Slider(
                        value: (_playingMessageId == msgId && _audioDuration.inMilliseconds > 0)
                            ? _audioPosition.inMilliseconds
                            .clamp(0, _audioDuration.inMilliseconds)
                            .toDouble()
                            : 0,
                        max: _audioDuration.inMilliseconds > 0
                            ? _audioDuration.inMilliseconds.toDouble()
                            : 1,
                        onChanged: (_playingMessageId == msgId)
                            ? (value) async {
                          try {
                            await _audioPlayer.seek(
                              Duration(milliseconds: value.toInt()),
                            );
                          } catch (_) {
                            _showErrorSnackbar('تعذر تحريك المؤشر الصوتي');
                          }
                        }
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      if (contentWidgets.isEmpty) {
        contentWidgets.add(
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.attach_file),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    fileName.isNotEmpty ? fileName : 'مرفق',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: contentWidgets,
      );
    } else {
      content = Text(
        text.isNotEmpty ? text : 'مرفق غير متاح',
        style: theme.textTheme.bodyMedium,
      );
    }

    return VisibilityDetector(
      key: Key(msgId),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          _handleMessageVisibility(msgId, true);
        } else {
          _handleMessageVisibility(msgId, false);
        }
      },
      child: FutureBuilder<DocumentSnapshot?>(
        future: replyToId != null
            ? _firestore
            .collection('consultations')
            .doc(widget.consultationId)
            .collection('messages')
            .doc(replyToId)
            .get()
            : Future.value(null),
        builder: (context, snapshot) {
          final replyData = snapshot.data?.data() as Map<String, dynamic>?;
          final replyText = replyData?['text'] as String? ?? '';
          final replyFileName = replyData?['fileName'] as String? ?? '';

          final replyWidget = snapshot.hasData && replyToId != null
              ? GestureDetector(
            onTap: () async {
              setState(() => _highlightedMessageId = replyToId);
              await _scrollToMessage(replyToId!);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? theme.primaryColor.withOpacity(0.2)
                    : theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      replyText.isNotEmpty ? replyText : replyFileName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
              : const SizedBox.shrink();

          Future<void> onDoubleTapReaction() async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                const emojis = ['❤️', '👍', '🙏', '😢', '😮', '😂'];
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: Wrap(
                      spacing: 12,
                      children: emojis.map((emoji) {
                        return InkWell(
                          onTap: () => Navigator.pop(context, emoji),
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.45),
                              shape: BoxShape.circle,
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            );

            if (selected == null) return;
            await MessageReactionsService.toggleReaction(
              consultationId: widget.consultationId,
              messageId: msgId,
              emoji: selected,
            );
            if (mounted) setState(() {});
          }

          return GestureDetector(
            onDoubleTap: onDoubleTapReaction,
            onLongPress: () => _handleLongPress(doc),
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
                _onReplyToMessage(doc);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              key: _messageKeys[msgId],
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  // ========== صورة المستخدم (اليسار للرسائل الواردة) ==========
                  if (!isMe) ...[
                    _buildUserAvatar(
                      imageUrl: senderImage,
                      radius: 16,
                      backgroundColor: theme.primaryColor.withOpacity(0.3),
                      fallbackIconColor: theme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                  ],

                  // ========== الفقاعة ==========
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: Column(
                        crossAxisAlignment:
                        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? theme.primaryColor.withOpacity(0.2)
                                  : isMe
                                  ? them.primary
                                  : isDarkMode
                                  ? Color.lerp(theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer, .35)!
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isMe ? 18 : 6),
                                bottomRight: Radius.circular(isMe ? 6 : 18),
                              ),
                              boxShadow: [
                                if (!isDarkMode && !isMe)
                                  BoxShadow(
                                    color: theme.colorScheme.shadow.withOpacity(0.10),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                replyWidget,
                                if (text.isNotEmpty || fileUrl != null) content,
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                Text(
                                  time,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: theme.disabledColor,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  _buildStatusIcon(status, isMe, theme),
                                ],
                              ],
                            ),
                          ),
                          MessageReactionsWidget(
                            consultationId: widget.consultationId,
                            messageId: msgId,
                            showAddButton: false,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ========== صورة المستخدم (اليمين للرسائل المرسلة) ==========
                  if (isMe) ...[
                    const SizedBox(width: 8),
                    _buildUserAvatar(
                      imageUrl: senderImage,
                      radius: 16,
                      backgroundColor: theme.primaryColor.withOpacity(0.3),
                      fallbackIconColor: theme.primaryColor,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserAvatar({
    required String? imageUrl,
    required double radius,
    required Color backgroundColor,
    required Color fallbackIconColor,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: _buildAvatarImage(
          imageUrl: imageUrl,
          size: radius * 2,
          fallbackIconColor: fallbackIconColor,
        ),
      ),
    );
  }

  Widget _buildAvatarImage({
    required String? imageUrl,
    required double size,
    Color fallbackIconColor = Colors.blue,
  }) {
    if (imageUrl == null || imageUrl.isEmpty || _cloudStorageBlocked) {
      return _buildAvatarFallback(size: size, iconColor: fallbackIconColor);
    }

    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildAvatarFallback(
        size: size,
        iconColor: fallbackIconColor,
      ),
    );
  }

  Widget _buildAvatarFallback({
    required double size,
    required Color iconColor,
  }) {
    return Container(
      width: size,
      height: size,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: size * 0.55,
        color: iconColor,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDarkMode) {
    final userData = widget.isDoctor ? patientData : doctorData;
    final contactName = '${widget.isDoctor ? 'المريض' : 'الطبيب'}: ${getUserName(userData, widget.isDoctor)}';
    final userImageUrl = getUserImageUrl(userData);

    return AppBar(
      backgroundColor: theme.colorScheme.surface.withOpacity(isDarkMode ? .92 : .98),
      elevation: 0,
      iconTheme: IconThemeData(color: theme.colorScheme.primary),
      titleSpacing: 0,
      title: InkWell(
        onTap: () => _showUserInfoDialog(context),
        child: Row(
          children: [
            Hero(
              tag: 'user-${widget.isDoctor ? widget.patientUid : widget.doctorUid}',
              child: _buildUserAvatar(
                imageUrl: userImageUrl,
                radius: 20,
                backgroundColor: theme.primaryColor.withOpacity(0.2),
                fallbackIconColor: theme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('users').doc(widget.isDoctor ? widget.patientUid : widget.doctorUid).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contactName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                        Text('',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.disabledColor,
                            )),
                      ],
                    );
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                  final isOnline = userData?['isOnline'] as bool? ?? false;
                  final lastSeen = userData?['lastSeen'];
                  DateTime? lastSeenTime;

                  if (lastSeen != null) {
                    if (lastSeen is Timestamp) {
                      lastSeenTime = lastSeen.toDate();
                    } else if (lastSeen is Map) {
                      final seconds = lastSeen['seconds'] as int?;
                      final nanoseconds = lastSeen['nanoseconds'] as int?;
                      if (seconds != null) {
                        lastSeenTime = DateTime.fromMillisecondsSinceEpoch(
                          seconds * 1000 + (nanoseconds ?? 0) ~/ 1000000,
                        );
                      }
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contactName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                      Text(
                        isOnline
                            ? 'متصل الآن'
                            : lastSeenTime != null
                            ? 'آخر ظهور ${DateFormat('hh:mm a', 'ar').format(lastSeenTime)}'
                            : '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isOnline ? theme.colorScheme.secondary : theme.disabledColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [

        IconButton(
          icon: const Icon(Icons.videocam),
          tooltip: 'مكالمة فيديو',
          onPressed: () => _initiateVideoCall(context),
        ),
        // ✅ زر المكالمة الصوتية
        IconButton(
          icon: const Icon(Icons.call),
          tooltip: 'مكالمة صوتية',
          onPressed: () => _initiateAudioCall(context),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleAppBarMenuSelection(value, context),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('معلومات الجهة'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('بحث في المحادثة'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'notifications',
              child: Row(
                children: [
                  Icon(Icons.notifications_none, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('إعدادات الإشعارات'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  const Text('حظر المستخدم'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'unblock',
              child: Row(
                children: [
                  Icon(Icons.lock_open, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  const Text('إلغاء الحظر'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red[400]),
                  const SizedBox(width: 8),
                  const Text('حذف المحادثة'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 60,
              color: theme.disabledColor),
          const SizedBox(height: 16),
          Text('ابدأ المحادثة الآن',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // التمرير للأسفل عند البناء الأول
    if (_isFirstBuild) {
      _isFirstBuild = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _scrollToBottom(animated: false);
        });
      });
    }

    return Scaffold(
      appBar: _buildAppBar(theme, isDarkMode),
      body: PremiumGradientBackground(
        child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('consultations')
                    .doc(widget.consultationId)
                    .collection('messages')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _isInitialLoad) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    _isInitialLoad = false;
                    return _buildEmptyState(theme);
                  }

                  final docs = snapshot.data!.docs;
                  if (_lastMessage == null && docs.isNotEmpty) {
                    _lastMessage = docs.last;
                  }

                  // التمرير للأسفل عند التحميل الأول
                  if (_isInitialLoad && docs.isNotEmpty) {
                    _isInitialLoad = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom(animated: false);
                    });
                  }

                  return _buildMessagesList(docs, theme, isDarkMode);
                },
              ),
            ),
          ),
          if (selectedMedia != null) _previewMedia(theme, isDarkMode),
          _buildMessageInput(theme, isDarkMode),
        ],
      ),
      ),
    );
  }

  Widget _buildMessagesList(List<DocumentSnapshot> docs, ThemeData theme, bool isDarkMode) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            _scrollController.position.pixels ==
                _scrollController.position.minScrollExtent &&
            _hasMoreMessages &&
            !_isLoadingMore) {
          _loadMoreMessages();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        itemCount: docs.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == docs.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                ),
              ),
            );
          }
          final doc = docs[index];
          return _buildMessage(doc, theme, isDarkMode);
        },
        addAutomaticKeepAlives: true,
        cacheExtent: 1000,
      ),
    );
  }

  // ========== UTILITY METHODS ==========

  String? getUserImageUrl(Map<String, dynamic>? userData) {
    if (userData == null) return null;
    return userData['photoURL'] as String? ?? userData['profileImageUrl'] as String?;
  }

  String getUserName(Map<String, dynamic>? userData, bool isDoctor) {
    if (userData == null) return isDoctor ? 'مريض' : 'طبيب';
    return userData['fullName'] as String? ?? (isDoctor ? 'مريض' : 'طبيب');
  }

  String getUserStatus(Map<String, dynamic>? userData) {
    if (userData == null) return '';
    if (userData['isOnline'] as bool? ?? false) return 'متصل الآن';
    if (userData['lastSeen'] != null) {
      final lastSeen = (userData['lastSeen'] as Timestamp).toDate();
      return 'آخر ظهور ${DateFormat('hh:mm a', 'ar').format(lastSeen)}';
    }
    return '';
  }

  void _showFullScreenImage(String imageUrl, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showVideoDialog(String videoUrl, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فيديو مرفق'),
        content: const Text('سيتم فتح الفيديو في متصفح خارجي'),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('فتح'),
            onPressed: () {
              launchUrl(Uri.parse(videoUrl));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showFeatureNotAvailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('هذه الميزة غير متوفرة حالياً'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: MedicalTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _handleAppBarMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'info':
        _showUserInfoDialog(context);
        break;
      case 'search':
        _showSearchDialog(context);
        break;
      case 'notifications':
        _showNotificationSettings(context);
        break;
      case 'block':
        _toggleBlockConversation(block: true);
        break;
      case 'unblock':
        _toggleBlockConversation(block: false);
        break;
      case 'delete':
        _showDeleteConfirmationDialog(context);
        break;
    }
  }

  void _showUserInfoDialog(BuildContext context) {
    final userData = widget.isDoctor ? patientData : doctorData;
    final contactName = getUserName(userData, widget.isDoctor);
    final userImageUrl = getUserImageUrl(userData);
    final userStatus = getUserStatus(userData);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('معلومات $contactName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.withOpacity(0.15),
              child: ClipOval(
                child: _buildAvatarImage(
                  imageUrl: userImageUrl,
                  size: 80,
                  fallbackIconColor: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(contactName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              userStatus,
              style: TextStyle(
                color: userStatus.contains('متصل الآن') ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('إغلاق'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();
    List<QueryDocumentSnapshot> results = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> runSearch(String query) async {
            final normalizedQuery = query.trim().toLowerCase();
            if (normalizedQuery.isEmpty) {
              setDialogState(() => results = []);
              return;
            }

            setDialogState(() => isSearching = true);
            final snapshot = await _firestore
                .collection('consultations')
                .doc(widget.consultationId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .get();

            final filtered = snapshot.docs.where((doc) {
              final data = doc.data();
              final text = (data['text'] ?? data['fileName'] ?? '').toString().toLowerCase();
              final sender = (data['senderName'] ?? '').toString().toLowerCase();
              return text.contains(normalizedQuery) || sender.contains(normalizedQuery);
            }).toList();

            setDialogState(() {
              results = filtered;
              isSearching = false;
            });
          }

          return AlertDialog(
            title: const Text('بحث في المحادثة'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'ابحث في الرسائل...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: runSearch,
                  ),
                  const SizedBox(height: 12),
                  if (isSearching)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                  else if (results.isNotEmpty)
                    SizedBox(
                      height: 260,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final data = results[index].data() as Map<String, dynamic>;
                          return ListTile(
                            dense: true,
                            title: Text((data['text'] ?? data['fileName'] ?? 'رسالة').toString()),
                            subtitle: Text((data['senderName'] ?? '').toString()),
                          );
                        },
                      ),
                    )
                  else
                    const Text('اكتب كلمة ثم اضغط بحث'),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('إلغاء'),
                onPressed: () => Navigator.pop(dialogContext),
              ),
              TextButton(
                child: const Text('بحث'),
                onPressed: () => runSearch(searchController.text),
              ),
            ],
          );
        },
      ),
    ).whenComplete(searchController.dispose);
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات الإشعارات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('تشغيل الإشعارات'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('صوت الإشعارات'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('حفظ'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المحادثة'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذه المحادثة وجميع رسائلها من قاعدة البيانات؟'),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          TextButton(
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteCurrentConsultation();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCurrentConsultation() async {
    try {
      final consultationRef = _firestore.collection('consultations').doc(widget.consultationId);

      while (true) {
        final messages = await consultationRef.collection('messages').limit(400).get();
        if (messages.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (final message in messages.docs) {
          batch.delete(message.reference);
        }
        await batch.commit();
      }

      final notifications = await _firestore
          .collection('notifications')
          .where('consultationId', isEqualTo: widget.consultationId)
          .get();
      if (notifications.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final notification in notifications.docs) {
          batch.delete(notification.reference);
        }
        await batch.commit();
      }

      await consultationRef.delete();

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('تم حذف المحادثة بالكامل')),
      );
    } catch (e) {
      _showErrorSnackbar('فشل في حذف المحادثة: $e');
    }
  }

  // ============ Logging Functions ============

  void _logDebug(String message) {
    debugPrint('$_logTag 🔍 $message');
  }

  void _logInfo(String message) {
    debugPrint('$_logTag ℹ️ $message');
  }

  void _logSuccess(String message) {
    debugPrint('$_logTag ✅ $message');
  }

  void _logWarning(String message) {
    debugPrint('$_logTag ⚠️ $message');
  }

  void _logError(String message) {
    debugPrint('$_logTag ❌ $message');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    selectedMedia?.delete();
    super.dispose();
  }
}