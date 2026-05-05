import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/message_model.dart';
import 'smart_chat_engine.dart';

/// نظام الأولويات الذكي للرسائل
/// يرتب المحادثات والرسائل بناءً على الأهمية والسياق
class SmartPrioritySystem {
  static final SmartPrioritySystem _instance = SmartPrioritySystem._internal();
  factory SmartPrioritySystem() => _instance;
  SmartPrioritySystem._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SmartChatEngine _smartEngine = SmartChatEngine();

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Message Priority Calculation ───────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// حساب أولوية الرسالة (0-100)
  Future<double> calculateMessagePriority({
    required String userId,
    required String chatId,
    required MessageModel message,
  }) async {
    double priority = 50.0; // القيمة الافتراضية

    // 1. الإلحاح (0-20 نقطة)
    final urgency = _smartEngine._detectUrgency(message.text ?? '');
    if (urgency == 'high') priority += 20;
    else if (urgency == 'medium') priority += 10;

    // 2. المشاعر (0-15 نقطة)
    final emotion = await _smartEngine._detectEmotion(message.text ?? '');
    if (emotion == 'angry' || emotion == 'sad') priority += 15; // مشاعر سلبية = أولوية
    else if (emotion == 'happy' || emotion == 'grateful') priority += 5;

    // 3. النية (0-10 نقطة)
    final intent = _smartEngine._detectIntent(message.text ?? '');
    if (intent == 'question') priority += 10; // الأسئلة لها أولوية
    else if (intent == 'invitation') priority += 8;

    // 4. المرسل (0-20 نقطة)
    final senderPriority = await _getSenderPriority(userId, message.senderId);
    priority += senderPriority;

    // 5. الوقت (0-10 نقطة)
    if (message.createdAt != null) {
      final age = DateTime.now().difference(message.createdAt!);
      if (age.inMinutes < 5) priority += 10; // رسائل جديدة جداً
      else if (age.inMinutes < 30) priority += 5;
    }

    // 6. الكلمات المفتاحية الهامة (0-15 نقطة)
    if (await _containsImportantKeywords(message.text ?? '', userId)) {
      priority += 15;
    }

    // 7. الإشارة المباشرة (@mention) (0-10 نقطة)
    if (message.text?.contains('@') == true) {
      priority += 10;
    }

    return priority.clamp(0, 100);
  }

  /// حساب أولوية المرسل بناءً على العلاقة
  Future<double> _getSenderPriority(String userId, String senderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // عدد التفاعلات السابقة
      final interactionKey = 'behavior_${userId}_chat_with_$senderId';
      final interactions = prefs.getInt(interactionKey) ?? 0;
      
      double priority = 0.0;
      
      // كثرة التفاعل = أولوية أعلى
      if (interactions > 100) priority = 20;
      else if (interactions > 50) priority = 15;
      else if (interactions > 20) priority = 10;
      else if (interactions > 5) priority = 5;
      
      // التفاعل الأخير
      final lastInteractionKey = '${interactionKey}_last';
      final lastInteraction = prefs.getString(lastInteractionKey);
      if (lastInteraction != null) {
        final lastTime = DateTime.parse(lastInteraction);
        final daysSince = DateTime.now().difference(lastTime).inDays;
        
        // تفاعل حديث = أولوية أعلى
        if (daysSince < 1) priority += 5;
        else if (daysSince < 7) priority += 3;
      }
      
      // جهات الاتصال المميزة
      final favoriteKey = 'favorite_contact_$userId\_$senderId';
      if (prefs.getBool(favoriteKey) ?? false) {
        priority += 10;
      }
      
      return priority;
    } catch (e) {
      return 0;
    }
  }

  /// التحقق من وجود كلمات مفتاحية هامة
  Future<bool> _containsImportantKeywords(String text, String userId) async {
    final lowerText = text.toLowerCase();
    
    // كلمات عامة هامة
    final generalKeywords = [
      'عاجل', 'urgent', 'مهم', 'important', 'ضروري',
      'مساعدة', 'help', 'طارئ', 'emergency',
      'اجتماع', 'meeting', 'موعد', 'appointment',
    ];
    
    for (final keyword in generalKeywords) {
      if (lowerText.contains(keyword)) return true;
    }
    
    // كلمات مفتاحية مخصصة للمستخدم
    final prefs = await SharedPreferences.getInstance();
    final customKeywordsKey = 'custom_keywords_$userId';
    final customKeywords = prefs.getStringList(customKeywordsKey) ?? [];
    
    for (final keyword in customKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) return true;
    }
    
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Chat Ranking ───────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// ترتيب المحادثات حسب الأولوية
  Future<List<Map<String, dynamic>>> rankChats({
    required String userId,
    required List<Map<String, dynamic>> chats,
  }) async {
    final rankedChats = <Map<String, dynamic>>[];
    
    for (final chat in chats) {
      final chatId = chat['id'] as String;
      final priority = await _calculateChatPriority(userId, chatId, chat);
      
      rankedChats.add({
        ...chat,
        'priority': priority,
      });
    }
    
    // ترتيب تنازلي حسب الأولوية
    rankedChats.sort((a, b) => (b['priority'] as double).compareTo(a['priority'] as double));
    
    return rankedChats;
  }

  /// حساب أولوية المحادثة
  Future<double> _calculateChatPriority(
    String userId,
    String chatId,
    Map<String, dynamic> chatData,
  ) async {
    double priority = 50.0;
    
    // 1. عدد الرسائل غير المقروءة (0-30 نقطة)
    final unreadCount = chatData['unreadCount'] as int? ?? 0;
    if (unreadCount > 10) priority += 30;
    else if (unreadCount > 5) priority += 20;
    else if (unreadCount > 0) priority += 10;
    
    // 2. آخر رسالة (0-20 نقطة)
    final lastMessage = chatData['lastMessage'] as Map<String, dynamic>?;
    if (lastMessage != null) {
      final lastMessageTime = (lastMessage['timestamp'] as Timestamp?)?.toDate();
      if (lastMessageTime != null) {
        final minutesSince = DateTime.now().difference(lastMessageTime).inMinutes;
        if (minutesSince < 5) priority += 20;
        else if (minutesSince < 30) priority += 15;
        else if (minutesSince < 60) priority += 10;
        else if (minutesSince < 180) priority += 5;
      }
      
      // محتوى آخر رسالة
      final lastMessageText = lastMessage['text'] as String?;
      if (lastMessageText != null) {
        final urgency = _smartEngine._detectUrgency(lastMessageText);
        if (urgency == 'high') priority += 15;
      }
    }
    
    // 3. نوع المحادثة (0-10 نقطة)
    final isGroup = chatData['isGroup'] as bool? ?? false;
    if (!isGroup) priority += 10; // محادثات فردية لها أولوية أعلى
    
    // 4. التثبيت (0-25 نقطة)
    final isPinned = chatData['isPinned'] as bool? ?? false;
    if (isPinned) priority += 25;
    
    // 5. تفاعل المستخدم (0-15 نقطة)
    final interactionPriority = await _getChatInteractionPriority(userId, chatId);
    priority += interactionPriority;
    
    return priority.clamp(0, 100);
  }

  Future<double> _getChatInteractionPriority(String userId, String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // عدد مرات فتح المحادثة
      final openCountKey = 'behavior_${userId}_open_chat_$chatId';
      final openCount = prefs.getInt(openCountKey) ?? 0;
      
      if (openCount > 100) return 15;
      if (openCount > 50) return 10;
      if (openCount > 20) return 5;
      
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Smart Filtering ────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تصفية ذكية للمحادثات
  Future<List<Map<String, dynamic>>> smartFilter({
    required String userId,
    required List<Map<String, dynamic>> chats,
    required String filterType,
  }) async {
    switch (filterType) {
      case 'urgent':
        return _filterUrgentChats(chats);
      
      case 'unread':
        return chats.where((c) => (c['unreadCount'] as int? ?? 0) > 0).toList();
      
      case 'important':
        return await _filterImportantChats(userId, chats);
      
      case 'recent':
        return _filterRecentChats(chats);
      
      case 'groups':
        return chats.where((c) => c['isGroup'] == true).toList();
      
      case 'personal':
        return chats.where((c) => c['isGroup'] != true).toList();
      
      default:
        return chats;
    }
  }

  List<Map<String, dynamic>> _filterUrgentChats(List<Map<String, dynamic>> chats) {
    return chats.where((chat) {
      final lastMessage = chat['lastMessage'] as Map<String, dynamic>?;
      if (lastMessage == null) return false;
      
      final text = lastMessage['text'] as String? ?? '';
      final urgency = _smartEngine._detectUrgency(text);
      return urgency == 'high';
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _filterImportantChats(
    String userId,
    List<Map<String, dynamic>> chats,
  ) async {
    final importantChats = <Map<String, dynamic>>[];
    
    for (final chat in chats) {
      final priority = await _calculateChatPriority(
        userId,
        chat['id'] as String,
        chat,
      );
      
      if (priority > 70) {
        importantChats.add(chat);
      }
    }
    
    return importantChats;
  }

  List<Map<String, dynamic>> _filterRecentChats(List<Map<String, dynamic>> chats) {
    final now = DateTime.now();
    
    return chats.where((chat) {
      final lastMessage = chat['lastMessage'] as Map<String, dynamic>?;
      if (lastMessage == null) return false;
      
      final timestamp = (lastMessage['timestamp'] as Timestamp?)?.toDate();
      if (timestamp == null) return false;
      
      return now.difference(timestamp).inHours < 24;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Smart Grouping ─────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تجميع ذكي للمحادثات
  Future<Map<String, List<Map<String, dynamic>>>> smartGroupChats({
    required String userId,
    required List<Map<String, dynamic>> chats,
  }) async {
    final grouped = <String, List<Map<String, dynamic>>>{
      'priority': [],
      'work': [],
      'personal': [],
      'groups': [],
      'archived': [],
      'other': [],
    };
    
    for (final chat in chats) {
      // أرشيف
      if (chat['isArchived'] == true) {
        grouped['archived']!.add(chat);
        continue;
      }
      
      // أولوية عالية
      final priority = await _calculateChatPriority(
        userId,
        chat['id'] as String,
        chat,
      );
      
      if (priority > 75) {
        grouped['priority']!.add(chat);
        continue;
      }
      
      // مجموعات
      if (chat['isGroup'] == true) {
        grouped['groups']!.add(chat);
        continue;
      }
      
      // تصنيف حسب المحتوى
      final category = await _categorizeChatByContent(chat);
      if (grouped.containsKey(category)) {
        grouped[category]!.add(chat);
      } else {
        grouped['other']!.add(chat);
      }
    }
    
    return grouped;
  }

  Future<String> _categorizeChatByContent(Map<String, dynamic> chat) async {
    final lastMessage = chat['lastMessage'] as Map<String, dynamic>?;
    if (lastMessage == null) return 'other';
    
    final text = lastMessage['text'] as String? ?? '';
    final topic = await _smartEngine._detectTopic(text, null);
    
    if (topic == 'work') return 'work';
    if (topic == 'family') return 'personal';
    
    return 'other';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Priority Notifications ─────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحديد نوع الإشعار بناءً على الأولوية
  Future<Map<String, dynamic>> determineNotificationType({
    required String userId,
    required MessageModel message,
    required String chatId,
  }) async {
    final priority = await calculateMessagePriority(
      userId: userId,
      chatId: chatId,
      message: message,
    );
    
    // أولوية عالية جداً
    if (priority >= 80) {
      return {
        'type': 'high_priority',
        'sound': 'urgent',
        'vibration': 'strong',
        'heads_up': true,
        'led_color': 'red',
      };
    }
    
    // أولوية عالية
    if (priority >= 60) {
      return {
        'type': 'priority',
        'sound': 'default',
        'vibration': 'medium',
        'heads_up': true,
        'led_color': 'blue',
      };
    }
    
    // أولوية عادية
    if (priority >= 40) {
      return {
        'type': 'normal',
        'sound': 'default',
        'vibration': 'short',
        'heads_up': false,
        'led_color': 'green',
      };
    }
    
    // أولوية منخفضة
    return {
      'type': 'low_priority',
      'sound': 'silent',
      'vibration': 'none',
      'heads_up': false,
      'led_color': 'none',
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Auto Archive ───────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// أرشفة تلقائية للمحادثات غير النشطة
  Future<List<String>> suggestChatsToArchive({
    required String userId,
    required List<Map<String, dynamic>> chats,
  }) async {
    final suggestions = <String>[];
    final now = DateTime.now();
    
    for (final chat in chats) {
      // تخطي المحادثات المثبتة
      if (chat['isPinned'] == true) continue;
      
      // تخطي المحادثات التي بها رسائل غير مقروءة
      if ((chat['unreadCount'] as int? ?? 0) > 0) continue;
      
      final lastMessage = chat['lastMessage'] as Map<String, dynamic>?;
      if (lastMessage == null) continue;
      
      final lastMessageTime = (lastMessage['timestamp'] as Timestamp?)?.toDate();
      if (lastMessageTime == null) continue;
      
      final daysSinceLastMessage = now.difference(lastMessageTime).inDays;
      
      // اقتراح أرشفة المحادثات غير النشطة لأكثر من 30 يوم
      if (daysSinceLastMessage > 30) {
        // التحقق من التفاعل
        final interactionPriority = await _getChatInteractionPriority(
          userId,
          chat['id'] as String,
        );
        
        // إذا كان التفاعل منخفض
        if (interactionPriority < 5) {
          suggestions.add(chat['id'] as String);
        }
      }
    }
    
    return suggestions;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Focus Mode ─────────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// وضع التركيز - إظهار المحادثات المهمة فقط
  Future<List<Map<String, dynamic>>> getFocusModeChats({
    required String userId,
    required List<Map<String, dynamic>> chats,
  }) async {
    final focusChats = <Map<String, dynamic>>[];
    
    for (final chat in chats) {
      final priority = await _calculateChatPriority(
        userId,
        chat['id'] as String,
        chat,
      );
      
      // فقط الأولوية العالية
      if (priority >= 65) {
        focusChats.add(chat);
      }
    }
    
    return focusChats;
  }
}
