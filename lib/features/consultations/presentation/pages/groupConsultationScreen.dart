import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class GroupConsultationScreen extends StatefulWidget {
  const GroupConsultationScreen({super.key});

  @override
  State<GroupConsultationScreen> createState() => _GroupConsultationScreenState();
}

class _GroupConsultationScreenState extends State<GroupConsultationScreen> {
  static const bool _preferInlineAttachments = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;
  Map<String, dynamic>? _replyToMessage;

  List<PlatformFile> _selectedFiles = [];
  bool _cloudStorageBlocked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode? Colors.grey[900]: Colors.white,
        foregroundColor: Colors.blue,
        title: const Text("الاستشارة الجماعية"),
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessagesList()),
            if (_replyToMessage != null) _buildReplyPreview(),
            if (_selectedFiles.isNotEmpty) _buildSelectedFilesPreview(),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection("group_consultations").orderBy("timestamp", descending: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        final messages = snapshot.data!.docs;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final doc = messages[index];
            final message = doc.data() as Map<String, dynamic>;
            final isMe = message['senderId'] == _auth.currentUser?.uid;
            return GestureDetector(
              onLongPress: isMe ? () => _deleteMessage(doc.id) : null,
              onDoubleTap: () => setState(() => _replyToMessage = message),
              child: _buildMessageBubble(message, isMe, theme, isDarkMode),
            );
          },
        );
      },
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      width: double.infinity,
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "ردًا على: ${_replyToMessage!['text'] ?? ''}",
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _replyToMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFilesPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedFiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          final isImage = file.extension?.toLowerCase() == 'jpg' || file.extension?.toLowerCase() == 'png';
          return Stack(
            children: [
              Container(
                width: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isImage
                    ? Image.memory(file.bytes!, fit: BoxFit.cover)
                    : Center(child: Icon(Icons.insert_drive_file, size: 40)),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.red),
                  onPressed: () {
                    setState(() => _selectedFiles.removeAt(index));
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }




  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe, ThemeData them, bool isDarkMode) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ?
            Colors.blue[400] :
            isDarkMode?
            Colors.grey[800]
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: message['senderImage'] != null
                          ? NetworkImage(message['senderImage'])
                          : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message['senderName'] ?? 'مستخدم',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (!isMe) const SizedBox(height: 4),
              if (message['replyTo'] != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDarkMode? Colors.grey[600]: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text("ردًا على: ${message['replyTo']['text'] ?? ''}"),
                ),
              if (message['files'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate((message['files'] as List).length, (index) {
                    final file = message['files'][index];
                    final fileType = (file['fileType'] ?? '').toString();
                    final isImage = fileType == 'image' || fileType == 'image_inline';
                    final fileUrl = (file['fileUrl'] ?? '').toString();
                    final fileBase64 = (file['fileBase64'] ?? '').toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: isImage
                          ? GestureDetector(
                        onTap: fileUrl.isNotEmpty
                            ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImagePreviewScreen(imageUrl: fileUrl),
                          ),
                        )
                            : null,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: fileUrl.isNotEmpty
                              ? Image.network(
                            fileUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                              : Image.memory(
                            base64Decode(fileBase64),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                          : InkWell(
                        onTap: fileUrl.isNotEmpty ? () => _openFile(fileUrl) : null,
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file),
                            const SizedBox(width: 5),
                            Text(file['fileName'] ?? "ملف مرفق"),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              if ((message['text'] ?? '').isNotEmpty) Text(message['text']),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTimestamp(message['timestamp']),
                    style: TextStyle(color: isDarkMode? Colors.grey[300]:Colors.grey[600], fontSize: 10),
                  ),
                  if (isMe)
                    Text(
                      '✓ تم الإرسال',
                      style: TextStyle(color: isDarkMode? Colors.grey[300]: Colors.grey[600], fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _pickFiles,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final user = _auth.currentUser;
    if (user == null || (_messageController.text.trim().isEmpty && _selectedFiles.isEmpty)) return;

    setState(() => _isSending = true);

    try {
      final userData = await _firestore.collection("users").doc(user.uid).get();
      final fullName = userData.data()?['fullName'] ?? 'مستخدم';
      final photoURL = userData.data()?['photoURL'];

      final List<Map<String, String>> files = [];

      for (final file in _selectedFiles) {
        final uploadedFile = await _uploadGroupFileWithFallback(file);
        files.add(uploadedFile);
      }

      final msg = {
        'text': _messageController.text.trim(),
        'senderId': user.uid,
        'senderName': fullName,
        'senderImage': photoURL,
        'timestamp': FieldValue.serverTimestamp(),
        'files': files,
        'replyTo': _replyToMessage,
      };

      await _firestore.collection("group_consultations").add(msg);

      _messageController.clear();
      setState(() {
        _replyToMessage = null;
        _selectedFiles.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إرسال الرسالة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<Map<String, String>> _uploadGroupFileWithFallback(PlatformFile file) async {
    final ext = (file.extension ?? '').toLowerCase();
    final isImage = ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'webp';

    if (file.bytes == null) {
      throw Exception('الملف ${file.name} لا يحتوي بيانات');
    }

    if (_preferInlineAttachments || _cloudStorageBlocked) {
      return {
        'fileType': isImage ? 'image_inline' : 'file_inline',
        'fileBase64': base64Encode(file.bytes!),
        'fileName': file.name,
      };
    }

    try {
      final ref = _storage.ref().child(
        'group_files/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
      );
      await ref.putData(file.bytes!);
      final url = await ref.getDownloadURL();
      return {
        'fileUrl': url,
        'fileType': isImage ? 'image' : 'file',
        'fileName': file.name,
      };
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('code\": 402') ||
          msg.contains('httpresult: 402') ||
          msg.contains('-13000') ||
          msg.contains('spark pricing plan') ||
          msg.contains('no longer supports')) {
        _cloudStorageBlocked = true;
      }
      return {
        'fileType': isImage ? 'image_inline' : 'file_inline',
        'fileBase64': base64Encode(file.bytes!),
        'fileName': file.name,
      };
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
    if (result != null) {
      setState(() => _selectedFiles = result.files);
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    await _firestore.collection("group_consultations").doc(messageId).delete();
  }

  void _openFile(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('hh:mm a | dd MMM yyyy', 'ar').format(date);
    }
    return '';
  }
}

class ImagePreviewScreen extends StatelessWidget {
  final String imageUrl;
  const ImagePreviewScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}