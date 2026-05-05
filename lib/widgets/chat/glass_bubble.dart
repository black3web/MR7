import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import '../../config/theme.dart';
import '../../models/message_model.dart';

/// فقاعة رسالة بتأثير Glassmorphism
class GlassBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final bool showAvatar;
  final String? senderName;
  final String? senderPhotoUrl;

  const GlassBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.showAvatar = false,
    this.senderName,
    this.senderPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisAlignment:
              isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // صورة المرسل (للرسائل الواردة في المجموعات)
            if (!isMine && showAvatar) _buildAvatar(),
            if (!isMine && showAvatar) const SizedBox(width: 8),

            // الفقاعة
            Flexible(
              child: _buildBubbleContent(context),
            ),

            // مساحة للصورة في الرسائل الصادرة
            if (isMine && showAvatar) const SizedBox(width: 8),
            if (isMine && showAvatar) _buildAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundImage: senderPhotoUrl != null && senderPhotoUrl!.isNotEmpty
          ? NetworkImage(senderPhotoUrl!)
          : null,
      child: senderPhotoUrl == null || senderPhotoUrl!.isEmpty
          ? Text(
              senderName?.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }

  Widget _buildBubbleContent(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // اسم المرسل (في المجموعات)
        if (!isMine && showAvatar && senderName != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Text(
              senderName!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // الرد على رسالة
        if (message.replyToId != null) _buildReplyPreview(),

        // الفقاعة الرئيسية
        GlassContainer(
          blur: 20,
          opacity: 0.15,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMine ? 20 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 20),
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isMine
                ? [
                    AppColors.accent.withOpacity(0.3),
                    AppColors.accent.withOpacity(0.1),
                  ]
                : [
                    AppColors.primary.withOpacity(0.4),
                    AppColors.primary.withOpacity(0.2),
                  ],
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMessageContent(context),
                const SizedBox(height: 4),
                _buildMessageFooter(),
              ],
            ),
          ),
        ),

        // التفاعلات
        if (message.reactions.isNotEmpty) _buildReactions(),
      ],
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppColors.accent,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToSenderId ?? 'Unknown',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyToText ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage();
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.video:
        return _buildVideoMessage();
      case MessageType.voice:
        return _buildVoiceMessage();
      case MessageType.sticker:
        return _buildStickerMessage();
      case MessageType.file:
        return _buildFileMessage();
      case MessageType.location:
        return _buildLocationMessage();
      default:
        return _buildTextMessage();
    }
  }

  Widget _buildTextMessage() {
    return SelectableText(
      message.text ?? '',
      style: TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
    );
  }

  Widget _buildImageMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text != null && message.text!.isNotEmpty) ...[
          Text(
            message.text!,
            style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            message.mediaUrl ?? '',
            fit: BoxFit.cover,
            width: 250,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: 250,
                height: 200,
                color: Colors.grey.withOpacity(0.2),
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stack) => Container(
              width: 250,
              height: 200,
              color: Colors.grey.withOpacity(0.2),
              child: const Icon(Icons.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text != null && message.text!.isNotEmpty) ...[
          Text(
            message.text!,
            style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
        ],
        Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: message.thumbnailUrl != null
                  ? Image.network(
                      message.thumbnailUrl!,
                      width: 250,
                      height: 150,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 250,
                      height: 150,
                      color: Colors.grey.withOpacity(0.2),
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoiceMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mic, color: AppColors.accent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.play_arrow, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.0,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(message.duration ?? 0),
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStickerMessage() {
    return Image.network(
      message.mediaUrl ?? '',
      width: 150,
      height: 150,
      fit: BoxFit.contain,
    );
  }

  Widget _buildFileMessage() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.description, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.fileName ?? 'ملف',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _formatFileSize(message.fileSize ?? 0),
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationMessage() {
    return Column(
      children: [
        Container(
          height: 150,
          width: 250,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.location_on, size: 48, color: Colors.red),
          ),
        ),
        if (message.text != null && message.text!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message.text!,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildMessageFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isEdited)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              'معدلة',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        if (message.isForwarded)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.forward, size: 12, color: AppColors.textSecondary),
          ),
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        if (isMine) ...[
          const SizedBox(width: 4),
          _buildReadStatus(),
        ],
      ],
    );
  }

  Widget _buildReadStatus() {
    IconData icon;
    Color color;

    if (message.isRead) {
      icon = Icons.done_all;
      color = AppColors.accent;
    } else if (message.isDelivered) {
      icon = Icons.done_all;
      color = AppColors.textSecondary;
    } else {
      icon = Icons.done;
      color = AppColors.textSecondary;
    }

    return Icon(icon, size: 16, color: color);
  }

  Widget _buildReactions() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: message.reactions.entries.take(5).map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 14)),
                if (entry.value > 1) ...[
                  const SizedBox(width: 2),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      return '${time.day}/${time.month}';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
