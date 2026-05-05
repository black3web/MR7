import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/message_model.dart';
import '../../widgets/user_avatar.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'video_message_player.dart';
import 'voice_message_player.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMine;
  final bool showAvatar;
  final bool showName;
  final bool isSelected;
  final bool selectionMode;
  final Function(MessageModel)? onReply;
  final Function(MessageModel)? onDelete;
  final Function(MessageModel)? onEdit;
  final Function(MessageModel, String)? onReact;
  final Function(MessageModel)? onSelect;
  final Function(MessageModel)? onTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showAvatar = false,
    this.showName   = false,
    this.isSelected = false,
    this.selectionMode = false,
    this.onReply,
    this.onDelete,
    this.onEdit,
    this.onReact,
    this.onSelect,
    this.onTap,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _swipeCtrl;
  double _dragOffset = 0;
  bool _showReactBar = false;

  @override
  void initState() {
    super.initState();
    _swipeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() { _swipeCtrl.dispose(); super.dispose(); }

  // ─── Context menu ──────────────────────────────────────────────────────
  void _showOptions(BuildContext ctx) {
    final l = AppLocalizations.of(ctx);
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _OptionsSheet(
        message: widget.message,
        isMine: widget.isMine,
        l: l,
        onReply:  () { Navigator.pop(ctx); widget.onReply?.call(widget.message); },
        onCopy:   () { Navigator.pop(ctx); _copy(); },
        onEdit:   widget.isMine ? () { Navigator.pop(ctx); widget.onEdit?.call(widget.message); } : null,
        onDelete: widget.isMine ? () { Navigator.pop(ctx); widget.onDelete?.call(widget.message); } : null,
        onSelect: () { Navigator.pop(ctx); widget.onSelect?.call(widget.message); },
      ),
    );
  }

  void _copy() {
    final text = widget.message.text ?? '';
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ الرسالة'), duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _onSwipeStart(DragStartDetails _) => setState(() => _dragOffset = 0);
  void _onSwipeUpdate(DragUpdateDetails d) {
    if (!mounted) return;
    setState(() {
      _dragOffset = (widget.isMine
          ? (_dragOffset + d.delta.dx).clamp(-60.0, 0.0)
          : (_dragOffset + d.delta.dx).clamp(0.0, 60.0));
    });
  }
  void _onSwipeEnd(DragEndDetails d) {
    final threshold = widget.isMine ? -45.0 : 45.0;
    if (widget.isMine ? _dragOffset < threshold : _dragOffset > threshold) {
      HapticFeedback.mediumImpact();
      widget.onReply?.call(widget.message);
    }
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    if (msg.isDeleted) return _DeletedBubble(isMine: widget.isMine);

    return GestureDetector(
      onLongPress: () => _showOptions(context),
      onTap: () {
        if (widget.selectionMode) {
          widget.onSelect?.call(msg);
        } else {
          widget.onTap?.call(msg);
        }
      },
      onHorizontalDragStart: _onSwipeStart,
      onHorizontalDragUpdate: _onSwipeUpdate,
      onHorizontalDragEnd: _onSwipeEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: widget.isSelected
            ? AppColors.accent.withOpacity(0.08)
            : Colors.transparent,
        padding: EdgeInsets.only(
          bottom: 3,
          left: widget.isMine ? 48 : 8,
          right: widget.isMine ? 8 : 48,
        ),
        child: Transform.translate(
          offset: Offset(_dragOffset, 0),
          child: Column(
            crossAxisAlignment: widget.isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Sender name (only for other person)
              if (widget.showName && !widget.isMine)
                Padding(
                  padding: const EdgeInsets.only(left: 42, bottom: 3),
                  child: Row(children: [
                    Text(msg.senderName ?? '', style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
                    if (msg.extra?['isAdmin'] == true) ...[
                      const SizedBox(width: 4),
                      _DevBadge(),
                    ],
                  ]),
                ),

              Row(
                mainAxisAlignment: widget.isMine
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar for other person
                  if (!widget.isMine && widget.showAvatar)
                    Padding(
                      padding: const EdgeInsets.only(right: 6, bottom: 2),
                      child: UserAvatar(
                          photoUrl: msg.senderPhotoUrl,
                          name: msg.senderName ?? '?',
                          size: 30),
                    )
                  else if (!widget.isMine && !widget.showAvatar)
                    const SizedBox(width: 36),

                  // Bubble
                  Flexible(
                    child: _BubbleBody(
                      msg: msg,
                      isMine: widget.isMine,
                      onImageTap: () {
                        if (msg.mediaUrl != null) {
                          Navigator.pushNamed(context, '/imageView',
                              arguments: {'url': msg.mediaUrl});
                        }
                      },
                    ),
                  ),
                ],
              ),

              // Reactions
              if (msg.reactions.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    top: 2,
                    left: widget.isMine ? 0 : 36,
                    right: widget.isMine ? 0 : 0,
                  ),
                  child: _ReactionBar(
                    reactions: msg.reactions,
                    isMine: widget.isMine,
                    onTap: (emoji) => widget.onReact?.call(msg, emoji),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bubble body (all content types) ─────────────────────────────────────
class _BubbleBody extends StatelessWidget {
  final MessageModel msg;
  final bool isMine;
  final VoidCallback? onImageTap;
  const _BubbleBody({required this.msg, required this.isMine, this.onImageTap});

  @override
  Widget build(BuildContext context) {
    // ── Forwarded label ──
    Widget? forwardedLabel;
    if (msg.isForwarded) {
      forwardedLabel = Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.forward_rounded, size: 12, color: Colors.white.withOpacity(0.4)),
          const SizedBox(width: 4),
          Text('أُعيد توجيهه', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
        ]),
      );
    }

    // ── Reply preview ──
    Widget? replyWidget;
    if (msg.replyToId != null && msg.replyToText != null) {
      replyWidget = Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: isMine ? AppColors.accent : Colors.white54, width: 2.5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(msg.replyToSenderId ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent)),
          const SizedBox(height: 2),
          Text(msg.replyToText ?? '', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      );
    }

    // ── Content based on type ──
    Widget content;
    switch (msg.type) {
      case MessageType.image:
        content = _ImageContent(url: msg.mediaUrl ?? '', onTap: onImageTap);
        break;
      case MessageType.video:
        content = VideoMessagePlayer(url: msg.mediaUrl ?? '');
        break;
      case MessageType.voice:
        content = VoiceMessagePlayer(url: msg.mediaUrl ?? '', duration: msg.duration ?? 0);
        break;
      case MessageType.sticker:
        content = _StickerContent(url: msg.mediaUrl ?? '');
        break;
      default:
        content = _TextContent(text: msg.text ?? '', isMine: isMine);
    }

    // ── Time + status ──
    final timeStr = DateFormat('HH:mm').format(msg.createdAt.toLocal());
    final timeRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (msg.isEdited)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text('(محرَّر)', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.35))),
          ),
        Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4))),
        if (isMine) ...[
          const SizedBox(width: 3),
          _StatusIcon(status: msg.status),
        ],
      ],
    );

    // ── Sticker: no bubble background ──
    if (msg.type == MessageType.sticker) {
      return Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          content,
          Padding(padding: const EdgeInsets.only(top: 2), child: timeRow),
        ],
      );
    }

    // ── Regular bubble ──
    final radius = BorderRadius.only(
      topLeft:     const Radius.circular(18),
      topRight:    const Radius.circular(18),
      bottomLeft:  Radius.circular(isMine ? 18 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 18),
    );

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
        minWidth: 60,
      ),
      decoration: BoxDecoration(
        color: isMine ? AppColors.bubbleSelf : AppColors.bubbleOther,
        borderRadius: radius,
        border: Border.all(
          color: isMine ? AppColors.bubbleSelfBorder : AppColors.bubbleOtherBorder,
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius.subtract(const BorderRadius.all(Radius.circular(1))),
        child: Padding(
          padding: msg.type == MessageType.image || msg.type == MessageType.video
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (forwardedLabel != null) forwardedLabel,
              if (replyWidget != null) replyWidget,
              content,
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: msg.type == MessageType.image || msg.type == MessageType.video
                      ? const EdgeInsets.fromLTRB(0, 0, 8, 6)
                      : EdgeInsets.zero,
                  child: timeRow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Text content ─────────────────────────────────────────────────────────
class _TextContent extends StatelessWidget {
  final String text;
  final bool isMine;
  const _TextContent({required this.text, required this.isMine});

  @override
  Widget build(BuildContext context) => SelectableText(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 15,
      height: 1.45,
    ),
  );
}

// ─── Image content ────────────────────────────────────────────────────────
class _ImageContent extends StatelessWidget {
  final String url;
  final VoidCallback? onTap;
  const _ImageContent({required this.url, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: 220,
        placeholder: (_, __) => Container(
          width: 220, height: 160,
          color: AppColors.bgLight,
          child: const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 220, height: 120, color: AppColors.bgLight,
          child: const Center(child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted)),
        ),
      ),
    ),
  );
}

// ─── Sticker content ──────────────────────────────────────────────────────
class _StickerContent extends StatelessWidget {
  final String url;
  const _StickerContent({required this.url});
  bool get _isEmoji => url.startsWith('emoji:');
  String get _emoji => url.replaceFirst('emoji:', '');

  @override
  Widget build(BuildContext context) {
    if (_isEmoji) {
      return SizedBox(
        width: 90, height: 90,
        child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 64))),
      );
    }
    return CachedNetworkImage(
      imageUrl: url, width: 130, height: 130, fit: BoxFit.contain,
      placeholder: (_, __) => const SizedBox(width: 130, height: 130,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))),
      errorWidget: (_, __, ___) => const SizedBox(width: 130, height: 130,
          child: Center(child: Text('🙂', style: TextStyle(fontSize: 60)))),
    );
  }
}

// ─── Status icon ──────────────────────────────────────────────────────────
class _StatusIcon extends StatelessWidget {
  final MessageStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(width: 10, height: 10,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54));
      case MessageStatus.sent:
        return const Icon(Icons.check_rounded, size: 13, color: Colors.white54);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded, size: 13, color: Colors.white54);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded, size: 13, color: AppColors.read);
    }
  }
}

// ─── Reaction bar ─────────────────────────────────────────────────────────
class _ReactionBar extends StatelessWidget {
  final Map<String, dynamic> reactions;
  final bool isMine;
  final Function(String)? onTap;
  const _ReactionBar({required this.reactions, required this.isMine, this.onTap});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    children: reactions.entries.map((e) {
      final count = (e.value as Map?)?['userIds']?.length ?? 0;
      return GestureDetector(
        onTap: () => onTap?.call(e.key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.bgLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Text('${e.key} $count',
              style: const TextStyle(fontSize: 12, color: Colors.white)),
        ),
      );
    }).toList(),
  );
}

// ─── Dev badge ────────────────────────────────────────────────────────────
class _DevBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF1744)]),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text('👑 مطور', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
  );
}

// ─── Deleted bubble ───────────────────────────────────────────────────────
class _DeletedBubble extends StatelessWidget {
  final bool isMine;
  const _DeletedBubble({required this.isMine});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      bottom: 3,
      left: isMine ? 48 : 8,
      right: isMine ? 8 : 48,
    ),
    child: Row(
      mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.block_rounded, size: 14, color: Colors.white.withOpacity(0.3)),
            const SizedBox(width: 6),
            Text('تم حذف هذه الرسالة',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.3), fontStyle: FontStyle.italic)),
          ]),
        ),
      ],
    ),
  );
}

// ─── Options sheet ────────────────────────────────────────────────────────
class _OptionsSheet extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final AppLocalizations l;
  final VoidCallback? onReply, onCopy, onEdit, onDelete, onSelect;

  const _OptionsSheet({
    required this.message, required this.isMine, required this.l,
    this.onReply, this.onCopy, this.onEdit, this.onDelete, this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      // Handle
      Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 16),
      // Reaction row
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: AppConstants.reactions.take(10).map((e) => GestureDetector(
            onTap: () { Navigator.pop(context); },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12)),
              child: Text(e, style: const TextStyle(fontSize: 22)),
            ),
          )).toList(),
        ),
      ),
      const SizedBox(height: 12),
      const Divider(color: AppColors.divider),
      if (onReply != null)  _tile(Icons.reply_rounded, l['reply'], AppColors.textSecondary, onReply!),
      if (message.type == MessageType.text && onCopy != null)
        _tile(Icons.copy_rounded, l['copy'], AppColors.textSecondary, onCopy!),
      if (onEdit != null)   _tile(Icons.edit_rounded, l['edit'], AppColors.textSecondary, onEdit!),
      if (onSelect != null) _tile(Icons.check_box_outlined, 'تحديد', AppColors.textSecondary, onSelect!),
      if (onDelete != null) _tile(Icons.delete_rounded, l['delete'], AppColors.accent, onDelete!),
    ]),
  );

  Widget _tile(IconData icon, String label, Color color, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: color, size: 20),
        title: Text(label, style: TextStyle(color: color, fontSize: 14)),
        dense: true,
        onTap: onTap,
      );
}
