import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/user_avatar.dart';
import '../../services/notification_service.dart';

class HomeDrawer extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const HomeDrawer({super.key, required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    final p    = context.watch<AppProvider>();
    final l    = AppLocalizations.of(context);
    final user = p.currentUser;
    if (user == null) return const Drawer();

    return Drawer(
      backgroundColor: AppColors.bgCard,
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Profile header
          GestureDetector(
            onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.profile); },
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: BoxDecoration(
                gradient: AppGradients.drawerGradient,
                border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  UserAvatar(photoUrl: user.photoUrl, name: user.name, size: 56),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(user.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (user.isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8F00)]),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('👑 مطور', style: TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.w900)),
                        ),
                    ]),
                    const SizedBox(height: 2),
                    Text('@${user.username}', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
                  ])),
                ]),
                const SizedBox(height: 12),
                // Stats row
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _Stat(label: 'جهات\nالاتصال', value: '${user.contacts.length}'),
                  _StatDivider(),
                  _Stat(label: 'المجموعات', value: '—'),
                  _StatDivider(),
                  _Stat(label: 'القصص', value: '—'),
                ]),
              ]),
            ),
          ),

          // Menu items
          Expanded(child: SingleChildScrollView(
            child: Column(children: [
              _MenuItem(icon: Icons.person_rounded, label: l['profile'], color: AppColors.accent,
                  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.profile); }),
              _MenuItem(icon: Icons.edit_rounded, label: l['editProfile'], color: const Color(0xFF4285F4),
                  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.editProfile); }),
              _MenuItem(icon: Icons.notifications_rounded, label: 'الإشعارات', color: const Color(0xFFFFA000),
                  badge: StreamBuilder<int>(
                    stream: NotificationService().unreadCount(user.id),
                    builder: (_, s) {
                      final n = s.data ?? 0;
                      return n > 0 ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                        child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ) : const SizedBox();
                    },
                  ),
                  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.notifications); }),
              const _SectionDivider(label: 'AI'),
              _MenuItem(icon: Icons.auto_awesome_rounded, label: 'Gemini 2.5 Flash', color: const Color(0xFF4285F4),
                  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.geminiChat); }),
              _MenuItem(icon: Icons.psychology_rounded, label: 'DeepSeek AI', color: const Color(0xFF00BCD4),
                  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.deepSeekChat); }),
              _MenuItem(icon: Icons.image_rounded, label: 'Image Generator', color: const Color(0xFFE91E63),
                  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.imageGen); }),
              _MenuItem(icon: Icons.movie_creation_rounded, label: 'Video AI', color: const Color(0xFF7B1FA2),
                  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.videoGen); }),
              _MenuItem(icon: Icons.music_note_rounded, label: 'AI Music', color: const Color(0xFFAD1457),
                  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.musicAi); }),
              const _SectionDivider(label: 'أخرى'),
              _MenuItem(icon: Icons.settings_rounded, label: l['settings'], color: AppColors.textMuted,
                  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.settings); }),
              _MenuItem(icon: Icons.headset_mic_rounded, label: l['support'], color: const Color(0xFF2E7D32),
                  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.support); }),
              if (user.isAdmin)
                _MenuItem(icon: Icons.admin_panel_settings_rounded, label: 'لوحة الإدارة', color: AppColors.devGold,
                    onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.admin); }),
            ]),
          )),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.glassBorder))),
            child: GestureDetector(
              onTap: () async {
                await p.logout();
                if (context.mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.logout_rounded, size: 18, color: AppColors.accent)),
                const SizedBox(width: 12),
                Text(l['logout'], style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10), textAlign: TextAlign.center),
  ]);
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(height: 32, width: 0.7, color: AppColors.glassBorder);
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Row(children: [
      const Expanded(child: Divider(color: AppColors.divider, height: 1)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
      const Expanded(child: Divider(color: AppColors.divider, height: 1)),
    ]),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  final VoidCallback onTap; final Widget? badge;
  const _MenuItem({required this.icon, required this.label, required this.color, required this.onTap, this.badge});
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 18, color: color)),
    title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
    trailing: badge,
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
  );
}
