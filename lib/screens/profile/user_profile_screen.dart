import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/glass_container.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  bool _openingChat = false;
  bool _showPass = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final u = await AuthService().getUserById(widget.userId);
      if (mounted) setState(() { _user = u; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p   = context.watch<AppProvider>();
    final l   = AppLocalizations.of(context);
    final me  = p.currentUser!;
    final isAdmin = me.isAdmin;

    if (_loading) return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
    );
    if (_user == null) return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: Text(l['noResults'], style: const TextStyle(color: AppColors.textMuted))),
    );

    final u         = _user!;
    final isSelf    = me.id == u.id;
    final isContact = me.contacts.contains(u.id);
    final isBlocked = me.blocked.contains(u.id);
    final isDev     = u.id == AppConstants.devId || u.isAdmin;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: SafeArea(child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.95), border: Border(bottom: BorderSide(color: AppColors.glassBorder))),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
              Expanded(child: Row(children: [
                Text(u.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                if (isDev) ...[
                  const SizedBox(width: 6),
                  _DevTag(),
                ],
              ])),
              if (!isSelf)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                  color: AppColors.bgCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) async {
                    if (v == 'block')   { await AuthService().toggleBlock(u.id); p.refreshUser(); _load(); }
                    if (v == 'contact') { await AuthService().toggleContact(u.id); p.refreshUser(); _load(); }
                    if (v == 'report')  { _showReport(context); }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'contact', child: Row(children: [
                      Icon(isContact ? Icons.person_remove_rounded : Icons.person_add_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(isContact ? l['removeContact'] : l['addContact'], style: const TextStyle(color: Colors.white)),
                    ])),
                    PopupMenuItem(value: 'block', child: Row(children: [
                      Icon(isBlocked ? Icons.lock_open_rounded : Icons.block_rounded, size: 18, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Text(isBlocked ? l['unblock'] : l['block'], style: const TextStyle(color: AppColors.accent)),
                    ])),
                    const PopupMenuItem(value: 'report', child: Row(children: [
                      Icon(Icons.flag_rounded, size: 18, color: Colors.orange),
                      SizedBox(width: 10),
                      Text('بلاغ', style: TextStyle(color: Colors.orange)),
                    ])),
                  ],
                ),
            ]),
          ),

          // Body
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Avatar
              GestureDetector(
                onTap: u.photoUrl != null ? () => Navigator.pushNamed(context, AppRoutes.imageView, arguments: {'url': u.photoUrl}) : null,
                child: Hero(
                  tag: 'avatar_${u.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: isDev ? [BoxShadow(color: AppColors.devGold.withOpacity(0.4), blurRadius: 24, spreadRadius: 3)] : null,
                    ),
                    child: UserAvatar(photoUrl: u.photoUrl, name: u.name, size: 90),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Name + dev badge
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(u.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                if (isDev) ...[const SizedBox(width: 8), _DevTag()],
              ]),
              const SizedBox(height: 4),
              Text('@${u.username}', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.55))),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: u.isOnline ? AppColors.online : AppColors.offline)),
                const SizedBox(width: 6),
                Text(u.isOnline ? l['online'] : l['offline'],
                    style: TextStyle(color: u.isOnline ? AppColors.online : AppColors.textMuted, fontSize: 13)),
              ]),

              // Bio if present
              if (u.bio != null && u.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.glassBorder)),
                  child: Text(u.bio!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
                ),
              ],

              const SizedBox(height: 20),

              // Action buttons
              if (!isSelf) Row(children: [
                Expanded(child: _ActionBtn(
                  icon: Icons.message_rounded,
                  label: l['message'],
                  loading: _openingChat,
                  onTap: isBlocked ? null : () async {
                    setState(() => _openingChat = true);
                    try {
                      final chat = await ChatService().getOrCreateChat(me.id, u.id);
                      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.chat,
                          arguments: {'chatId': chat.id, 'otherUserId': u.id});
                    } catch (_) {
                      setState(() => _openingChat = false);
                    }
                  },
                )),
              ]),

              const SizedBox(height: 16),

              // Info card
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _InfoRow(icon: Icons.badge_rounded, label: 'ID', value: u.id,
                      onCopy: () => _copy(context, u.id)),
                  const Divider(color: AppColors.divider, height: 20),
                  _InfoRow(icon: Icons.alternate_email_rounded, label: l['username'], value: '@${u.username}',
                      onCopy: () => _copy(context, u.username)),
                  if (u.bio != null && u.bio!.isNotEmpty) ...[
                    const Divider(color: AppColors.divider, height: 20),
                    _InfoRow(icon: Icons.info_outline_rounded, label: 'Bio', value: u.bio!),
                  ],
                ]),
              ),

              // Admin-only: extra info including password hash
              if (isAdmin && !isSelf) ...[
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(14),
                  borderColor: AppColors.devGold.withOpacity(0.3),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.admin_panel_settings_rounded, size: 16, color: AppColors.devGold),
                      const SizedBox(width: 6),
                      const Text('معلومات المشرف', style: TextStyle(color: AppColors.devGold, fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                    const Divider(color: AppColors.divider, height: 16),
                    _InfoRow(icon: Icons.calendar_today_rounded, label: 'تاريخ التسجيل', value: _fmtDate(u.createdAt)),
                    const Divider(color: AppColors.divider, height: 16),
                    _InfoRow(icon: Icons.access_time_rounded, label: 'آخر ظهور', value: _fmtDate(u.lastSeen)),
                    const Divider(color: AppColors.divider, height: 16),
                    Row(children: [
                      const Icon(Icons.lock_rounded, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('كلمة السر (hash)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text(
                          _showPass ? u.passwordHash : '••••••••••••••••••••••••••••••••',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ])),
                      GestureDetector(
                        onTap: () => setState(() => _showPass = !_showPass),
                        child: Icon(_showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 18, color: AppColors.textMuted),
                      ),
                    ]),
                    const Divider(color: AppColors.divider, height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      _AdminBtn(label: u.isBanned ? 'رفع الحظر' : 'حظر', color: AppColors.accent,
                          onTap: () async {
                            await AuthService().toggleBan(u.id);
                            _load();
                          }),
                      _AdminBtn(label: u.isAdmin ? 'إزالة مشرف' : 'ترقية مشرف', color: AppColors.devGold,
                          onTap: () async {
                            await AuthService().toggleAdmin(u.id);
                            _load();
                          }),
                    ]),
                  ]),
                ),
              ],

              const SizedBox(height: 24),
            ]),
          )),
        ])),
      ),
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'غير معروف';
    return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2,'0')}';
  }

  void _copy(BuildContext ctx, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
      content: Text('تم النسخ'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating));
  }

  void _showReport(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
      content: Text('تم إرسال البلاغ'), behavior: SnackBarBehavior.floating));
  }
}

class _DevTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8F00)]),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Text('👑', style: TextStyle(fontSize: 9)),
      SizedBox(width: 3),
      Text('مطور', style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.w900)),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback? onTap; final bool loading;
  const _ActionBtn({required this.icon, required this.label, this.onTap, this.loading = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        gradient: onTap != null ? AppGradients.accentGradient : null,
        color: onTap == null ? AppColors.bgLight : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onTap != null ? [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,3))] : null,
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (loading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        else Icon(icon, size: 18, color: onTap != null ? Colors.white : AppColors.textMuted),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: onTap != null ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label, value; final VoidCallback? onCopy;
  const _InfoRow({required this.icon, required this.label, required this.value, this.onCopy});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: AppColors.textMuted),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    ])),
    if (onCopy != null)
      GestureDetector(onTap: onCopy, child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textMuted)),
  ]);
}

class _AdminBtn extends StatelessWidget {
  final String label; final Color color; final VoidCallback onTap;
  const _AdminBtn({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.4))),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    ),
  );
}
