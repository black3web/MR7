import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _confirmLogout = false;
  Map<Permission, PermissionStatus> _perms = {};

  @override
  void initState() { super.initState(); _loadPermissions(); }

  Future<void> _loadPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.notification,
    ].request();
    if (mounted) setState(() => _perms = statuses);
  }

  @override
  Widget build(BuildContext context) {
    final l    = AppLocalizations.of(context);
    final p    = context.watch<AppProvider>();
    final user = p.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: SafeArea(child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.95), border: Border(bottom: BorderSide(color: AppColors.glassBorder))),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
              Text(l['settings'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
              const Spacer(),
              Text('v${AppConstants.appVersion}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ]),
          ),

          Expanded(child: ListView(
            padding: const EdgeInsets.all(14),
            children: [

              // ── Appearance ──
              _Section(title: l['appearance']),
              GlassContainer(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
                // Theme
                _Tile(icon: Icons.palette_rounded, iconColor: const Color(0xFF7B1FA2), title: l['theme'],
                  trailing: _Dropdown(
                    value: p.theme,
                    items: {'dark': l['dark'], 'light': l['light'], 'system': l['system']},
                    onChanged: (v) => p.setTheme(v!),
                  )),
                _Divider(),

                // Accent color
                _Tile(icon: Icons.color_lens_rounded, iconColor: AppColors.accent, title: l['accentColor'],
                  trailing: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: _accentColors.map((c) => _ColorDot(
                      color: c, selected: p.accentColorValue == c.value,
                      onTap: () => p.setAccentColor(c),
                    )).toList()),
                  )),
                _Divider(),

                // Font scale
                _Tile(icon: Icons.text_fields_rounded, iconColor: const Color(0xFF1976D2), title: l['fontSize'],
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    _SmallBtn(Icons.remove_rounded, () => p.setFontScale((p.fontScale - 0.1).clamp(0.8, 1.4))),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${(p.fontScale * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                    _SmallBtn(Icons.add_rounded, () => p.setFontScale((p.fontScale + 0.1).clamp(0.8, 1.4))),
                  ])),
              ])),

              // ── Chat Background ──
              _Section(title: 'خلفية الدردشة'),
              GlassContainer(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('اختر خلفية المحادثات', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: AppConstants.chatBackgrounds.map((bg) {
                    final sel = p.chatBackground == bg['id'];
                    return GestureDetector(
                      onTap: () => p.setChatBackground(bg['id'] == 'none' ? null : bg['id']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 10),
                        width: 60, height: 80,
                        decoration: BoxDecoration(
                          gradient: (bg['gradient'] as List?)?.length == 2
                              ? LinearGradient(colors: (bg['gradient'] as List).map((c) => Color(c as int)).toList(), begin: Alignment.topLeft, end: Alignment.bottomRight)
                              : null,
                          color: bg['gradient'] == null ? AppColors.bgLight : null,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? AppColors.accent : AppColors.glassBorder, width: sel ? 2 : 0.8),
                          boxShadow: sel ? [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 8)] : null,
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          if (sel) const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.accent),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(bg['label'] as String, textAlign: TextAlign.center,
                              style: TextStyle(color: sel ? AppColors.accent : AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 4),
                        ]),
                      ),
                    );
                  }).toList()),
                ),
              ])),

              // ── Language ──
              _Section(title: l['language']),
              GlassContainer(padding: const EdgeInsets.symmetric(vertical: 4), child:
                _Tile(icon: Icons.language_rounded, iconColor: const Color(0xFF00897B), title: l['language'],
                  trailing: _Dropdown(
                    value: p.language,
                    items: const {'ar': '🇮🇶 العربية', 'en': '🇬🇧 English'},
                    onChanged: (v) => p.setLanguage(v!),
                  )),
              ),

              // ── Chat settings ──
              _Section(title: 'الدردشة'),
              GlassContainer(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
                _Tile(icon: Icons.notifications_rounded, iconColor: const Color(0xFFFFA000), title: l['notifications'],
                  trailing: _Switch(
                    value: user?.settings['notifications'] ?? true,
                    onChanged: (v) => _updateSetting('notifications', v),
                  )),
                _Divider(),
                _Tile(icon: Icons.done_all_rounded, iconColor: AppColors.read, title: l['readReceipts'],
                  trailing: _Switch(
                    value: user?.settings['readReceipts'] ?? true,
                    onChanged: (v) => _updateSetting('readReceipts', v),
                  )),
                _Divider(),
                _Tile(icon: Icons.keyboard_rounded, iconColor: const Color(0xFF546E7A), title: 'مؤشر الكتابة',
                  trailing: _Switch(
                    value: user?.settings['typingIndicator'] ?? true,
                    onChanged: (v) => _updateSetting('typingIndicator', v),
                  )),
                _Divider(),
                _Tile(icon: Icons.vibration_rounded, iconColor: const Color(0xFF5C6BC0), title: 'الاهتزاز',
                  trailing: _Switch(
                    value: user?.settings['vibration'] ?? true,
                    onChanged: (v) => _updateSetting('vibration', v),
                  )),
                _Divider(),
                _Tile(icon: Icons.record_voice_over_rounded, iconColor: const Color(0xFFE91E63), title: 'قراءة الرسائل صوتياً',
                  trailing: _Switch(
                    value: user?.settings['textToSpeech'] ?? false,
                    onChanged: (v) => _updateSetting('textToSpeech', v),
                  )),
              ])),

              // ── Privacy ──
              _Section(title: l['privacy']),
              GlassContainer(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
                _Tile(icon: Icons.visibility_rounded, iconColor: const Color(0xFF00897B), title: l['lastSeen'],
                  trailing: _Dropdown(
                    value: user?.privacy['lastSeen'] ?? 'everyone',
                    items: const {'everyone': 'الجميع', 'contacts': 'جهات الاتصال', 'nobody': 'لا أحد'},
                    onChanged: (v) => _updatePrivacy('lastSeen', v!),
                  )),
                _Divider(),
                _Tile(icon: Icons.photo_rounded, iconColor: const Color(0xFF5C6BC0), title: 'صورة الملف',
                  trailing: _Dropdown(
                    value: user?.privacy['photo'] ?? 'everyone',
                    items: const {'everyone': 'الجميع', 'contacts': 'جهات الاتصال', 'nobody': 'لا أحد'},
                    onChanged: (v) => _updatePrivacy('photo', v!),
                  )),
                _Divider(),
                _Tile(icon: Icons.auto_stories_rounded, iconColor: const Color(0xFFE91E63), title: 'القصص',
                  trailing: _Dropdown(
                    value: user?.privacy['stories'] ?? 'everyone',
                    items: const {'everyone': 'الجميع', 'contacts': 'جهات الاتصال', 'nobody': 'لا أحد'},
                    onChanged: (v) => _updatePrivacy('stories', v!),
                  )),
                _Divider(),
                _Tile(icon: Icons.message_rounded, iconColor: const Color(0xFF1976D2), title: 'من يمكنه مراسلتي',
                  trailing: _Dropdown(
                    value: user?.privacy['messages'] ?? 'everyone',
                    items: const {'everyone': 'الجميع', 'contacts': 'جهات الاتصال'},
                    onChanged: (v) => _updatePrivacy('messages', v!),
                  )),
              ])),

              // ── Permissions ──
              _Section(title: 'الأذونات'),
              GlassContainer(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
                _PermTile(label: 'الكاميرا', icon: Icons.camera_alt_rounded, color: const Color(0xFF00BCD4),
                    status: _perms[Permission.camera], onRequest: () => _requestPerm(Permission.camera)),
                _Divider(),
                _PermTile(label: 'الميكروفون', icon: Icons.mic_rounded, color: AppColors.accent,
                    status: _perms[Permission.microphone], onRequest: () => _requestPerm(Permission.microphone)),
                _Divider(),
                _PermTile(label: 'الإشعارات', icon: Icons.notifications_rounded, color: const Color(0xFFFFA000),
                    status: _perms[Permission.notification], onRequest: () => _requestPerm(Permission.notification)),
                _Divider(),
                _PermTile(label: 'التخزين', icon: Icons.storage_rounded, color: const Color(0xFF4CAF50),
                    status: _perms[Permission.storage], onRequest: () => _requestPerm(Permission.storage)),
              ])),

              // ── Account ──
              _Section(title: l['account']),
              GlassContainer(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
                _Tile(icon: Icons.person_rounded, iconColor: AppColors.accent, title: l['editProfile'],
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile)),
                _Divider(),
                _Tile(icon: Icons.people_alt_rounded, iconColor: const Color(0xFF0288D1), title: 'تبديل الحساب',
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                    onTap: () => _showAccountSwitch(context, l, p)),
                _Divider(),
                _Tile(icon: Icons.headset_mic_rounded, iconColor: const Color(0xFF2E7D32), title: l['support'],
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.support)),
                if (context.read<AppProvider>().isAdmin) ...[
                  _Divider(),
                  _Tile(icon: Icons.admin_panel_settings_rounded, iconColor: AppColors.devGold, title: 'لوحة الإدارة',
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.admin)),
                ],
              ])),

              const SizedBox(height: 8),

              // Logout
              GlassContainer(
                padding: EdgeInsets.zero,
                borderColor: AppColors.accent.withOpacity(0.3),
                child: ListTile(
                  leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.logout_rounded, size: 18, color: AppColors.accent)),
                  title: Text(l['logout'], style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: _confirmLogout ? const Text('اضغط مجدداً للتأكيد', style: TextStyle(color: AppColors.accent, fontSize: 11)) : null,
                  onTap: () async {
                    if (!_confirmLogout) {
                      setState(() => _confirmLogout = true);
                      Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _confirmLogout = false); });
                      return;
                    }
                    await context.read<AppProvider>().logout();
                    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                ),
              ),
              const SizedBox(height: 24),
              Center(child: Text('MR7 Chat v${AppConstants.appVersion}', style: TextStyle(color: AppColors.textMuted.withOpacity(0.4), fontSize: 11))),
              const SizedBox(height: 8),
            ],
          )),
        ])),
      ),
    );
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    await AuthService().updateProfile(settings: {key: value});
    if (mounted) context.read<AppProvider>().refreshUser();
  }

  Future<void> _updatePrivacy(String key, dynamic value) async {
    await AuthService().updateProfile(privacy: {key: value});
    if (mounted) context.read<AppProvider>().refreshUser();
  }

  Future<void> _requestPerm(Permission perm) async {
    final status = await perm.request();
    if (status.isPermanentlyDenied) openAppSettings();
    if (mounted) setState(() => _perms[perm] = status);
  }

  void _showAccountSwitch(BuildContext ctx, AppLocalizations l, AppProvider p) {
    showModalBottomSheet(context: ctx, builder: (_) => _AccountSwitchSheet(p: p, l: l, onClose: () => Navigator.pop(ctx)));
  }

  static const List<Color> _accentColors = [
    Color(0xFFFF1744), Color(0xFFE91E63), Color(0xFF9C27B0),
    Color(0xFF3F51B5), Color(0xFF0288D1), Color(0xFF00897B), Color(0xFFFF6D00),
  ];
}

// ── Account switch sheet ──────────────────────────────────────────────────────
class _AccountSwitchSheet extends StatelessWidget {
  final AppProvider p;
  final AppLocalizations l;
  final VoidCallback onClose;
  const _AccountSwitchSheet({required this.p, required this.l, required this.onClose});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('الحسابات المحفوظة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 16),
      if (p.savedAccounts.isEmpty)
        const Padding(padding: EdgeInsets.all(16), child: Text('لا توجد حسابات أخرى', style: TextStyle(color: AppColors.textMuted)))
      else ...p.savedAccounts.map((acc) => ListTile(
        leading: Container(width: 38, height: 38, decoration: BoxDecoration(gradient: AppGradients.accentGradient, shape: BoxShape.circle),
          child: Center(child: Text((acc.name.isNotEmpty ? acc.name[0] : '?').toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))),
        title: Text(acc.name, style: const TextStyle(color: Colors.white)),
        subtitle: Text('@${acc.username}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        trailing: p.currentUser?.id == acc.id
            ? const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20)
            : null,
        onTap: () { onClose(); p.switchAccount(acc.id); },
      )),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () { onClose(); Navigator.pushNamed(context, AppRoutes.login); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.glassBorder)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_rounded, size: 18, color: AppColors.accent),
            SizedBox(width: 8),
            Text('إضافة حساب', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    ]),
  );
}

// ── Shared widgets ────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
    child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.2)),
  );
}

class _Tile extends StatelessWidget {
  final IconData icon; final Color iconColor; final String title;
  final Widget? trailing; final VoidCallback? onTap;
  const _Tile({required this.icon, required this.iconColor, required this.title, this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: iconColor.withOpacity(0.14), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 18, color: iconColor)),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14))),
        if (trailing != null) trailing!,
      ]),
    ),
  ));
}

class _PermTile extends StatelessWidget {
  final String label; final IconData icon; final Color color;
  final PermissionStatus? status; final VoidCallback onRequest;
  const _PermTile({required this.label, required this.icon, required this.color, required this.status, required this.onRequest});
  @override
  Widget build(BuildContext context) {
    final granted = status?.isGranted ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 18, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(granted ? 'مسموح' : 'غير مسموح', style: TextStyle(color: granted ? AppColors.online : AppColors.textMuted, fontSize: 11)),
        ])),
        if (!granted) GestureDetector(
          onTap: onRequest,
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
            child: Text('منح', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700))),
        ) else Container(width: 20, height: 20,
          decoration: const BoxDecoration(color: AppColors.online, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 13, color: Colors.white)),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(height: 1, color: AppColors.divider, indent: 56, endIndent: 14);
}

class _Dropdown extends StatelessWidget {
  final String value; final Map<String, String> items; final Function(String?) onChanged;
  const _Dropdown({required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) => DropdownButton<String>(
    value: value, dropdownColor: AppColors.bgCard,
    style: const TextStyle(color: Colors.white, fontSize: 13), underline: const SizedBox(),
    items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
    onChanged: onChanged,
  );
}

class _Switch extends StatelessWidget {
  final bool value; final Function(bool) onChanged;
  const _Switch({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Switch(value: value, onChanged: onChanged, activeColor: AppColors.accent);
}

class _SmallBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _SmallBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 28, height: 28,
      decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.glassBorder)),
      child: Icon(icon, size: 16, color: AppColors.textSecondary)),
  );
}

class _ColorDot extends StatelessWidget {
  final Color color; final bool selected; final VoidCallback onTap;
  const _ColorDot({required this.color, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: selected ? 28 : 24, height: selected ? 28 : 24,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: color, shape: BoxShape.circle,
        border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 2.5),
        boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : null,
      ),
      child: selected ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
    ),
  );
}
