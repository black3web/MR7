import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../config/constants.dart';
import '../models/message_model.dart';
import 'smart_chat_engine.dart';
import 'smart_recommendation_engine.dart';

/// خدمة الإجراءات التلقائية الذكية
/// تنفذ مهام تلقائية بناءً على السياق والسلوك
class SmartAutomationService {
  static final SmartAutomationService _instance = SmartAutomationService._internal();
  factory SmartAutomationService() => _instance;
  SmartAutomationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SmartChatEngine _smartEngine = SmartChatEngine();
  final SmartRecommendationEngine _recommendations = SmartRecommendationEngine();

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Auto Reply ─────────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// رد تلقائي ذكي
  Future<String?> generateAutoReply({
    required String userId,
    required String chatId,
    required MessageModel incomingMessage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // التحقق من تفعيل الرد التلقائي
      final autoReplyEnabled = prefs.getBool('auto_reply_enabled_$userId') ?? false;
      if (!autoReplyEnabled) return null;
      
      // الحالات التي يتم فيها الرد التلقائي
      final autoReplyMode = prefs.getString('auto_reply_mode_$userId') ?? 'off';
      
      if (autoReplyMode == 'off') return null;
      
      // وضع القيادة
      if (autoReplyMode == 'driving') {
        return 'أنا أقود الآن، سأرد عليك لاحقاً 🚗';
      }
      
      // وضع النوم
      if (autoReplyMode == 'sleeping') {
        final hour = DateTime.now().hour;
        if (hour >= 23 || hour < 7) {
          return 'أنا نائم الآن، سأرد عليك في الصباح 😴';
        }
      }
      
      // وضع الاجتماع
      if (autoReplyMode == 'meeting') {
        return 'أنا في اجتماع الآن، سأرد عليك قريباً 📝';
      }
      
      // وضع العمل
      if (autoReplyMode == 'working') {
        return 'أنا مشغول في العمل، سأرد عليك عندما أتفرغ 💼';
      }
      
      // رد مخصص
      final customReply = prefs.getString('auto_reply_custom_$userId');
      if (customReply != null && customReply.isNotEmpty) {
        return customReply;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// تفعيل/تعطيل الرد التلقائي
  Future<void> setAutoReply({
    required String userId,
    required String mode, // off, driving, sleeping, meeting, working, custom
    String? customMessage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (mode == 'off') {
      await prefs.setBool('auto_reply_enabled_$userId', false);
    } else {
      await prefs.setBool('auto_reply_enabled_$userId', true);
      await prefs.setString('auto_reply_mode_$userId', mode);
      
      if (mode == 'custom' && customMessage != null) {
        await prefs.setString('auto_reply_custom_$userId', customMessage);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Smart Do Not Disturb ───────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// عدم الإزعاج الذكي
  Future<bool> shouldSilenceNotification({
    required String userId,
    required String chatId,
    required MessageModel message,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // التحقق من DND اليدوي
      final dndActive = prefs.getBool('dnd_active_$userId') ?? false;
      if (dndActive) {
        // السماح للجهات المهمة
        final allowVip = prefs.getBool('dnd_allow_vip_$userId') ?? true;
        if (allowVip) {
          final isVip = prefs.getBool('vip_contact_${userId}_${message.senderId}') ?? false;
          return !isVip; // لا تكتم إذا كان VIP
        }
        return true; // اكتم الجميع
      }
      
      // DND الذكي (تعلم من سلوك المستخدم)
      final smartDndEnabled = prefs.getBool('smart_dnd_enabled_$userId') ?? false;
      if (!smartDndEnabled) return false;
      
      final hour = DateTime.now().hour;
      
      // ساعات النوم المعتادة
      final sleepStart = prefs.getInt('sleep_start_$userId') ?? 23;
      final sleepEnd = prefs.getInt('sleep_end_$userId') ?? 7;
      
      if ((hour >= sleepStart || hour < sleepEnd)) {
        return true; // كتم أثناء النوم
      }
      
      // أوقات العمل
      final workStart = prefs.getInt('work_start_$userId') ?? 9;
      final workEnd = prefs.getInt('work_end_$userId') ?? 17;
      final isWorkday = DateTime.now().weekday <= 5; // الاثنين-الجمعة
      
      if (isWorkday && hour >= workStart && hour < workEnd) {
        // كتم المحادثات الشخصية أثناء العمل
        final isWorkChat = await _isWorkRelatedChat(chatId);
        return !isWorkChat;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isWorkRelatedChat(String chatId) async {
    // منطق بسيط - يمكن تحسينه
    try {
      final chatDoc = await _firestore.collection(AppConstants.colChats).doc(chatId).get();
      final category = chatDoc.data()?['category'] as String?;
      return category == 'work';
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Auto Archive ───────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// أرشفة تلقائية ذكية
  Future<void> autoArchiveInactiveChats({
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoArchiveEnabled = prefs.getBool('auto_archive_enabled_$userId') ?? false;
      
      if (!autoArchiveEnabled) return;
      
      final inactiveDays = prefs.getInt('auto_archive_days_$userId') ?? 30;
      final threshold = DateTime.now().subtract(Duration(days: inactiveDays));
      
      // جلب المحادثات
      final chatsSnapshot = await _firestore
          .collection(AppConstants.colChats)
          .where('participantIds', arrayContains: userId)
          .get();
      
      final batch = _firestore.batch();
      int archivedCount = 0;
      
      for (final chatDoc in chatsSnapshot.docs) {
        final data = chatDoc.data();
        
        // تخطي المثبتة
        if (data['isPinned'] == true) continue;
        
        // تخطي التي بها رسائل غير مقروءة
        if ((data['unreadCount'] as int? ?? 0) > 0) continue;
        
        // التحقق من آخر رسالة
        final lastMessage = data['lastMessage'] as Map<String, dynamic>?;
        if (lastMessage != null) {
          final timestamp = (lastMessage['timestamp'] as Timestamp?)?.toDate();
          if (timestamp != null && timestamp.isBefore(threshold)) {
            batch.update(chatDoc.reference, {'isArchived': true});
            archivedCount++;
          }
        }
      }
      
      if (archivedCount > 0) {
        await batch.commit();
        print('Auto-archived $archivedCount chats');
      }
    } catch (e) {
      print('Error auto-archiving: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Smart Message Scheduling ───────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// جدولة رسالة ذكية (إرسال في الوقت المناسب)
  Future<void> scheduleSmartMessage({
    required String userId,
    required String chatId,
    required String recipientId,
    required String message,
    MessageType type = MessageType.text,
  }) async {
    try {
      // التنبؤ بأفضل وقت للإرسال
      final prediction = await _recommendations.predictBestReplyTime(
        userId: userId,
        recipientId: recipientId,
      );
      
      final bestHour = prediction['bestHour'] as int;
      final now = DateTime.now();
      
      // حساب موعد الإرسال
      DateTime scheduledTime;
      
      if (now.hour < bestHour) {
        // اليوم في الساعة المحددة
        scheduledTime = DateTime(now.year, now.month, now.day, bestHour);
      } else {
        // غداً في الساعة المحددة
        final tomorrow = now.add(const Duration(days: 1));
        scheduledTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, bestHour);
      }
      
      // حفظ الرسالة المجدولة
      await _firestore.collection(AppConstants.colScheduledMessages).add({
        'userId': userId,
        'chatId': chatId,
        'recipientId': recipientId,
        'message': message,
        'type': type.toString(),
        'scheduledFor': Timestamp.fromDate(scheduledTime),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
      print('Message scheduled for: $scheduledTime');
    } catch (e) {
      print('Error scheduling message: $e');
    }
  }

  /// إرسال الرسائل المجدولة
  Future<void> sendScheduledMessages() async {
    try {
      final now = Timestamp.now();
      
      final snapshot = await _firestore
          .collection(AppConstants.colScheduledMessages)
          .where('status', isEqualTo: 'pending')
          .where('scheduledFor', isLessThanOrEqualTo: now)
          .get();
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // TODO: إرسال الرسالة فعلياً
        // await ChatService().sendMessage(...)
        
        // تحديث الحالة
        await doc.reference.update({'status': 'sent'});
      }
    } catch (e) {
      print('Error sending scheduled messages: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Auto Translation ───────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// ترجمة تلقائية للرسائل
  Future<String?> autoTranslateMessage({
    required String userId,
    required String message,
    required String detectedLanguage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoTranslateEnabled = prefs.getBool('auto_translate_enabled_$userId') ?? false;
      
      if (!autoTranslateEnabled) return null;
      
      final userLanguage = prefs.getString('user_language_$userId') ?? 'ar';
      
      // ترجمة فقط إذا كانت اللغة مختلفة
      if (detectedLanguage != userLanguage) {
        return await _smartEngine.autoTranslate(
          text: message,
          targetLang: userLanguage,
          sourceLang: detectedLanguage,
        );
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Smart Cleanup ──────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تنظيف ذكي للبيانات القديمة
  Future<Map<String, int>> smartCleanup({
    required String userId,
  }) async {
    final results = <String, int>{
      'deletedMessages': 0,
      'deletedMedia': 0,
      'clearedCache': 0,
    };
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تنظيف الرسائل القديمة
      final deleteOldMessages = prefs.getBool('cleanup_old_messages_$userId') ?? false;
      if (deleteOldMessages) {
        final daysToKeep = prefs.getInt('messages_keep_days_$userId') ?? 90;
        final threshold = DateTime.now().subtract(Duration(days: daysToKeep));
        
        results['deletedMessages'] = await _deleteOldMessages(userId, threshold);
      }
      
      // تنظيف الوسائط القديمة
      final deleteOldMedia = prefs.getBool('cleanup_old_media_$userId') ?? false;
      if (deleteOldMedia) {
        final daysToKeep = prefs.getInt('media_keep_days_$userId') ?? 30;
        final threshold = DateTime.now().subtract(Duration(days: daysToKeep));
        
        results['deletedMedia'] = await _deleteOldMedia(userId, threshold);
      }
      
      // تنظيف الكاش
      results['clearedCache'] = await _clearCache(userId);
      
    } catch (e) {
      print('Error in smart cleanup: $e');
    }
    
    return results;
  }

  Future<int> _deleteOldMessages(String userId, DateTime threshold) async {
    int count = 0;
    
    try {
      final chatsSnapshot = await _firestore
          .collection(AppConstants.colChats)
          .where('participantIds', arrayContains: userId)
          .get();
      
      for (final chatDoc in chatsSnapshot.docs) {
        final messagesSnapshot = await chatDoc.reference
            .collection('messages')
            .where('createdAt', isLessThan: Timestamp.fromDate(threshold))
            .get();
        
        final batch = _firestore.batch();
        for (final msgDoc in messagesSnapshot.docs) {
          batch.delete(msgDoc.reference);
          count++;
        }
        
        if (messagesSnapshot.docs.isNotEmpty) {
          await batch.commit();
        }
      }
    } catch (e) {
      print('Error deleting old messages: $e');
    }
    
    return count;
  }

  Future<int> _deleteOldMedia(String userId, DateTime threshold) async {
    // TODO: حذف الملفات الوسائطية القديمة من Storage
    return 0;
  }

  Future<int> _clearCache(String userId) async {
    // TODO: تنظيف الكاش المحلي
    return 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Background Tasks ───────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تشغيل المهام الخلفية الذكية
  Future<void> runBackgroundTasks(String userId) async {
    try {
      // 1. أرشفة تلقائية
      await autoArchiveInactiveChats(userId: userId);
      
      // 2. إرسال الرسائل المجدولة
      await sendScheduledMessages();
      
      // 3. تنظيف أسبوعي (كل أحد)
      final now = DateTime.now();
      if (now.weekday == DateTime.sunday) {
        await smartCleanup(userId: userId);
      }
      
      // 4. مزامنة البيانات
      await _recommendations.trackUserBehavior(
        userId: userId,
        action: 'background_task_completed',
        metadata: {'timestamp': now.toIso8601String()},
      );
      
      print('Background tasks completed successfully');
    } catch (e) {
      print('Error running background tasks: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Smart Suggestions ──────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// اقتراحات ذكية للإجراءات
  Future<List<Map<String, dynamic>>> getSuggestedActions({
    required String userId,
  }) async {
    final suggestions = <Map<String, dynamic>>[];
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. اقتراح تفعيل DND في وقت النوم
      final hour = DateTime.now().hour;
      if (hour >= 22 && !(prefs.getBool('dnd_active_$userId') ?? false)) {
        suggestions.add({
          'type': 'enable_dnd',
          'title': 'تفعيل عدم الإزعاج',
          'description': 'حان وقت النوم، هل تريد تفعيل عدم الإزعاج؟',
          'action': 'enable_dnd',
        });
      }
      
      // 2. اقتراح أرشفة المحادثات القديمة
      final lastArchive = prefs.getString('last_archive_$userId');
      if (lastArchive == null || 
          DateTime.now().difference(DateTime.parse(lastArchive)).inDays > 7) {
        suggestions.add({
          'type': 'archive_old',
          'title': 'أرشفة المحادثات القديمة',
          'description': 'لديك محادثات غير نشطة، هل تريد أرشفتها؟',
          'action': 'auto_archive',
        });
      }
      
      // 3. اقتراح تنظيف البيانات
      final storageUsed = prefs.getInt('storage_used_$userId') ?? 0;
      if (storageUsed > 1000) { // أكثر من 1GB
        suggestions.add({
          'type': 'cleanup',
          'title': 'تنظيف البيانات',
          'description': 'لديك ${(storageUsed / 1000).toStringAsFixed(1)} GB من البيانات، هل تريد التنظيف؟',
          'action': 'smart_cleanup',
        });
      }
      
    } catch (e) {
      print('Error getting suggestions: $e');
    }
    
    return suggestions;
  }
}
