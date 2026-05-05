import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../config/theme.dart';
import '../../models/message_model.dart';
import '../../services/chat_service.dart';
import '../../widgets/chat/typing_indicator.dart';

/// شريط إدخال متقدم بجميع ميزات Telegram
class AdvancedInputBar extends StatefulWidget {
  final String chatId;
  final String senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final String? recipientId;
  final MessageModel? replyingTo;
  final VoidCallback? onCancelReply;
  final bool isGroup;

  const AdvancedInputBar({
    super.key,
    required this.chatId,
    required this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    this.recipientId,
    this.replyingTo,
    this.onCancelReply,
    this.isGroup = false,
  });

  @override
  State<AdvancedInputBar> createState() => _AdvancedInputBarState();
}

class _AdvancedInputBarState extends State<AdvancedInputBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _showEmojiPicker = false;
  bool _isTyping = false;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _recorder.dispose();
    if (_isTyping) {
      _chatService.setTyping(widget.chatId, widget.senderId, false);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final newIsTyping = _textController.text.trim().isNotEmpty;
    if (newIsTyping != _isTyping) {
      setState(() => _isTyping = newIsTyping);
      _chatService.setTyping(widget.chatId, widget.senderId, newIsTyping);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.replyingTo != null) _buildReplyPreview(),
        if (_isRecording) _buildRecordingUI(),
        if (_showEmojiPicker) _buildEmojiPicker(),
        _buildMainInputBar(),
      ],
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.replyingTo!.senderName ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.replyingTo!.text ?? _getMediaType(widget.replyingTo!.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.onCancelReply,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: RecordingIndicator(
        seconds: _recordingSeconds,
        onStop: _stopRecording,
        onCancel: _cancelRecording,
      ),
    );
  }

  Widget _buildMainInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // زر المرفقات
          IconButton(
            icon: Icon(Icons.add, color: AppColors.accent),
            onPressed: _showAttachmentOptions,
          ),
          
          // حقل النص
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: 5,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(color: AppColors.textPrimary),
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: _toggleEmojiPicker,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // زر الإرسال/التسجيل
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    final hasText = _textController.text.trim().isNotEmpty;
    
    return GestureDetector(
      onTap: hasText ? _sendText : null,
      onLongPressStart: hasText ? null : (_) => _startRecording(),
      onLongPressEnd: hasText ? null : (_) => _stopRecording(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          hasText ? Icons.send : Icons.mic,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _textController.text += emoji.emoji;
        },
        config: Config(
          bgColor: AppColors.background,
          indicatorColor: AppColors.accent,
          iconColor: AppColors.textSecondary,
          iconColorSelected: AppColors.accent,
          backspaceColor: AppColors.accent,
          skinToneDialogBgColor: AppColors.surface,
          skinToneIndicatorColor: AppColors.accent,
          categoryIcons: const CategoryIcons(),
          buttonMode: ButtonMode.MATERIAL,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Actions ────────────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);
    if (_showEmojiPicker) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _chatService.setTyping(widget.chatId, widget.senderId, false);

    try {
      await _chatService.sendMessageWithNotif(
        chatId: widget.chatId,
        senderId: widget.senderId,
        senderName: widget.senderName ?? 'Unknown',
        senderPhotoUrl: widget.senderPhotoUrl,
        type: MessageType.text,
        text: text,
        replyToId: widget.replyingTo?.id,
        replyToText: widget.replyingTo?.text,
        replyToSenderId: widget.replyingTo?.senderId,
        recipientId: widget.recipientId,
      );
      widget.onCancelReply?.call();
    } catch (e) {
      _showError('فشل إرسال الرسالة');
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final path = '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(), path: path);
        
        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
        });

        // عداد الوقت
        while (_isRecording) {
          await Future.delayed(const Duration(seconds: 1));
          if (_isRecording) {
            setState(() => _recordingSeconds++);
          }
        }
      }
    } catch (e) {
      _showError('فشل بدء التسجيل');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);

      if (path != null && _recordingSeconds > 0) {
        // رفع الملف وإرسال
        final url = await _uploadFile(File(path));
        if (url != null) {
          await _chatService.sendMessageWithNotif(
            chatId: widget.chatId,
            senderId: widget.senderId,
            senderName: widget.senderName ?? 'Unknown',
            senderPhotoUrl: widget.senderPhotoUrl,
            type: MessageType.voice,
            mediaUrl: url,
            duration: _recordingSeconds,
            recipientId: widget.recipientId,
          );
        }
      }
    } catch (e) {
      _showError('فشل إرسال التسجيل');
    }
  }

  void _cancelRecording() {
    _recorder.stop();
    setState(() => _isRecording = false);
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            _buildAttachmentOption(
              Icons.photo_camera,
              'كاميرا',
              Colors.pink,
              () => _pickMedia(ImageSource.camera, false),
            ),
            _buildAttachmentOption(
              Icons.photo_library,
              'معرض الصور',
              Colors.purple,
              () => _pickMedia(ImageSource.gallery, false),
            ),
            _buildAttachmentOption(
              Icons.videocam,
              'فيديو',
              Colors.red,
              () => _pickMedia(ImageSource.gallery, true),
            ),
            _buildAttachmentOption(
              Icons.insert_drive_file,
              'ملف',
              Colors.blue,
              _pickFile,
            ),
            _buildAttachmentOption(
              Icons.location_on,
              'موقع',
              Colors.green,
              _shareLocation,
            ),
            _buildAttachmentOption(
              Icons.emoji_emotions,
              'ملصق',
              Colors.orange,
              _pickSticker,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: TextStyle(color: AppColors.textPrimary)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    try {
      if (isVideo) {
        final video = await _picker.pickVideo(source: source);
        if (video != null) {
          await _sendMedia(File(video.path), MessageType.video);
        }
      } else {
        final image = await _picker.pickImage(source: source);
        if (image != null) {
          await _sendMedia(File(image.path), MessageType.image);
        }
      }
    } catch (e) {
      _showError('فشل اختيار الملف');
    }
  }

  Future<void> _sendMedia(File file, MessageType type) async {
    try {
      final url = await _uploadFile(file);
      if (url != null) {
        await _chatService.sendMessageWithNotif(
          chatId: widget.chatId,
          senderId: widget.senderId,
          senderName: widget.senderName ?? 'Unknown',
          senderPhotoUrl: widget.senderPhotoUrl,
          type: type,
          mediaUrl: url,
          recipientId: widget.recipientId,
        );
      }
    } catch (e) {
      _showError('فشل إرسال الملف');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final url = await _uploadFile(file);
        
        if (url != null) {
          await _chatService.sendMessage(
            chatId: widget.chatId,
            senderId: widget.senderId,
            senderName: widget.senderName,
            senderPhotoUrl: widget.senderPhotoUrl,
            type: MessageType.file,
            mediaUrl: url,
            fileName: result.files.single.name,
            fileSize: result.files.single.size,
          );
        }
      }
    } catch (e) {
      _showError('فشل إرسال الملف');
    }
  }

  Future<void> _shareLocation() async {
    // TODO: Implement location sharing
    _showError('ميزة الموقع قريباً');
  }

  Future<void> _pickSticker() async {
    // TODO: Show sticker picker
    _showError('ميزة الملصقات قريباً');
  }

  Future<String?> _uploadFile(File file) async {
    // TODO: Implement file upload to Firebase Storage
    // This is a placeholder
    return 'https://example.com/${file.path.split('/').last}';
  }

  String _getMediaType(MessageType type) {
    switch (type) {
      case MessageType.image: return '📷 صورة';
      case MessageType.video: return '🎥 فيديو';
      case MessageType.voice: return '🎤 رسالة صوتية';
      case MessageType.sticker: return '🙂 ملصق';
      case MessageType.file: return '📄 ملف';
      case MessageType.location: return '📍 موقع';
      default: return '';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
