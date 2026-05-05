import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/group_service.dart';
import '../../models/group_model.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/glass_container.dart';
import 'package:intl/intl.dart';

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});
  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final l = AppLocalizations.of(context);
    final user = p.currentUser;
    if (user == null) return const SizedBox();

    return Stack(children: [
      Column(children: [
        // ── Tabs: My Groups | Discover ──
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          height: 38,
          decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.glassBorder)),
          child: TabBar(
            controller: _tabCtrl,
            indicator: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: AppGradients.accentGradient),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            padding: const EdgeInsets.all(2),
            tabs: [Tab(text: l['myGroups']), const Tab(text: 'اكتشاف')],
          ),
        ),
        Expanded(child: TabBarView(
          controller: _tabCtrl,
          children: [
            _MyGroupsTab(userId: user.id, l: l),
            _DiscoverGroupsTab(userId: user.id),
          ],
        )),
      ]),

      // ── FAB ──
      Positioned(
        bottom: 16, right: 16,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _FabBtn(
            icon: Icons.group_add_rounded,
            label: 'إنشاء',
            color: AppColors.primary,
            onTap: () => _showCreateDialog(context, l, user.id),
          ),
          const SizedBox(height: 10),
          _FabBtn(
            icon: Icons.search_rounded,
            label: 'انضمام',
            color: const Color(0xFF1565C0),
            onTap: () => _showJoinDialog(context, user.id),
          ),
        ]),
      ),
    ]);
  }

  // ── Create group ──────────────────────────────────────────────────────
  void _showCreateDialog(BuildContext ctx, AppLocalizations l, String userId) {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorder)),
        title: Text(l['createGroup'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _Field(ctrl: nameCtrl, hint: l['groupName'], icon: Icons.group_rounded),
          const SizedBox(height: 10),
          _Field(ctrl: userCtrl, hint: l['groupUsername'], icon: Icons.alternate_email_rounded),
          const SizedBox(height: 10),
          _Field(ctrl: descCtrl, hint: 'وصف المجموعة', icon: Icons.info_outline_rounded, maxLines: 2),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l['cancel'])),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || userCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                final g = await GroupService().createGroup(
                  name: nameCtrl.text.trim(),
                  username: userCtrl.text.trim(),
                  creatorId: userId,
                  description: descCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pushNamed(ctx, AppRoutes.groupChat, arguments: {'groupId': g.id});
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(e.toString().replaceAll('Exception: ', '')),
                  backgroundColor: AppColors.accent,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: Text(l['createGroup']),
          ),
        ],
      ),
    );
  }

  // ── Join group ────────────────────────────────────────────────────────
  void _showJoinDialog(BuildContext ctx, String userId) {
    final ctrl = TextEditingController();
    bool loading = false;
    showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(builder: (_, setSt) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorder)),
        title: const Text('الانضمام لمجموعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('أدخل اسم المستخدم الخاص بالمجموعة', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 12),
          _Field(ctrl: ctrl, hint: 'مثال: mygroup', icon: Icons.alternate_email_rounded),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: loading ? null : () async {
              if (ctrl.text.trim().isEmpty) return;
              setSt(() => loading = true);
              try {
                final g = await GroupService().joinGroupByUsername(ctrl.text.trim(), userId);
                Navigator.pop(dCtx);
                if (g != null && ctx.mounted) {
                  Navigator.pushNamed(ctx, AppRoutes.groupChat, arguments: {'groupId': g.id});
                } else if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('لم يتم العثور على المجموعة'), behavior: SnackBarBehavior.floating));
                }
              } catch (e) {
                setSt(() => loading = false);
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(e.toString().replaceAll('Exception: ', '')),
                  backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating));
              }
            },
            child: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('انضمام'),
          ),
        ],
      )),
    );
  }
}

// ── My Groups tab ──────────────────────────────────────────────────────────
class _MyGroupsTab extends StatelessWidget {
  final String userId;
  final AppLocalizations l;
  const _MyGroupsTab({required this.userId, required this.l});

  @override
  Widget build(BuildContext context) => StreamBuilder<List<GroupModel>>(
    stream: GroupService().getUserGroups(userId),
    builder: (ctx, snap) {
      if (snap.connectionState == ConnectionState.waiting)
        return const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2));
      final groups = snap.data ?? [];
      if (groups.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.bgLight, border: Border.all(color: AppColors.glassBorder)),
          child: Icon(Icons.group_outlined, size: 36, color: AppColors.textMuted.withOpacity(0.5))),
        const SizedBox(height: 16),
        Text(l['noGroups'], style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
        const SizedBox(height: 6),
        const Text('أنشئ أو انضم لمجموعة جديدة', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ]));
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 100, top: 4),
        itemCount: groups.length,
        itemBuilder: (_, i) => _GroupTile(group: groups[i], currentUserId: userId),
      );
    },
  );
}

// ── Discover tab ──────────────────────────────────────────────────────────
class _DiscoverGroupsTab extends StatefulWidget {
  final String userId;
  const _DiscoverGroupsTab({required this.userId});
  @override
  State<_DiscoverGroupsTab> createState() => _DiscoverGroupsTabState();
}

class _DiscoverGroupsTabState extends State<_DiscoverGroupsTab> {
  final _ctrl   = TextEditingController();
  List<GroupModel> _results = [];
  bool _loading = false;
  bool _searched = false;

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _searched = true; });
    try {
      _results = await GroupService().searchGroups(q);
    } catch (_) { _results = []; }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(children: [
        Expanded(child: Container(
          height: 42,
          decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.glassBorder)),
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onSubmitted: (_) => _search(),
            decoration: const InputDecoration(
              hintText: 'ابحث عن مجموعة...',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _search,
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(gradient: AppGradients.accentGradient, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    ),
    Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
        : !_searched
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.explore_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.3)),
                const SizedBox(height: 12),
                const Text('ابحث للعثور على مجموعات', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              ]))
            : _results.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.search_off_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    const Text('لا توجد نتائج', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _results.length,
                    itemBuilder: (_, i) => _GroupTile(group: _results[i], currentUserId: widget.userId, showJoin: true),
                  ),
    ),
  ]);
}

// ── Group tile ────────────────────────────────────────────────────────────
class _GroupTile extends StatelessWidget {
  final GroupModel group;
  final String currentUserId;
  final bool showJoin;
  const _GroupTile({required this.group, required this.currentUserId, this.showJoin = false});

  bool get _isMember => group.memberIds.contains(currentUserId);

  @override
  Widget build(BuildContext context) {
    final lastTime = group.lastMessageAt != null
        ? DateFormat('HH:mm').format(group.lastMessageAt!.toLocal())
        : '';
    return ListTile(
      onTap: () {
        if (_isMember) {
          Navigator.pushNamed(context, AppRoutes.groupChat, arguments: {'groupId': group.id});
        } else if (showJoin) {
          _joinGroup(context);
        }
      },
      leading: UserAvatar(photoUrl: group.photoUrl, name: group.name, size: 48),
      title: Row(children: [
        Expanded(child: Text(group.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
        Text(lastTime, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ]),
      subtitle: Row(children: [
        Expanded(child: Text(
          group.lastMessageText ?? '@${group.username}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        )),
        if (showJoin && !_isMember)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(gradient: AppGradients.accentGradient, borderRadius: BorderRadius.circular(10)),
            child: const Text('انضمام', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        if ((group.unreadCounts[currentUserId] ?? 0) > 0)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
            child: Text(
              '${group.unreadCounts[currentUserId]}',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
      ]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Future<void> _joinGroup(BuildContext ctx) async {
    try {
      await GroupService().addMember(group.id, currentUserId);
      if (ctx.mounted) Navigator.pushNamed(ctx, AppRoutes.groupChat, arguments: {'groupId': group.id});
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

class _FabBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _FabBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0,4))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final int maxLines;
  const _Field({required this.ctrl, required this.hint, required this.icon, this.maxLines = 1});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.glassBorder)),
    child: TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    ),
  );
}
