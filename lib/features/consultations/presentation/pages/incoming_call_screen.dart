import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
//import '../../../core/config/medical_theme.dart';

/// ✅ شاشة المكالمة الواردة الاحترافية
/// تعرض معلومات المتصل والأزرار الأساسية (قبول/رفض)
/// مشابهة لتطبيقات WhatsApp و Messenger الاحترافية
class IncomingCallScreen extends StatefulWidget {
  final String callID;
  final String callerID;
  final String callerName;
  final String? callerImage;
  final bool isVideoCall;
  final String doctorID;
  final String patientID;

  const IncomingCallScreen({
    Key? key,
    required this.callID,
    required this.callerID,
    required this.callerName,
    this.callerImage,
    required this.isVideoCall,
    required this.doctorID,
    required this.patientID,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  bool _isProcessing = false;
  int _callDuration = 0;
  late DateTime _callStartTime;

  @override
  void initState() {
    super.initState();
    _callStartTime = DateTime.now();
    _setupAnimations();
    _startCallTimer();
  }

  void _setupAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _scaleController.repeat(reverse: true);
  }

  void _startCallTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _callDuration = DateTime.now().difference(_callStartTime).inSeconds;
        });
      }
      return mounted;
    });
  }

  Future<void> _acceptCall() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      debugPrint('✅ تم قبول المكالمة من ${widget.callerName}');

      // الانتقال إلى شاشة المكالمة
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackbar('❌ لا يوجد مستخدم مسجل');
        return;
      }

      if (!mounted) return;

      debugPrint('📞 [Incoming Call] جاري الانتقال إلى شاشة المكالمة...');
      debugPrint('📞 [Incoming Call] callID: ${widget.callID}');
      debugPrint('📞 [Incoming Call] doctorID: ${widget.doctorID}');
      debugPrint('📞 [Incoming Call] patientID: ${widget.patientID}');
      debugPrint('📞 [Incoming Call] isVideoCall: ${widget.isVideoCall}');

      // التأكد من أن جميع البيانات موجودة
      if (widget.callID.isEmpty) {
        _showErrorSnackbar('❌ معرف المكالمة فارغ');
        return;
      }

      if (widget.doctorID.isEmpty || widget.patientID.isEmpty) {
        _showErrorSnackbar('❌ بيانات المستخدمين غير صحيحة');
        return;
      }

      // الانتقال لشاشة المكالمة الفعلية مع البيانات الكاملة
      Navigator.of(context).pushReplacementNamed(
        '/call',
        arguments: {
          'callID': widget.callID,
          'doctorID': widget.doctorID,
          'patientID': widget.patientID,
          'isVideoCall': widget.isVideoCall,
          'isDoctor': currentUser.uid == widget.doctorID,
          'userName': currentUser.displayName ?? 'User_${currentUser.uid.substring(0, 5)}',
        },
      );

      debugPrint('✅ [Incoming Call] تم الانتقال بنجاح');
    } catch (e) {
      debugPrint('❌ [Incoming Call] خطأ: $e');
      _showErrorSnackbar('❌ خطأ: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectCall() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      debugPrint('❌ تم رفض المكالمة من ${widget.callerName}');

      // إنهاء المكالمة من Zego
      // await ZegoUIKitPrebuiltCallInvitationService().cancelInvitation(
      //   isVideoCall: widget.isVideoCall,
      //   invitees: [ZegoCallUser(widget.callerID, widget.callerName)],
      //   callID: widget.callID,
      // );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackbar('خطأ في رفض المكالمة: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatCallDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        body: SafeArea(
          child: Column(
            children: [
              // ========== رأس الشاشة ==========
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.primaryColor.withOpacity(0.9),
                        theme.primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ========== صورة المتصل ==========
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: widget.callerImage != null &&
                                widget.callerImage!.isNotEmpty
                                ? Image.network(
                              widget.callerImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar(theme);
                              },
                            )
                                : _buildDefaultAvatar(theme),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ========== اسم المتصل ==========
                      Text(
                        widget.callerName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // ========== نوع المكالمة ==========
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.isVideoCall ? '📹 مكالمة فيديو' : '📞 مكالمة صوتية',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ========== مدة المكالمة (مؤشر الانتظار) ==========
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.7),
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'في الانتظار... ${_formatCallDuration(_callDuration)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ========== أزرار الإجراء ==========
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // ========== زر الرفض ==========
                    GestureDetector(
                      onTap: _isProcessing ? null : _rejectCall,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red[400],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red[400]!.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isProcessing
                            ? SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.7),
                            ),
                            strokeWidth: 2,
                          ),
                        )
                            : Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    // ========== زر القبول ==========
                    GestureDetector(
                      onTap: _isProcessing ? null : _acceptCall,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green[400],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green[400]!.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isProcessing
                            ? SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.7),
                            ),
                            strokeWidth: 2,
                          ),
                        )
                            : Icon(
                          Icons.call,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      color: theme.primaryColor.withOpacity(0.3),
      child: Icon(
        Icons.person,
        color: Colors.white.withOpacity(0.7),
        size: 80,
      ),
    );
  }
}
