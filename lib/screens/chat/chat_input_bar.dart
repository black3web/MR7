import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/theme.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../models/message_model.dart';
import 'sticker_picker.dart';

class ChatInputBar extends StatefulWidget {
  final String chatId;
  final String senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final MessageModel? replyingTo;
  final VoidCallback? onClearReply;
  final VoidCallback? onSent;
  final bool isGroup;

  const ChatInputBar({
    super.key,
    required this.chatId,
    required this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    this.replyingTo,
    this.onClearReply,
    this.onSent,
    this.isGroup = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with TickerProviderStateMixin {
  final _ctrl         = TextEditingController();
  final _focusNode    = FocusNode();
  bool _hasText       = false;
  bool _sending       = false;
  bool _showAttach    = false;
  bool _showStickers  = false;
  bool _uploading     = false;
  double _uploadPct   = 0;

  // Voice recording
  final _recorder     = AudioRecorder();
  bool _recording     = false;
  bool _recordReady   = false;
  String? _recordPath;
  int _recSeconds     = 0;
  Timer? _recTimer;
  late AnimationController _recAnim;

  @override
  void initState() {
    super.initState();
    _recAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _ctrl.addListener(() => setState(() => _hasText = _ctrl.text.trim().isNotEmpty));
    _checkMicPerm();
  }

  Future<void> _checkMicPerm() async {
    _recordReady = await _recorder.hasPermission();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _recTimer?.cancel();
    _recAnim.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ── Send text ─────────────────────────────────────────────────────────
  Future<void> _sendText() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() { _sending = true; _hasText = false; });
    final saved = text;
    _ctrl.clear();
    try {
      await ChatService().sendMessageWithNotif(
        chatId: widget.chatId,
        senderId: widget.senderId,
        senderName: widget.senderName ?? 'Unknown',
        senderPhotoUrl: widget.senderPhotoUrl ?? '',
        type: MessageType.text,
        text: saved,
        replyToId: widget.replyingTo?.id,
        replyToText: widget.replyingTo?.text,
        replyToSenderId: widget.replyingTo?.senderName,
      );
      widget.onSent?.call();
      widget.onClearReply?.call();
    } catch (e) {
      if (mounted) { _ctrl.text = saved; setState(() => _hasText = true); }
      _err('فشل الإرسال: ${e.toString().replaceAll("Exception: ", "")}');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Send media ────────────────────────────────────────────────────────
  Future<void> _sendMedia({required MessageType type, required XFile file}) async {
    setState(() { _uploading = true; _uploadPct = 0.1; });
    _startProgress();
    try {
      final url = await StorageService().uploadMedia(file, widget.chatId);
      if (!mounted) return;
      setState(() => _uploadPct = 0.95);
      await ChatService().sendMessageWithNotif(
        chatId: widget.chatId, senderId: widget.senderId,
        senderName: widget.senderName ?? 'Unknown', senderPhotoUrl: widget.senderPhotoUrl ?? '',
        type: type, mediaUrl: url,
        replyToId: widget.replyingTo?.id,
        replyToText: widget.replyingTo?.text,
        replyToSenderId: widget.replyingTo?.senderName,
      );
      widget.onSent?.call();
      widget.onClearReply?.call();
    } catch (e) {
      _err('فشل رفع ${type == MessageType.image ? "الصورة" : "الفيديو"}: ${e.toString().replaceAll("Exception: ", "")}');
    } finally {
      if (mounted) setState(() { _uploading = false; _uploadPct = 0; });
    }
  }

  void _startProgress() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _uploading) {
        setState(() => _uploadPct = (_uploadPct + 0.15).clamp(0.0, 0.9));
        if (_uploadPct < 0.9) _startProgress();
      }
    });
  }

  // ── Pick image ────────────────────────────────────────────────────────
  Future<void> _pickImage({ImageSource src = ImageSource.gallery}) async {
    _closeAttach();
    final file = await StorageService().pickImage(source: src);
    if (file == null || !mounted) return;
    await _sendMedia(type: MessageType.image, file: file);
  }

  // ── Pick video ────────────────────────────────────────────────────────
  Future<void> _pickVideo() async {
    _closeAttach();
    final file = await StorageService().pickVideo();
    if (file == null || !mounted) return;
    await _sendMedia(type: MessageType.video, file: file);
  }

  // ── Voice recording ───────────────────────────────────────────────────
  Future<void> _startRecording() async {
    if (!_recordReady) {
      _recordReady = await _recorder.hasPermission();
      if (!_recordReady) { _err('لا إذن للميكروفون. أضفه من الإعدادات.'); return; }
    }
    try {
      final dir  = await getTemporaryDirectory();
      _recordPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100), path: _recordPath!);
      _recSeconds = 0;
      _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recSeconds++);
        if (_recSeconds >= 300) _stopRecording(); // 5 min limit
      });
      setState(() => _recording = true);
      HapticFeedback.mediumImpact();
    } catch (e) {
      _err('فشل بدء التسجيل');
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recTimer?.cancel();
    try {
      final path = await _recorder.stop();
      if (cancel || path == null || _recSeconds < 1) {
        setState(() => _recording = false);
        return;
      }
      setState(() => _recording = false);
      // Upload voice
      final file = XFile(path);
      setState(() { _uploading = true; _uploadPct = 0.1; });
      _startProgress();
      try {
        final url = await StorageService().uploadMedia(file, widget.chatId);
        if (!mounted) return;
        setState(() => _uploadPct = 0.95);
        await ChatService().sendMessageWithNotif(
          chatId: widget.chatId, senderId: widget.senderId,
          senderName: widget.senderName ?? 'Unknown', senderPhotoUrl: widget.senderPhotoUrl ?? '',
          type: MessageType.voice, mediaUrl: url, duration: _recSeconds,
        );
        widget.onSent?.call();
      } catch (e) {
        _err('فشل إرسال الصوتية');
      } finally {
        if (mounted) setState(() { _uploading = false; _uploadPct = 0; });
      }
    } catch (e) {
      setState(() => _recording = false);
      _err('فشل إيقاف التسجيل');
    }
  }

  // ── Sticker send ──────────────────────────────────────────────────────
  Future<void> _sendSticker(String url) async {
    setState(() => _showStickers = false);
    try {
      await ChatService().sendMessageWithNotif(
        chatId: widget.chatId, senderId: widget.senderId,
        senderName: widget.senderName ?? 'Unknown', senderPhotoUrl: widget.senderPhotoUrl ?? '',
        type: MessageType.sticker, mediaUrl: url,
      );
      widget.onSent?.call();
    } catch (_) { _err('فشل إرسال الملصق'); }
  }

  void _closeAttach() => setState(() => _showAttach = false);

  void _err(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFCC0022),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _fmtRec(int s) =>
      '${(s ~/ 60).toString().padLeft(2,'0')}:${(s % 60).toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // ── Reply preview ──
      if (widget.replyingTo != null) _ReplyPreview(msg: widget.replyingTo!, onClose: widget.onClearReply),

      // ── Upload progress ──
      if (_uploading) _ProgressBar(pct: _uploadPct),

      // ── Attach menu ──
      if (_showAttach) _AttachMenu(
        onPhoto:  () => _pickImage(),
        onCamera: () => _pickImage(src: ImageSource.camera),
        onVideo:  _pickVideo,
        onClose:  _closeAttach,
      ),

      // ── Sticker picker ──
      if (_showStickers) StickerPicker(
        onStickerSelected: _sendSticker,
        onClose: () => setState(() => _showStickers = false),
      ),

      // ── Recording bar ──
      if (_recording) _RecordingBar(
        seconds: _recSeconds,
        onCancel: () => _stopRecording(cancel: true),
        onSend: _stopRecording,
        anim: _recAnim,
      ),

      // ── Main input row ──
      if (!_recording)
        ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
              decoration: BoxDecoration(
                color: AppColors.bgMedium.withOpacity(0.94),
                border: Border(top: BorderSide(color: AppColors.glassBorder, width: 0.7)),
              ),
              child: Row(children: [
                // Attach
                _CircleIcon(
                  icon: _showAttach ? Icons.close_rounded : Icons.attach_file_rounded,
                  color: _showAttach ? AppColors.accent : AppColors.textMuted,
                  onTap: () { setState(() { _showAttach = !_showAttach; _showStickers = false; _focusNode.unfocus(); }); },
                ),
                const SizedBox(width: 6),

                // Text field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 130),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.glassBorder, width: 0.7),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4),
                      onTap: () => setState(() { _showAttach = false; _showStickers = false; }),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Sticker button
                _CircleIcon(
                  icon: _showStickers ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
                  color: _showStickers ? AppColors.accent : AppColors.textMuted,
                  onTap: () { setState(() { _showStickers = !_showStickers; _showAttach = false; if (_showStickers) _focusNode.unfocus(); else _focusNode.requestFocus(); }); },
                ),
                const SizedBox(width: 6),

                // Send / Mic
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: _hasText
                      ? _SendButton(key: const ValueKey('s'), loading: _sending, onTap: _sendText)
                      : GestureDetector(
                          key: const ValueKey('m'),
                          onLongPressStart: (_) => _startRecording(),
                          onLongPressEnd: (_) => _stopRecording(),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.bgLight,
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: const Icon(Icons.mic_rounded, size: 20, color: AppColors.textMuted),
                          ),
                        ),
                ),
              ]),
            ),
          ),
        ),
    ],
  );
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────
class _ReplyPreview extends StatelessWidget {
  final MessageModel msg;
  final VoidCallback? onClose;
  const _ReplyPreview({required this.msg, this.onClose});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
    decoration: BoxDecoration(
      color: AppColors.bgMedium,
      border: Border(top: BorderSide(color: AppColors.glassBorder), left: const BorderSide(color: AppColors.accent, width: 3)),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(msg.senderName ?? 'رسالة', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(msg.text ?? (msg.type == MessageType.image ? '📷 صورة' : msg.type == MessageType.voice ? '🎤 رسالة صوتية' : '🎥 فيديو'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      GestureDetector(onTap: onClose, child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted)),
    ]),
  );
}

class _ProgressBar extends StatelessWidget {
  final double pct;
  const _ProgressBar({required this.pct});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
    color: AppColors.bgMedium,
    child: Column(children: [
      Row(children: [
        const Icon(Icons.cloud_upload_outlined, size: 14, color: AppColors.accent),
        const SizedBox(width: 8),
        Text('جاري الرفع... ${(pct * 100).toInt()}%',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: pct, backgroundColor: AppColors.bgLight, color: AppColors.accent, minHeight: 3)),
    ]),
  );
}

class _AttachMenu extends StatelessWidget {
  final VoidCallback onPhoto, onCamera, onVideo, onClose;
  const _AttachMenu({required this.onPhoto, required this.onCamera, required this.onVideo, required this.onClose});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    color: AppColors.bgMedium.withOpacity(0.97),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _AttachBtn(icon: Icons.photo_library_rounded, label: 'معرض', color: const Color(0xFF4285F4), onTap: onPhoto),
      _AttachBtn(icon: Icons.camera_alt_rounded, label: 'كاميرا', color: const Color(0xFF00BCD4), onTap: onCamera),
      _AttachBtn(icon: Icons.videocam_rounded, label: 'فيديو', color: const Color(0xFF9C27B0), onTap: onVideo),
    ]),
  );
}

class _AttachBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _AttachBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56, height: 56,
        decoration: BoxDecoration(color: color.withOpacity(0.13), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.35))),
        child: Icon(icon, size: 26, color: color)),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    ]),
  );
}

class _RecordingBar extends StatelessWidget {
  final int seconds; final VoidCallback onCancel, onSend; final Animation<double> anim;
  const _RecordingBar({required this.seconds, required this.onCancel, required this.onSend, required this.anim});
  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2,'0')}:${(s % 60).toString().padLeft(2,'0')}';
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    decoration: BoxDecoration(color: AppColors.bgMedium, border: Border(top: BorderSide(color: AppColors.glassBorder))),
    child: Row(children: [
      GestureDetector(onTap: onCancel, child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppColors.bgLight, shape: BoxShape.circle, border: Border.all(color: AppColors.glassBorder)),
        child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accent),
      )),
      const SizedBox(width: 10),
      AnimatedBuilder(animation: anim, builder: (_, __) => Container(
        width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle,
          color: AppColors.accent.withOpacity(0.5 + anim.value * 0.5)),
      )),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('جاري التسجيل...', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
        Text(_fmt(seconds), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2)),
      ])),
      GestureDetector(onTap: onSend, child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(gradient: AppGradients.accentGradient, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 10)]),
        child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
      )),
    ]),
  );
}

class _CircleIcon extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _CircleIcon({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 38, height: 38,
      decoration: BoxDecoration(color: AppColors.bgLight, shape: BoxShape.circle, border: Border.all(color: AppColors.glassBorder, width: 0.7)),
      child: Icon(icon, size: 19, color: color)),
  );
}

class _SendButton extends StatelessWidget {
  final bool loading; final VoidCallback onTap;
  const _SendButton({super.key, required this.loading, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(width: 40, height: 40,
      decoration: BoxDecoration(gradient: AppGradients.accentGradient, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 10, offset: const Offset(0,3))]),
      child: loading
          ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.send_rounded, size: 18, color: Colors.white)),
  );
}
