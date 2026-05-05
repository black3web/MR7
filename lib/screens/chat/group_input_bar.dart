// group_input_bar.dart — reuses ChatInputBar logic for groups
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/theme.dart';
import '../../services/group_service.dart';
import '../../services/storage_service.dart';
import '../../models/message_model.dart';
import 'sticker_picker.dart';

class GroupInputBar extends StatefulWidget {
  final String groupId;
  final String senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final MessageModel? replyingTo;
  final VoidCallback? onClearReply;
  final VoidCallback? onSent;

  const GroupInputBar({
    super.key,
    required this.groupId,
    required this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    this.replyingTo,
    this.onClearReply,
    this.onSent,
  });

  @override
  State<GroupInputBar> createState() => _GroupInputBarState();
}

class _GroupInputBarState extends State<GroupInputBar>
    with TickerProviderStateMixin {
  final _ctrl      = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText    = false;
  bool _sending    = false;
  bool _showAttach = false;
  bool _showStickers = false;
  bool _uploading  = false;
  double _uploadPct = 0;

  final _recorder  = AudioRecorder();
  bool _recording  = false;
  bool _recordReady = false;
  String? _recordPath;
  int _recSeconds  = 0;
  Timer? _recTimer;
  late AnimationController _recAnim;

  @override
  void initState() {
    super.initState();
    _recAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _ctrl.addListener(() => setState(() => _hasText = _ctrl.text.trim().isNotEmpty));
    _checkMic();
  }

  Future<void> _checkMic() async {
    _recordReady = await _recorder.hasPermission();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose(); _focusNode.dispose();
    _recTimer?.cancel(); _recAnim.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() { _sending = true; _hasText = false; });
    final saved = text; _ctrl.clear();
    try {
      await GroupService().sendGroupMessage(
        groupId: widget.groupId, senderId: widget.senderId,
        senderName: widget.senderName ?? 'Unknown', 
        senderPhotoUrl: widget.senderPhotoUrl ?? '',
        type: MessageType.text, text: saved,
        replyToId: widget.replyingTo?.id,
        replyToText: widget.replyingTo?.text,
        replyToSenderId: widget.replyingTo?.senderName,
      );
      widget.onSent?.call(); widget.onClearReply?.call();
    } catch (e) {
      if (mounted) { _ctrl.text = saved; setState(() => _hasText = true); }
      _err('فشل الإرسال');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendMedia(MessageType type, XFile file) async {
    setState(() { _uploading = true; _uploadPct = 0.1; });
    _progress();
    try {
      final url = await StorageService().uploadMedia(file, widget.groupId);
      if (!mounted) return;
      await GroupService().sendGroupMessage(
        groupId: widget.groupId, senderId: widget.senderId,
        senderName: widget.senderName ?? 'Unknown', 
        senderPhotoUrl: widget.senderPhotoUrl ?? '',
        type: type, mediaUrl: url,
      );
      widget.onSent?.call();
    } catch (_) { _err('فشل رفع الملف'); }
    finally { if (mounted) setState(() { _uploading = false; _uploadPct = 0; }); }
  }

  void _progress() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _uploading) {
        setState(() => _uploadPct = (_uploadPct + 0.15).clamp(0.0, 0.9));
        if (_uploadPct < 0.9) _progress();
      }
    });
  }

  Future<void> _pickImage({ImageSource src = ImageSource.gallery}) async {
    _hideAttach();
    final f = await StorageService().pickImage(source: src);
    if (f == null || !mounted) return;
    await _sendMedia(MessageType.image, f);
  }

  Future<void> _pickVideo() async {
    _hideAttach();
    final f = await StorageService().pickVideo();
    if (f == null || !mounted) return;
    await _sendMedia(MessageType.video, f);
  }

  Future<void> _startRecording() async {
    if (!_recordReady) { _err('لا إذن للميكروفون'); return; }
    final dir = await getTemporaryDirectory();
    _recordPath = '${dir.path}/gvoice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: _recordPath!);
    _recSeconds = 0;
    _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recSeconds++);
    });
    setState(() => _recording = true);
    HapticFeedback.mediumImpact();
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recTimer?.cancel();
    final path = await _recorder.stop();
    if (cancel || path == null || _recSeconds < 1) { setState(() => _recording = false); return; }
    setState(() => _recording = false);
    final f = XFile(path);
    setState(() { _uploading = true; _uploadPct = 0.1; });
    _progress();
    try {
      final url = await StorageService().uploadMedia(f, widget.groupId);
      if (!mounted) return;
      await GroupService().sendGroupMessage(
        groupId: widget.groupId, senderId: widget.senderId,
        senderName: widget.senderName ?? 'Unknown', 
        senderPhotoUrl: widget.senderPhotoUrl ?? '',
        type: MessageType.voice, mediaUrl: url, duration: _recSeconds,
      );
      widget.onSent?.call();
    } catch (_) { _err('فشل إرسال الصوتية'); }
    finally { if (mounted) setState(() { _uploading = false; _uploadPct = 0; }); }
  }

  Future<void> _sendSticker(String url) async {
    setState(() => _showStickers = false);
    try {
      await GroupService().sendGroupMessage(
        groupId: widget.groupId, senderId: widget.senderId,
        senderName: widget.senderName ?? 'Unknown', 
        senderPhotoUrl: widget.senderPhotoUrl ?? '',
        type: MessageType.sticker, mediaUrl: url,
      );
      widget.onSent?.call();
    } catch (_) { _err('فشل إرسال الملصق'); }
  }

  void _hideAttach() => setState(() => _showAttach = false);
  void _err(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m),
        backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3)));
  }

  String _fmtRec(int s) => '${(s ~/ 60).toString().padLeft(2,'0')}:${(s % 60).toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (widget.replyingTo != null) Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        decoration: BoxDecoration(color: AppColors.bgMedium, border: Border(top: BorderSide(color: AppColors.glassBorder), left: const BorderSide(color: AppColors.accent, width: 3))),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.replyingTo!.senderName ?? '', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
            Text(widget.replyingTo!.text ?? '📷', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          GestureDetector(onTap: widget.onClearReply, child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted)),
        ]),
      ),
      if (_uploading) Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6), color: AppColors.bgMedium,
        child: Column(children: [
          Row(children: [const Icon(Icons.cloud_upload_outlined, size: 14, color: AppColors.accent), const SizedBox(width: 8),
            Text('جاري الرفع... ${(_uploadPct * 100).toInt()}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))]),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: _uploadPct, backgroundColor: AppColors.bgLight, color: AppColors.accent, minHeight: 3)),
        ]),
      ),
      if (_showAttach) Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), color: AppColors.bgMedium.withOpacity(0.97),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _AttBtn(Icons.photo_library_rounded, 'معرض', const Color(0xFF4285F4), () => _pickImage()),
          _AttBtn(Icons.camera_alt_rounded, 'كاميرا', const Color(0xFF00BCD4), () => _pickImage(src: ImageSource.camera)),
          _AttBtn(Icons.videocam_rounded, 'فيديو', const Color(0xFF9C27B0), _pickVideo),
        ]),
      ),
      if (_showStickers) StickerPicker(onStickerSelected: _sendSticker, onClose: () => setState(() => _showStickers = false)),
      if (_recording) Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12), color: AppColors.bgMedium,
        child: Row(children: [
          GestureDetector(onTap: () => _stopRecording(cancel: true), child: Container(
            width: 36, height: 36, decoration: BoxDecoration(color: AppColors.bgLight, shape: BoxShape.circle),
            child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accent))),
          const SizedBox(width: 10),
          AnimatedBuilder(animation: _recAnim, builder: (_, __) => Container(width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withOpacity(0.5 + _recAnim.value * 0.5)))),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('جاري التسجيل...', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
            Text(_fmtRec(_recSeconds), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2)),
          ])),
          GestureDetector(onTap: _stopRecording, child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(gradient: AppGradients.accentGradient, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, size: 18, color: Colors.white))),
        ]),
      ),
      if (!_recording) ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.94), border: Border(top: BorderSide(color: AppColors.glassBorder, width: 0.7))),
            child: Row(children: [
              _Btn(icon: _showAttach ? Icons.close_rounded : Icons.attach_file_rounded, color: _showAttach ? AppColors.accent : AppColors.textMuted,
                onTap: () => setState(() { _showAttach = !_showAttach; _showStickers = false; _focusNode.unfocus(); })),
              const SizedBox(width: 6),
              Expanded(child: Container(
                constraints: const BoxConstraints(maxHeight: 130),
                decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.glassBorder, width: 0.7)),
                child: TextField(
                  controller: _ctrl, focusNode: _focusNode, maxLines: null,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4),
                  onTap: () => setState(() { _showAttach = false; _showStickers = false; }),
                  decoration: const InputDecoration(hintText: 'رسالة للمجموعة...', hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10), isDense: true),
                ),
              )),
              const SizedBox(width: 6),
              _Btn(icon: _showStickers ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined, color: _showStickers ? AppColors.accent : AppColors.textMuted,
                onTap: () => setState(() { _showStickers = !_showStickers; _showAttach = false; if (_showStickers) _focusNode.unfocus(); else _focusNode.requestFocus(); })),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: _hasText
                    ? GestureDetector(key: const ValueKey('s'), onTap: _sending ? null : _sendText, child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(gradient: AppGradients.accentGradient, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 10, offset: const Offset(0,3))]),
                        child: _sending
                            ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 18, color: Colors.white)))
                    : GestureDetector(key: const ValueKey('m'),
                        onLongPressStart: (_) => _startRecording(),
                        onLongPressEnd: (_) => _stopRecording(),
                        child: Container(width: 40, height: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.bgLight, border: Border.all(color: AppColors.glassBorder)),
                          child: const Icon(Icons.mic_rounded, size: 20, color: AppColors.textMuted))),
              ),
            ]),
          ),
        ),
      ),
    ],
  );
}

class _Btn extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _Btn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    width: 38, height: 38, decoration: BoxDecoration(color: AppColors.bgLight, shape: BoxShape.circle, border: Border.all(color: AppColors.glassBorder, width: 0.7)),
    child: Icon(icon, size: 19, color: color)));
}

class _AttBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _AttBtn(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 54, height: 54, decoration: BoxDecoration(color: color.withOpacity(0.13), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.35))),
      child: Icon(icon, size: 26, color: color)),
    const SizedBox(height: 5),
    Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
  ]));
}
