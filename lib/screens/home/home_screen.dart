import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/notification_service.dart';
import '../../widgets/mr7_logo.dart';
import '../chat/chats_tab.dart';
import '../chat/groups_tab.dart';
import '../ai/ai_services_tab.dart';
import 'home_drawer.dart';
import 'stories_row.dart';
import 'broadcast_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _chatFilter = 'all';
  int _tabIdx = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() => _tabIdx = _tabCtrl.index));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AppProvider>().currentUser?.id;
      if (uid != null) {
        context.read<AppProvider>().refreshUser();
        NotificationService().startListening(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    NotificationService().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p   = context.watch<AppProvider>();
    final l   = AppLocalizations.of(context);
    final uid = p.currentUser?.id ?? '';
    if (p.currentUser == null) return const SizedBox();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: HomeDrawer(scaffoldKey: _scaffoldKey),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: SafeArea(child: Column(children: [
          // ── Top bar ──
          _TopBar(
            scaffoldKey: _scaffoldKey,
            uid: uid,
            tabIdx: _tabIdx,
            onSearch: () => Navigator.pushNamed(context, AppRoutes.search),
            onNotif: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),

          // ── Broadcast banner ──
          const BroadcastBanner(),

          // ── Stories ──
          const StoriesRow(),

          // ── Tab bar ──
          _TabBar(ctrl: _tabCtrl, l: l),

          // ── Chat filter chips (only on chats tab) ──
          if (_tabIdx == 0) _ChatFilterBar(
            current: _chatFilter,
            onChanged: (f) => setState(() => _chatFilter = f),
            l: l,
          ),

          // ── Content ──
          Expanded(child: TabBarView(
            controller: _tabCtrl,
            children: [
              ChatsTab(filter: _chatFilter),
              const GroupsTab(),
              const AiServicesTab(),
            ],
          )),
        ])),
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String uid;
  final int tabIdx;
  final VoidCallback onSearch, onNotif;
  const _TopBar({required this.scaffoldKey, required this.uid, required this.tabIdx, required this.onSearch, required this.onNotif});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
    child: Row(children: [
      // Menu
      GestureDetector(
        onTap: () => scaffoldKey.currentState?.openDrawer(),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.glassBase, border: Border.all(color: AppColors.glassBorder)),
          child: const Icon(Icons.menu_rounded, size: 20, color: AppColors.textSecondary),
        ),
      ),
      const Spacer(),
      const MR7Logo(fontSize: 26),
      const Spacer(),
      // Notification bell with badge
      GestureDetector(
        onTap: onNotif,
        child: Stack(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.glassBase, border: Border.all(color: AppColors.glassBorder)),
            child: const Icon(Icons.notifications_rounded, size: 20, color: AppColors.textSecondary),
          ),
          StreamBuilder<int>(
            stream: NotificationService().unreadCount(uid),
            builder: (_, snap) {
              final cnt = snap.data ?? 0;
              if (cnt == 0) return const SizedBox();
              return Positioned(top: 0, right: 0, child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(gradient: AppGradients.accentGradient, shape: BoxShape.circle, border: Border.all(color: AppColors.bgDark, width: 1.5)),
                child: Text(cnt > 9 ? '9+' : '$cnt',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800)),
              ));
            },
          ),
        ]),
      ),
      const SizedBox(width: 8),
      // Search
      GestureDetector(
        onTap: onSearch,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.glassBase, border: Border.all(color: AppColors.glassBorder)),
          child: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
        ),
      ),
    ]),
  );
}

// ─── Tab bar ──────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final TabController ctrl;
  final AppLocalizations l;
  const _TabBar({required this.ctrl, required this.l});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    height: 40,
    decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.glassBorder)),
    child: TabBar(
      controller: ctrl,
      indicator: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: AppGradients.accentGradient),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      padding: const EdgeInsets.all(3),
      tabs: [
        Tab(icon: const Icon(Icons.message_rounded, size: 16), text: l['chats']),
        Tab(icon: const Icon(Icons.group_rounded, size: 16), text: l['groups']),
        Tab(icon: const Icon(Icons.auto_awesome_rounded, size: 16), text: 'AI'),
      ],
    ),
  );
}

// ─── Chat filter bar ──────────────────────────────────────────────────────────
class _ChatFilterBar extends StatelessWidget {
  final String current;
  final Function(String) onChanged;
  final AppLocalizations l;
  const _ChatFilterBar({required this.current, required this.onChanged, required this.l});

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'id': 'all',      'label': l['all']},
      {'id': 'unread',   'label': l['unread']},
      {'id': 'contacts', 'label': l['contacts']},
    ];
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: filters.map((f) {
          final sel = current == f['id'];
          return GestureDetector(
            onTap: () => onChanged(f['id']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                gradient: sel ? AppGradients.accentGradient : null,
                color: sel ? null : AppColors.bgLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? AppColors.accent : AppColors.glassBorder),
              ),
              child: Text(f['label']!, style: TextStyle(
                  color: sel ? Colors.white : AppColors.textSecondary,
                  fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
