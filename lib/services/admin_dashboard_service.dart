import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import 'dart:async';

/// خدمة لوحة التحكم الجبارة للمبرمج
/// توفر تحكم كامل بكل جوانب التطبيق
class AdminDashboardService {
  static final AdminDashboardService _instance = AdminDashboardService._internal();
  factory AdminDashboardService() => _instance;
  AdminDashboardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// التحقق من صلاحيات المبرمج
  Future<bool> isDevAccount(String userId) async {
    return userId == AppConstants.devId;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Statistics & Analytics ─────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// إحصائيات عامة للتطبيق
  Future<Map<String, dynamic>> getAppStatistics() async {
    try {
      final users = await _firestore.collection(AppConstants.colUsers).count().get();
      final chats = await _firestore.collection(AppConstants.colChats).count().get();
      final groups = await _firestore.collection(AppConstants.colGroups).count().get();
      final stories = await _firestore.collection(AppConstants.colStories).count().get();
      
      // احصاءات متقدمة
      final activeToday = await _getActiveUsersToday();
      final messagesCount = await _getTotalMessagesCount();
      final storageUsed = await _getTotalStorageUsed();
      
      return {
        'totalUsers': users.count ?? 0,
        'totalChats': chats.count ?? 0,
        'totalGroups': groups.count ?? 0,
        'totalStories': stories.count ?? 0,
        'activeToday': activeToday,
        'totalMessages': messagesCount,
        'storageUsedMB': storageUsed,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<int> _getActiveUsersToday() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final snapshot = await _firestore
          .collection(AppConstants.colUsers)
          .where('lastActive', isGreaterThan: Timestamp.fromDate(startOfDay))
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getTotalMessagesCount() async {
    try {
      // مجموع الرسائل من جميع المحادثات
      int total = 0;
      final chats = await _firestore.collection(AppConstants.colChats).get();
      
      for (final chat in chats.docs) {
        final msgs = await chat.reference.collection('messages').count().get();
        total += msgs.count ?? 0;
      }
      
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<double> _getTotalStorageUsed() async {
    // تقدير تقريبي - يمكن استبداله بخدمة Firebase Storage
    return 0.0;
  }

  /// إحصائيات الذكاء الاصطناعي
  Future<Map<String, dynamic>> getAIStatistics() async {
    try {
      final logs = await _firestore
          .collection(AppConstants.colAiLogs)
          .orderBy('timestamp', descending: true)
          .limit(1000)
          .get();

      final Map<String, int> serviceUsage = {};
      final Map<String, int> successRate = {};
      int totalRequests = 0;
      int successfulRequests = 0;

      for (final doc in logs.docs) {
        final data = doc.data();
        final service = data['service'] as String? ?? 'unknown';
        final success = data['success'] as bool? ?? false;

        totalRequests++;
        serviceUsage[service] = (serviceUsage[service] ?? 0) + 1;
        
        if (success) {
          successfulRequests++;
          successRate[service] = (successRate[service] ?? 0) + 1;
        }
      }

      return {
        'totalRequests': totalRequests,
        'successfulRequests': successfulRequests,
        'successRate': totalRequests > 0 
            ? (successfulRequests / totalRequests * 100).toStringAsFixed(2) 
            : '0',
        'serviceUsage': serviceUsage,
        'serviceSuccessRate': successRate,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// إحصائيات المستخدمين المفصلة
  Future<Map<String, dynamic>> getUsersAnalytics() async {
    try {
      final users = await _firestore.collection(AppConstants.colUsers).get();
      
      int verifiedUsers = 0;
      int onlineUsers = 0;
      final Map<String, int> usersByCountry = {};
      
      for (final doc in users.docs) {
        final data = doc.data();
        
        if (data['isVerified'] == true) verifiedUsers++;
        if (data['isOnline'] == true) onlineUsers++;
        
        final country = data['country'] as String? ?? 'Unknown';
        usersByCountry[country] = (usersByCountry[country] ?? 0) + 1;
      }

      return {
        'totalUsers': users.size,
        'verifiedUsers': verifiedUsers,
        'onlineUsers': onlineUsers,
        'usersByCountry': usersByCountry,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── User Management ────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// البحث عن مستخدمين
  Future<List<Map<String, dynamic>>> searchUsers({
    String? query,
    int limit = 50,
  }) async {
    try {
      Query queryRef = _firestore.collection(AppConstants.colUsers);
      
      if (query != null && query.isNotEmpty) {
        queryRef = queryRef
            .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
            .where('username', isLessThan: '${query.toLowerCase()}z');
      }
      
      final snapshot = await queryRef.limit(limit).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// حظر/إلغاء حظر مستخدم
  Future<void> toggleUserBan({
    required String userId,
    required bool banned,
    String? reason,
  }) async {
    await _firestore.collection(AppConstants.colUsers).doc(userId).update({
      'isBanned': banned,
      'banReason': reason,
      'bannedAt': banned ? FieldValue.serverTimestamp() : null,
    });
  }

  /// توثيق/إلغاء توثيق مستخدم
  Future<void> toggleUserVerification({
    required String userId,
    required bool verified,
  }) async {
    await _firestore.collection(AppConstants.colUsers).doc(userId).update({
      'isVerified': verified,
      'verifiedAt': verified ? FieldValue.serverTimestamp() : null,
    });
  }

  /// حذف مستخدم كلياً
  Future<void> deleteUser(String userId) async {
    final batch = _firestore.batch();
    
    // حذف المستخدم
    batch.delete(_firestore.collection(AppConstants.colUsers).doc(userId));
    
    // حذف محادثاته
    final chats = await _firestore
        .collection(AppConstants.colChats)
        .where('participantIds', arrayContains: userId)
        .get();
    
    for (final chat in chats.docs) {
      batch.delete(chat.reference);
    }
    
    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Content Moderation ─────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// الحصول على البلاغات الأخيرة
  Future<List<Map<String, dynamic>>> getRecentReports({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.colReports)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// حذف محتوى مبلغ عنه
  Future<void> deleteReportedContent({
    required String reportId,
    required String contentType, // 'message', 'story', 'group'
    required String contentId,
  }) async {
    final batch = _firestore.batch();
    
    // حذف المحتوى
    if (contentType == 'message') {
      // يجب معرفة chatId أيضاً
      // batch.delete(_firestore.collection(AppConstants.colChats).doc(chatId).collection('messages').doc(contentId));
    } else if (contentType == 'story') {
      batch.delete(_firestore.collection(AppConstants.colStories).doc(contentId));
    } else if (contentType == 'group') {
      batch.delete(_firestore.collection(AppConstants.colGroups).doc(contentId));
    }
    
    // تحديث البلاغ
    batch.update(
      _firestore.collection(AppConstants.colReports).doc(reportId),
      {
        'status': 'resolved',
        'action': 'deleted',
        'resolvedAt': FieldValue.serverTimestamp(),
      },
    );
    
    await batch.commit();
  }

  /// تجاهل بلاغ
  Future<void> dismissReport(String reportId) async {
    await _firestore.collection(AppConstants.colReports).doc(reportId).update({
      'status': 'dismissed',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── System Configuration ───────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تشغيل/إيقاف خدمة AI
  Future<void> toggleAIService({
    required String serviceName,
    required bool enabled,
  }) async {
    await _firestore.collection('settings').doc('ai_services').set({
      serviceName: enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// الحصول على حالة جميع الخدمات
  Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final doc = await _firestore.collection('settings').doc('ai_services').get();
      
      if (!doc.exists) {
        return Map.fromEntries(
          AppConstants.aiServiceKeys.map((key) => MapEntry(key, true)),
        );
      }
      
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  /// تحديث إعدادات التطبيق العامة
  Future<void> updateAppSettings(Map<String, dynamic> settings) async {
    await _firestore.collection('settings').doc('app_config').set(
      settings,
      SetOptions(merge: true),
    );
  }

  /// الحصول على إعدادات التطبيق
  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('app_config').get();
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Broadcast Messages ─────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════────────════════════════

  /// إرسال رسالة جماعية لجميع المستخدمين
  Future<void> sendBroadcastMessage({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
  }) async {
    await _firestore.collection(AppConstants.colBroadcast).add({
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'sentBy': AppConstants.devId,
    });

    // إرسال إشعار لجميع المستخدمين
    final users = await _firestore.collection(AppConstants.colUsers).get();
    final batch = _firestore.batch();
    
    for (final user in users.docs) {
      batch.set(
        _firestore.collection(AppConstants.colNotifs).doc(),
        {
          'toUserId': user.id,
          'fromUserId': AppConstants.devId,
          'type': 'broadcast',
          'title': title,
          'body': message,
          'imageUrl': imageUrl,
          'actionUrl': actionUrl,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
    }
    
    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Real-time Monitoring ───────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// مراقبة المستخدمين النشطين في الوقت الفعلي
  Stream<int> watchActiveUsers() {
    return _firestore
        .collection(AppConstants.colUsers)
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// مراقبة الإحصائيات في الوقت الفعلي
  Stream<Map<String, dynamic>> watchStatistics() {
    return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
      return await getAppStatistics();
    });
  }

  /// مراقبة طلبات AI الحية
  Stream<List<Map<String, dynamic>>> watchAIRequests() {
    return _firestore
        .collection(AppConstants.colAiLogs)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Advanced Features ──────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تنظيف قاعدة البيانات
  Future<Map<String, int>> cleanupDatabase() async {
    int deletedStories = 0;
    int deletedNotifications = 0;

    try {
      // حذف القصص المنتهية
      final expiredStories = await _firestore
          .collection(AppConstants.colStories)
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();

      final batch = _firestore.batch();
      for (final story in expiredStories.docs) {
        batch.delete(story.reference);
        deletedStories++;
      }

      // حذف الإشعارات القديمة (أكثر من 30 يوم)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final oldNotifications = await _firestore
          .collection(AppConstants.colNotifs)
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      for (final notif in oldNotifications.docs) {
        batch.delete(notif.reference);
        deletedNotifications++;
      }

      await batch.commit();

      return {
        'deletedStories': deletedStories,
        'deletedNotifications': deletedNotifications,
      };
    } catch (e) {
      return {'error': -1};
    }
  }

  /// تصدير البيانات
  Future<Map<String, dynamic>> exportData({
    required String collection,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final data = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();

      return {
        'collection': collection,
        'count': data.length,
        'data': data,
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
