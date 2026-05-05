import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../services/notification_service.dart';
import '../../widgets/user_avatar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _typeIcon(String t) {
    switch (t) {
      case 'message':       return Icons.message_rounded;
      case 'group_message': return Icons.group_rounded;
      case 'story':         return Icons.auto_stories_rounded;
      case 'reaction':      return Icons.favorite_rounded;
      case 'ai':            return Icons.auto_awesome_rounded;
      default:              return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'message':       return const Color(0xFF1565C0);
      case 'group_message': return const Color(0xFF00897B);
      case 'story':         return const Color(0xFFE91E63);
      case 'reaction':      return const Color(0xFFF57C00);
      case 'ai':            return const Color(0xFF6A1B9A);
      default:              return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AppProvider>().currentUser?.id ?? '';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: SafeArea(child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.95), border: Border(bottom: BorderSide(color: AppColors.glassBorder))),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
              const Text('الإشعارات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => NotificationService().markAllRead(uid),
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: const Text('قراءة الكل', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ),
          Expanded(child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: NotificationService().getNotifications(uid),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2));
              final list = snap.data!;
              if (list.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 80, height: 80,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.bgLight, border: Border.all(color: AppColors.glassBorder)),
                  child: Icon(Icons.notifications_off_outlined, size: 36, color: AppColors.textMuted.withOpacity(0.4))),
                const SizedBox(height: 16),
                const Text('لا توجد إشعارات', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
              ]));
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final n       = list[i];
                  final isUnread = !(n['read'] as bool? ?? true);
                  final ts      = n['createdAt'] != null
                      ? DateFormat('HH:mm | dd/MM').format((n['createdAt'] as dynamic).toDate().toLocal())
                      : '';
                  return Dismissible(
                    key: Key(n['docId'] as String),
                    direction: DismissDirection.endToStart,
                    background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                      color: AppColors.accent.withOpacity(0.15),
                      child: const Icon(Icons.delete_rounded, color: AppColors.accent)),
                    onDismissed: (_) => NotificationService().deleteNotif(n['docId'] as String),
                    child: InkWell(
                      onTap: () {
                        NotificationService().markRead(n['docId'] as String);
                        final chatId  = n['chatId']  as String?;
                        final groupId = n['groupId'] as String?;
                        if (chatId != null && n['fromUserId'] != null) {
                          Navigator.pushNamed(context, AppRoutes.chat,
                              arguments: {'chatId': chatId, 'otherUserId': n['fromUserId']});
                        } else if (groupId != null) {
                          Navigator.pushNamed(context, AppRoutes.groupChat, arguments: {'groupId': groupId});
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUnread ? AppColors.accent.withOpacity(0.07) : AppColors.bgLight.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isUnread ? AppColors.accent.withOpacity(0.25) : AppColors.glassBorder, width: 0.8),
                        ),
                        child: Row(children: [
                          Stack(children: [
                            UserAvatar(photoUrl: n['fromPhotoUrl'] as String?, name: n['fromName'] as String? ?? '?', size: 44),
                            Positioned(bottom: 0, right: 0,
                              child: Container(width: 18, height: 18,
                                decoration: BoxDecoration(color: _typeColor(n['type'] as String? ?? ''), shape: BoxShape.circle, border: Border.all(color: AppColors.bgCard, width: 1.5)),
                                child: Icon(_typeIcon(n['type'] as String? ?? ''), size: 10, color: Colors.white))),
                          ]),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(n['title'] as String? ?? '',
                                style: TextStyle(color: Colors.white, fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500, fontSize: 14))),
                              Text(ts, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                            ]),
                            const SizedBox(height: 3),
                            Text(n['body'] as String? ?? '',
                              style: TextStyle(color: isUnread ? AppColors.textSecondary : AppColors.textMuted, fontSize: 13),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          ])),
                          if (isUnread)
                            Container(width: 8, height: 8, margin: const EdgeInsets.only(left: 6),
                                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                        ]),
                      ),
                    ),
                  );
                },
              );
            },
          )),
        ])),
      ),
    );
  }
}
