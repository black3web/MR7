import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../services/admin_dashboard_service.dart';

/// لوحة التحكم الجبارة للمبرمج - تحكم كامل بكل شيء
class AdminDashboardScreen extends StatefulWidget {
  final String userId;

  const AdminDashboardScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AdminDashboardService _admin = AdminDashboardService();
  
  late TabController _tabController;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _aiStats;
  Map<String, dynamic>? _userAnalytics;
  bool _isLoading = true;
  int _activeUsersNow = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadDashboardData();
    _startRealTimeMonitoring();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final stats = await _admin.getAppStatistics();
    final aiStats = await _admin.getAIStatistics();
    final userAnalytics = await _admin.getUsersAnalytics();

    setState(() {
      _stats = stats;
      _aiStats = aiStats;
      _userAnalytics = userAnalytics;
      _isLoading = false;
    });
  }

  void _startRealTimeMonitoring() {
    _admin.watchActiveUsers().listen((count) {
      if (mounted) {
        setState(() => _activeUsersNow = count);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.red),
            SizedBox(width: 8),
            Text('لوحة التحكم'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'نظرة عامة'),
            Tab(icon: Icon(Icons.people), text: 'المستخدمين'),
            Tab(icon: Icon(Icons.report), text: 'البلاغات'),
            Tab(icon: Icon(Icons.smart_toy), text: 'الذكاء الاصطناعي'),
            Tab(icon: Icon(Icons.settings), text: 'الإعدادات'),
            Tab(icon: Icon(Icons.code), text: 'متقدم'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildReportsTab(),
                _buildAITab(),
                _buildSettingsTab(),
                _buildAdvancedTab(),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ── Overview Tab ───────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLiveMonitoringCard(),
          const SizedBox(height: 16),
          _buildStatisticsGrid(),
          const SizedBox(height: 16),
          _buildQuickActionsCard(),
          const SizedBox(height: 16),
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildLiveMonitoringCard() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'المراقبة الحية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLiveStat('متصل الآن', _activeUsersNow, Icons.people, Colors.green),
                _buildLiveStat('رسائل/دقيقة', 0, Icons.message, Colors.blue),
                _buildLiveStat('طلبات AI', 0, Icons.smart_toy, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStat(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('المستخدمين', _stats?['totalUsers'] ?? 0, Icons.people, Colors.blue),
        _buildStatCard('المحادثات', _stats?['totalChats'] ?? 0, Icons.chat, Colors.green),
        _buildStatCard('المجموعات', _stats?['totalGroups'] ?? 0, Icons.groups, Colors.orange),
        _buildStatCard('القصص', _stats?['totalStories'] ?? 0, Icons.auto_stories, Colors.purple),
        _buildStatCard('الرسائل', _stats?['totalMessages'] ?? 0, Icons.message, Colors.cyan),
        _buildStatCard('نشط اليوم', _stats?['activeToday'] ?? 0, Icons.trending_up, Colors.pink),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إجراءات سريعة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionButton('إرسال إعلان', Icons.campaign, _sendBroadcast),
                _buildQuickActionButton('تنظيف البيانات', Icons.cleaning_services, _cleanupDatabase),
                _buildQuickActionButton('تصدير بيانات', Icons.download, _exportData),
                _buildQuickActionButton('إعادة تحميل', Icons.refresh, _loadDashboardData),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'النشاط الأخير',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _admin.watchAIRequests(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'لا يوجد نشاط حديث',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.take(5).length,
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.smart_toy, color: AppColors.accent, size: 20),
                      title: Text(
                        item['service'] ?? 'Unknown',
                        style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        _formatTimestamp(item['timestamp']),
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: Icon(
                        item['success'] == true ? Icons.check_circle : Icons.error,
                        color: item['success'] == true ? Colors.green : Colors.red,
                        size: 16,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ── Users Tab ──────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'بحث عن مستخدم...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: _searchUsers,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildUserAnalyticsCard(),
              const SizedBox(height: 16),
              // قائمة المستخدمين ستكون هنا
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserAnalyticsCard() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تحليلات المستخدمين',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnalyticsStat(
                  'مُوَثَّق',
                  _userAnalytics?['verifiedUsers'] ?? 0,
                  Icons.verified,
                  Colors.blue,
                ),
                _buildAnalyticsStat(
                  'متصل',
                  _userAnalytics?['onlineUsers'] ?? 0,
                  Icons.circle,
                  Colors.green,
                ),
                _buildAnalyticsStat(
                  'الكل',
                  _userAnalytics?['totalUsers'] ?? 0,
                  Icons.people,
                  AppColors.accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsStat(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ── Reports Tab ────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildReportsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _admin.getRecentReports(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data ?? [];
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'لا توجد بلاغات',
                  style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(report);
          },
        );
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.report_problem, color: Colors.red),
        title: Text(
          report['reason'] ?? 'بلاغ',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        subtitle: Text(
          'من: ${report['reportedBy']} • ${_formatTimestamp(report['createdAt'])}',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'delete', child: Text('حذف المحتوى')),
            const PopupMenuItem(value: 'dismiss', child: Text('تجاهل')),
            const PopupMenuItem(value: 'ban', child: Text('حظر المستخدم')),
          ],
          onSelected: (value) => _handleReportAction(report, value.toString()),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ── AI Tab ─────────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAITab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAIStatisticsCard(),
        const SizedBox(height: 16),
        _buildAIServicesCard(),
      ],
    );
  }

  Widget _buildAIStatisticsCard() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات الذكاء الاصطناعي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAIStat('الطلبات', _aiStats?['totalRequests'] ?? 0),
                _buildAIStat('ناجح', _aiStats?['successfulRequests'] ?? 0),
                _buildAIStat('نسبة النجاح', '${_aiStats?['successRate'] ?? '0'}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIStat(String label, dynamic value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAIServicesCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _admin.getSystemStatus(),
      builder: (context, snapshot) {
        final services = snapshot.data ?? {};

        return Card(
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'خدمات الذكاء الاصطناعي',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...AppConstants.aiServiceKeys.map((key) {
                  final isEnabled = services[key] ?? true;
                  final name = AppConstants.aiServiceNames[key] ?? key;

                  return SwitchListTile(
                    title: Text(name, style: TextStyle(color: AppColors.textPrimary)),
                    value: isEnabled,
                    activeColor: AppColors.accent,
                    onChanged: (value) => _toggleAIService(key, value),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ── Settings & Advanced Tabs ───────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: AppColors.surface,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('الثيمات والألوان'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('التخزين وقاعدة البيانات'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('الأمان والصلاحيات'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAdvancedCard(
          'تصدير البيانات',
          'تصدير جميع البيانات بصيغة JSON',
          Icons.download,
          _exportAllData,
        ),
        _buildAdvancedCard(
          'عرض السجلات',
          'عرض سجلات النظام والأخطاء',
          Icons.article,
          _viewLogs,
        ),
        _buildAdvancedCard(
          'تنظيف متقدم',
          'حذف البيانات القديمة والمنتهية',
          Icons.cleaning_services,
          _cleanupDatabase,
        ),
      ],
    );
  }

  Widget _buildAdvancedCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accent),
        title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ── Actions ────────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _searchUsers(String query) async {
    final users = await _admin.searchUsers(query: query, limit: 50);
    // عرض النتائج
  }

  Future<void> _handleReportAction(Map<String, dynamic> report, String action) async {
    switch (action) {
      case 'delete':
        await _admin.deleteReportedContent(
          reportId: report['id'],
          contentType: report['contentType'] ?? 'message',
          contentId: report['contentId'],
        );
        _showSnackBar('تم حذف المحتوى');
        break;
      case 'dismiss':
        await _admin.dismissReport(report['id']);
        _showSnackBar('تم تجاهل البلاغ');
        break;
      case 'ban':
        // عرض dialog للتأكيد
        break;
    }
    setState(() {});
  }

  Future<void> _toggleAIService(String serviceName, bool enabled) async {
    await _admin.toggleAIService(serviceName: serviceName, enabled: enabled);
    setState(() {});
    _showSnackBar('تم ${enabled ? 'تفعيل' : 'تعطيل'} ${AppConstants.aiServiceNames[serviceName]}');
  }

  Future<void> _sendBroadcast() async {
    // عرض dialog لإدخال الرسالة
  }

  Future<void> _cleanupDatabase() async {
    final result = await _admin.cleanupDatabase();
    _showSnackBar('تم حذف ${result['deletedStories']} قصة و ${result['deletedNotifications']} إشعار');
  }

  Future<void> _exportData() async {
    // عرض dialog لاختيار ما سيتم تصديره
  }

  Future<void> _exportAllData() async {
    final collections = ['users', 'chats', 'groups', 'stories'];
    for (final collection in collections) {
      final data = await _admin.exportData(collection: collection);
      final json = jsonEncode(data);
      // حفظ أو عرض البيانات
      Clipboard.setData(ClipboardData(text: json));
    }
    _showSnackBar('تم نسخ البيانات إلى الحافظة');
  }

  void _viewLogs() {
    // عرض السجلات
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    // تنسيق الوقت
    return 'منذ قليل';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
