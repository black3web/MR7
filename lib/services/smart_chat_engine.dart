import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/message_model.dart';
import 'ai_service.dart';

/// محرك الذكاء الاصطناعي المتقدم للمحادثات
/// يوفر ميزات ذكية متقدمة لتحسين تجربة المستخدم
class SmartChatEngine {
  static final SmartChatEngine _instance = SmartChatEngine._internal();
  factory SmartChatEngine() => _instance;
  SmartChatEngine._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIService _aiService = AIService();

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Smart Reply Suggestions ────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// توليد 3 اقتراحات ذكية للرد بناءً على آخر رسالة والسياق
  Future<List<String>> generateSmartReplies({
    required String lastMessage,
    List<String>? conversationHistory,
    String? senderName,
    String? relationship, // friend, colleague, family, stranger
  }) async {
    try {
      // تحليل السياق
      final context = await _analyzeContext(
        lastMessage: lastMessage,
        history: conversationHistory,
        relationship: relationship,
      );

      // توليد الردود بناءً على السياق
      final prompt = '''
تحليل الرسالة: "$lastMessage"
السياق: ${context['emotion']} - ${context['intent']}
العلاقة: ${relationship ?? 'عادية'}

اقترح 3 ردود مناسبة:
1. رد رسمي/محترم
2. رد ودي/عادي
3. رد سريع/مختصر

الردود فقط، بدون ترقيم:
''';

      final response = await _aiService.chatWithGemini(message: prompt);
      
      // استخراج الردود
      final replies = response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .where((line) => !line.contains('رد ') && !line.startsWith('الردود'))
          .take(3)
          .toList();

      // إضافة ردود سريعة افتراضية إذا فشل AI
      if (replies.isEmpty) {
        return _getDefaultQuickReplies(context['intent'] as String);
      }

      return replies;
    } catch (e) {
      return _getDefaultQuickReplies('general');
    }
  }

  List<String> _getDefaultQuickReplies(String intent) {
    final quickReplies = {
      'question': ['نعم', 'لا', 'ربما'],
      'greeting': ['مرحباً', 'أهلاً وسهلاً', 'كيف حالك؟'],
      'gratitude': ['العفو', 'لا شكر على واجب', '❤️'],
      'invitation': ['أوافق', 'سأفكر في الأمر', 'شكراً على الدعوة'],
      'general': ['حسناً', 'شكراً', 'أفهم'],
    };

    return quickReplies[intent] ?? quickReplies['general']!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Context Analysis ───────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحليل سياق المحادثة والمشاعر
  Future<Map<String, dynamic>> _analyzeContext({
    required String lastMessage,
    List<String>? history,
    String? relationship,
  }) async {
    final analysis = <String, dynamic>{};

    // تحليل المشاعر
    analysis['emotion'] = await _detectEmotion(lastMessage);
    
    // تحليل النية
    analysis['intent'] = _detectIntent(lastMessage);
    
    // تحليل الإلحاح
    analysis['urgency'] = _detectUrgency(lastMessage);
    
    // تحليل اللغة
    analysis['language'] = _detectLanguage(lastMessage);
    
    // تحليل الموضوع
    analysis['topic'] = await _detectTopic(lastMessage, history);

    return analysis;
  }

  /// كشف المشاعر في النص
  Future<String> _detectEmotion(String text) async {
    // كلمات مفتاحية للمشاعر
    final emotions = {
      'happy': ['سعيد', 'فرح', 'مبسوط', 'رائع', '😊', '😄', '❤️', '🎉'],
      'sad': ['حزين', 'مكتئب', 'زعلان', '😢', '😭', '💔'],
      'angry': ['غاضب', 'زعلان', 'منزعج', '😡', '😠'],
      'excited': ['متحمس', 'متشوق', '🔥', '🚀'],
      'confused': ['محتار', 'مش فاهم', '🤔'],
      'grateful': ['شكرا', 'ممتن', 'مشكور', '🙏'],
    };

    final lowerText = text.toLowerCase();
    
    for (final entry in emotions.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }

    return 'neutral';
  }

  /// كشف النية في الرسالة
  String _detectIntent(String text) {
    final lowerText = text.toLowerCase();

    // أنماط النوايا
    if (RegExp(r'\?|كيف|ماذا|متى|أين|لماذا|هل').hasMatch(lowerText)) {
      return 'question';
    }
    if (RegExp(r'مرحبا|أهلا|السلام|صباح|مساء').hasMatch(lowerText)) {
      return 'greeting';
    }
    if (RegExp(r'شكرا|ممتن|مشكور').hasMatch(lowerText)) {
      return 'gratitude';
    }
    if (RegExp(r'دعوة|تعال|هيا|لنذهب').hasMatch(lowerText)) {
      return 'invitation';
    }
    if (RegExp(r'مع السلامة|وداعا|باي').hasMatch(lowerText)) {
      return 'farewell';
    }

    return 'statement';
  }

  /// كشف مدى إلحاح الرسالة
  String _detectUrgency(String text) {
    final lowerText = text.toLowerCase();
    
    final urgentKeywords = [
      'عاجل', 'مستعجل', 'ضروري', 'فوراً', 'حالاً', 'الآن',
      'urgent', '!!!', 'ASAP', '🚨', '⚠️'
    ];

    for (final keyword in urgentKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        return 'high';
      }
    }

    return 'normal';
  }

  /// كشف اللغة
  String _detectLanguage(String text) {
    // كشف العربية
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
      return 'ar';
    }
    // كشف الإنجليزية
    if (RegExp(r'^[a-zA-Z\s\d\p{P}]+$', unicode: true).hasMatch(text)) {
      return 'en';
    }
    return 'mixed';
  }

  /// كشف الموضوع
  Future<String> _detectTopic(String text, List<String>? history) async {
    final topics = {
      'work': ['عمل', 'مشروع', 'اجتماع', 'تقرير', 'مدير', 'meeting', 'work'],
      'family': ['عائلة', 'أم', 'أب', 'أخ', 'أخت', 'family', 'mom', 'dad'],
      'food': ['طعام', 'غداء', 'عشاء', 'مطعم', 'food', 'lunch', 'dinner'],
      'travel': ['سفر', 'رحلة', 'طيران', 'فندق', 'travel', 'trip', 'hotel'],
      'tech': ['تطبيق', 'برنامج', 'كمبيوتر', 'app', 'software', 'tech'],
      'sports': ['رياضة', 'مباراة', 'كرة', 'sports', 'game', 'match'],
    };

    final lowerText = text.toLowerCase();
    
    for (final entry in topics.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return 'general';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Auto Translation ───────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// ترجمة تلقائية ذكية
  Future<String> autoTranslate({
    required String text,
    required String targetLang,
    String? sourceLang,
  }) async {
    try {
      final prompt = '''
ترجم النص التالي إلى ${targetLang == 'ar' ? 'العربية' : 'الإنجليزية'}:

"$text"

الترجمة فقط بدون أي إضافات:
''';

      return await _aiService.chatWithGemini(message: prompt);
    } catch (e) {
      return text;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Message Categorization ─────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تصنيف المحادثات تلقائياً
  Future<String> categorizeChat({
    required String chatId,
    required List<MessageModel> recentMessages,
  }) async {
    if (recentMessages.isEmpty) return 'general';

    // تحليل المواضيع الأكثر تكراراً
    final topics = <String, int>{};
    
    for (final message in recentMessages.take(20)) {
      if (message.text != null) {
        final topic = await _detectTopic(message.text!, null);
        topics[topic] = (topics[topic] ?? 0) + 1;
      }
    }

    // العثور على الموضوع الأكثر تكراراً
    if (topics.isEmpty) return 'general';
    
    return topics.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Spam Detection ─────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// كشف السبام والرسائل المزعجة
  Future<Map<String, dynamic>> detectSpam(String text) async {
    final analysis = <String, dynamic>{
      'isSpam': false,
      'confidence': 0.0,
      'reason': '',
    };

    final lowerText = text.toLowerCase();
    double score = 0.0;

    // علامات السبام
    final spamIndicators = [
      {'keywords': ['اربح', 'مجاني', 'هدية', 'جائزة'], 'weight': 0.3},
      {'keywords': ['اضغط هنا', 'انقر', 'سجل الآن'], 'weight': 0.2},
      {'keywords': ['رابط', 'http', 'www', '.com'], 'weight': 0.1},
      {'keywords': ['!!!', '💰', '🎁', '💵'], 'weight': 0.15},
    ];

    for (final indicator in spamIndicators) {
      final keywords = indicator['keywords'] as List<String>;
      final weight = indicator['weight'] as double;
      
      for (final keyword in keywords) {
        if (lowerText.contains(keyword)) {
          score += weight;
          analysis['reason'] = 'يحتوي على كلمات مشبوهة';
          break;
        }
      }
    }

    // رسائل متكررة
    if (RegExp(r'(.)\1{5,}').hasMatch(text)) {
      score += 0.2;
      analysis['reason'] = 'حروف متكررة بشكل مشبوه';
    }

    // روابط كثيرة
    final urlCount = RegExp(r'http[s]?://').allMatches(text).length;
    if (urlCount > 2) {
      score += 0.3;
      analysis['reason'] = 'يحتوي على روابط كثيرة';
    }

    // CAPS كثيرة
    final capsRatio = text.split('').where((c) => c == c.toUpperCase() && c != c.toLowerCase()).length / text.length;
    if (capsRatio > 0.6) {
      score += 0.15;
      analysis['reason'] = 'أحرف كبيرة كثيرة';
    }

    analysis['confidence'] = score;
    analysis['isSpam'] = score > 0.5;

    return analysis;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Content Moderation ─────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// فحص المحتوى الضار
  Future<Map<String, dynamic>> moderateContent(String text) async {
    final result = <String, dynamic>{
      'isSafe': true,
      'violations': <String>[],
      'severity': 'none',
    };

    final lowerText = text.toLowerCase();

    // كلمات غير لائقة (مثال بسيط)
    final profanity = ['كلمة1', 'كلمة2']; // استبدل بقائمة حقيقية
    for (final word in profanity) {
      if (lowerText.contains(word)) {
        result['isSafe'] = false;
        result['violations'].add('لغة غير لائقة');
        result['severity'] = 'high';
        break;
      }
    }

    // تهديدات
    final threats = ['سأقتل', 'سأضرب', 'سأؤذي'];
    for (final threat in threats) {
      if (lowerText.contains(threat)) {
        result['isSafe'] = false;
        result['violations'].add('تهديد');
        result['severity'] = 'critical';
        break;
      }
    }

    // معلومات شخصية حساسة
    if (RegExp(r'\d{10,}').hasMatch(text)) {
      result['warnings'] = ['قد يحتوي على معلومات حساسة'];
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Smart Search ───────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// بحث ذكي في المحادثات
  Future<List<Map<String, dynamic>>> smartSearch({
    required String query,
    required String userId,
    int limit = 20,
  }) async {
    try {
      // البحث في Firestore
      final results = <Map<String, dynamic>>[];

      // البحث في الرسائل
      final chatsSnapshot = await _firestore
          .collection(AppConstants.colChats)
          .where('participantIds', arrayContains: userId)
          .get();

      for (final chatDoc in chatsSnapshot.docs) {
        final messagesSnapshot = await chatDoc.reference
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .get();

        for (final msgDoc in messagesSnapshot.docs) {
          final data = msgDoc.data();
          final text = data['text'] as String?;
          
          if (text != null && _matchesSearch(text, query)) {
            results.add({
              'type': 'message',
              'chatId': chatDoc.id,
              'messageId': msgDoc.id,
              'text': text,
              'createdAt': data['createdAt'],
              'relevance': _calculateRelevance(text, query),
            });
          }
        }
      }

      // ترتيب حسب الصلة
      results.sort((a, b) => (b['relevance'] as double).compareTo(a['relevance'] as double));

      return results.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  bool _matchesSearch(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    // بحث دقيق
    if (lowerText.contains(lowerQuery)) return true;
    
    // بحث بالكلمات
    final queryWords = lowerQuery.split(' ');
    return queryWords.every((word) => lowerText.contains(word));
  }

  double _calculateRelevance(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    double score = 0.0;
    
    // تطابق دقيق
    if (lowerText == lowerQuery) score += 1.0;
    
    // يبدأ بالكلمة
    if (lowerText.startsWith(lowerQuery)) score += 0.8;
    
    // يحتوي على الكلمة
    if (lowerText.contains(lowerQuery)) score += 0.5;
    
    // عدد الكلمات المتطابقة
    final queryWords = lowerQuery.split(' ');
    final matchedWords = queryWords.where((word) => lowerText.contains(word)).length;
    score += (matchedWords / queryWords.length) * 0.3;
    
    return score;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Conversation Insights ──────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحليلات المحادثة
  Future<Map<String, dynamic>> getConversationInsights({
    required String chatId,
    required List<MessageModel> messages,
  }) async {
    if (messages.isEmpty) {
      return {
        'totalMessages': 0,
        'averageResponseTime': 0,
        'mostActiveTime': 'N/A',
        'emotionTrend': 'neutral',
        'topics': [],
      };
    }

    // إحصائيات أساسية
    final insights = <String, dynamic>{
      'totalMessages': messages.length,
    };

    // متوسط وقت الرد
    final responseTimes = <int>[];
    for (int i = 1; i < messages.length; i++) {
      if (messages[i].senderId != messages[i - 1].senderId) {
        final diff = messages[i].createdAt!.difference(messages[i - 1].createdAt!);
        responseTimes.add(diff.inSeconds);
      }
    }
    
    if (responseTimes.isNotEmpty) {
      insights['averageResponseTime'] = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
    }

    // أكثر وقت نشاطاً
    final hourCounts = <int, int>{};
    for (final msg in messages) {
      if (msg.createdAt != null) {
        final hour = msg.createdAt!.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
    }
    
    if (hourCounts.isNotEmpty) {
      final mostActiveHour = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      insights['mostActiveTime'] = '${mostActiveHour}:00';
    }

    // اتجاه المشاعر
    final emotions = <String>[];
    for (final msg in messages.take(20)) {
      if (msg.text != null) {
        emotions.add(await _detectEmotion(msg.text!));
      }
    }
    
    if (emotions.isNotEmpty) {
      // العثور على المشاعر الأكثر شيوعاً
      final emotionCounts = <String, int>{};
      for (final emotion in emotions) {
        emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      }
      insights['emotionTrend'] = emotionCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    // المواضيع
    final topics = <String>[];
    for (final msg in messages.take(50)) {
      if (msg.text != null) {
        final topic = await _detectTopic(msg.text!, null);
        if (!topics.contains(topic)) {
          topics.add(topic);
        }
      }
    }
    insights['topics'] = topics.take(5).toList();

    return insights;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Auto-Complete ──────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// اقتراحات الإكمال التلقائي
  Future<List<String>> getAutoCompleteSuggestions({
    required String partialText,
    required String userId,
  }) async {
    if (partialText.length < 2) return [];

    try {
      // جمع الرسائل السابقة للمستخدم
      final userMessages = await _getUserRecentMessages(userId, 100);
      
      // العثور على الكلمات المطابقة
      final suggestions = <String>{};
      final lowerPartial = partialText.toLowerCase();
      
      for (final message in userMessages) {
        if (message.toLowerCase().startsWith(lowerPartial)) {
          suggestions.add(message);
        }
        
        // كلمات تبدأ بالنص الجزئي
        final words = message.split(' ');
        for (final word in words) {
          if (word.toLowerCase().startsWith(lowerPartial) && word.length > partialText.length) {
            suggestions.add(word);
          }
        }
      }

      return suggestions.take(5).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _getUserRecentMessages(String userId, int limit) async {
    try {
      final chatsSnapshot = await _firestore
          .collection(AppConstants.colChats)
          .where('participantIds', arrayContains: userId)
          .limit(10)
          .get();

      final messages = <String>[];
      
      for (final chatDoc in chatsSnapshot.docs) {
        final messagesSnapshot = await chatDoc.reference
            .collection('messages')
            .where('senderId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();

        for (final msgDoc in messagesSnapshot.docs) {
          final text = msgDoc.data()['text'] as String?;
          if (text != null && text.isNotEmpty) {
            messages.add(text);
          }
        }
      }

      return messages;
    } catch (e) {
      return [];
    }
  }
}
