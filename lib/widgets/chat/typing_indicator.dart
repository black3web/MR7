import 'package:flutter/material.dart';
import 'dart:async';
import '../../config/theme.dart';

/// مؤشر الكتابة الحي - يظهر عندما يكتب المستخدم الآخر
class TypingIndicator extends StatefulWidget {
  final List<String> typingUsers;
  final bool showInBubble;

  const TypingIndicator({
    super.key,
    required this.typingUsers,
    this.showInBubble = true,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final typingText = _getTypingText();

    if (widget.showInBubble) {
      return _buildBubbleIndicator(typingText);
    } else {
      return _buildSimpleIndicator(typingText);
    }
  }

  Widget _buildBubbleIndicator(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withOpacity(0.3),
            child: const Icon(Icons.more_horiz, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                _buildDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleIndicator(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildDots(),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(0),
        const SizedBox(width: 4),
        _buildDot(1),
        const SizedBox(width: 4),
        _buildDot(2),
      ],
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final delay = index * 0.15;
        final value = (_animation.value + delay) % 1.0;
        final opacity = 0.3 + (0.7 * value);

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  String _getTypingText() {
    final count = widget.typingUsers.length;
    if (count == 1) {
      return '${widget.typingUsers[0]} يكتب...';
    } else if (count == 2) {
      return '${widget.typingUsers[0]} و ${widget.typingUsers[1]} يكتبان...';
    } else {
      return '$count أشخاص يكتبون...';
    }
  }
}

/// مؤشر الحالة على الإنترنت
class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;
  final bool showBorder;

  const OnlineIndicator({
    super.key,
    required this.isOnline,
    this.size = 12,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: AppColors.primary,
                width: 2,
              )
            : null,
      ),
    );
  }
}

/// مؤشر "آخر ظهور"
class LastSeenIndicator extends StatelessWidget {
  final DateTime? lastSeen;
  final bool isOnline;

  const LastSeenIndicator({
    super.key,
    this.lastSeen,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    String text;

    if (isOnline) {
      text = 'متصل الآن';
    } else if (lastSeen == null) {
      text = '';
    } else {
      text = _formatLastSeen(lastSeen!);
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: isOnline ? Colors.green : AppColors.textSecondary,
      ),
    );
  }

  String _formatLastSeen(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'منذ لحظات';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} يوم';
    } else {
      return 'آخر ظهور ${time.day}/${time.month}';
    }
  }
}

/// مؤشر حالة الرسالة (جاري الإرسال، تم الإرسال، تم التسليم، تم القراءة)
class MessageStatusIndicator extends StatelessWidget {
  final MessageStatus status;
  final bool isRead;
  final bool isDelivered;

  const MessageStatusIndicator({
    super.key,
    required this.status,
    this.isRead = false,
    this.isDelivered = false,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = AppColors.textSecondary;
        break;
      case MessageStatus.sent:
        icon = Icons.done;
        color = AppColors.textSecondary;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = AppColors.textSecondary;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = AppColors.accent;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
    }

    return Icon(icon, size: 16, color: color);
  }
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// مؤشر التحميل للرسائل الوسائطية
class MediaLoadingIndicator extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final bool isUploading;
  final VoidCallback? onCancel;

  const MediaLoadingIndicator({
    super.key,
    required this.progress,
    this.isUploading = true,
    this.onCancel,
  });

  @override
  State<MediaLoadingIndicator> createState() => _MediaLoadingIndicatorState();
}

class _MediaLoadingIndicatorState extends State<MediaLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: widget.progress,
              strokeWidth: 3,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          Text(
            '${(widget.progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.onCancel != null)
            Positioned(
              bottom: 4,
              child: GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// مؤشر التسجيل الصوتي
class RecordingIndicator extends StatefulWidget {
  final int seconds;
  final VoidCallback? onStop;
  final VoidCallback? onCancel;

  const RecordingIndicator({
    super.key,
    required this.seconds,
    this.onStop,
    this.onCancel,
  });

  @override
  State<RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Icon(
                Icons.mic,
                color: Colors.red.withOpacity(0.5 + 0.5 * _controller.value),
                size: 24,
              );
            },
          ),
          const SizedBox(width: 12),
          Text(
            _formatDuration(widget.seconds),
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 16),
          if (widget.onCancel != null)
            GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete, color: Colors.red, size: 20),
              ),
            ),
          if (widget.onStop != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onStop,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.send, color: AppColors.accent, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
