import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/constants.dart';
import '../models/message_model.dart';

/// نظام التوصيات الذكية وتعلم السلوك
/// يتعلم من تصرفات المستخدم ويقدم توصيات مخصصة
class SmartRecommendationEngine {
  static final SmartRecommendationEngine _instance = SmartRecommendationEngine._internal();
  factory SmartRecommendationEngine() => _instance;
  SmartRecommendationEngine._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // ── User Behavior Learning ─────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تتبع سلوك المستخدم
  Future<void> trackUserBehavior({
    required String userId,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'behavior_${userId}_$action';
      
      // زيادة العداد
      final count = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, count + 1);
      
      // حفظ آخر استخدام
      final lastUsedKey = '${key}_last';
      await prefs.setString(lastUsedKey, DateTime.now().toIso8601String());
      
      // حفظ البيانات الإضافية
      if (metadata != null) {
        final metaKey = '${key}_meta';
        final existingMeta = prefs.getString(metaKey);
        final metaList = existingMeta != null 
            ? List<Map<String, dynamic>>.from(jsonDecode(existingMeta))
            : <Map<String, dynamic>>[];
        
        metaList.add({
          ...metadata,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        // الاحتفاظ بآخر 100 فقط
        if (metaList.length > 100) {
          metaList.removeRange(0, metaList.length - 100);
        }
        
        await prefs.setString(metaKey, jsonEncode(metaList));
      }

      // حفظ في السحابة كل 10 إجراءات
      if (count % 10 == 0) {
        await _syncBehaviorToCloud(userId);
      }
    } catch (e) {
      print('Error tracking behavior: $e');
    }
  }

  Future<void> _syncBehaviorToCloud(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final behaviorData = <String, dynamic>{};
      
      for (final key in allKeys) {
        if (key.startsWith('behavior_$userId')) {
          final value = prefs.get(key);
          if (value != null) {
            behaviorData[key] = value;
          }
        }
      }
      
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(userId)
          .set({
        'behaviorData': behaviorData,
        'lastBehaviorSync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error syncing behavior: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Smart Contact Suggestions ──────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// اقتراح جهات اتصال بناءً على السلوك
  Future<List<Map<String, dynamic>>> suggestContacts({
    required String userId,
    int limit = 5,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final suggestions = <Map<String, dynamic>>[];
      
      // تحليل جهات الاتصال الأكثر تفاعلاً
      final chatsSnapshot = await _firestore
          .collection(AppConstants.colChats)
          .where('participantIds', arrayContains: userId)
          .get();

      final contactScores = <String, double>{};
      
      for (final chatDoc in chatsSnapshot.docs) {
        final data = chatDoc.data();
        final participants = List<String>.from(data['participantIds'] ?? []);
        final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');
        
        if (otherUserId.isEmpty) continue;
        
        // حساب النقاط بناءً على:
        double score = 0.0;
        
        // 1. عدد الرسائل
        final messagesCount = await chatDoc.reference.collection('messages').count().get();
        score += (messagesCount.count ?? 0) * 0.01;
        
        // 2. آخر تفاعل
        final lastMessage = data['lastMessage'] as Map<String, dynamic>?;
        if (lastMessage != null) {
          final lastMessageTime = (lastMessage['timestamp'] as Timestamp?)?.toDate();
          if (lastMessageTime != null) {
            final daysSince = DateTime.now().difference(lastMessageTime).inDays;
            score += (30 - daysSince).clamp(0, 30) * 0.1; // كلما أحدث، أعلى
          }
        }
        
        // 3. تكرار التفاعل
        final interactionKey = 'behavior_${userId}_open_chat_$otherUserId';
        final interactionCount = prefs.getInt(interactionKey) ?? 0;
        score += interactionCount * 0.5;
        
        // 4. الوقت المناسب (نفس الوقت عادة)
        final currentHour = DateTime.now().hour;
        final preferredTimeKey = 'behavior_${userId}_chat_time_$otherUserId';
        final preferredTime = prefs.getInt(preferredTimeKey) ?? -1;
        if ((preferredTime - currentHour).abs() < 2) {
          score += 5.0;
        }
        
        contactScores[otherUserId] = score;
      }
      
      // ترتيب حسب النقاط
      final sortedContacts = contactScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // جلب بيانات المستخدمين
      for (final entry in sortedContacts.take(limit)) {
        final userDoc = await _firestore
            .collection(AppConstants.colUsers)
            .doc(entry.key)
            .get();
        
        if (userDoc.exists) {
          suggestions.add({
            ...userDoc.data()!,
            'userId': entry.key,
            'score': entry.value,
            'reason': _getSuggestionReason(entry.value),
          });
        }
      }
      
      return suggestions;
    } catch (e) {
      return [];
    }
  }

  String _getSuggestionReason(double score) {
    if (score > 50) return 'تتحدث معه كثيراً';
    if (score > 30) return 'صديق نشط';
    if (score > 15) return 'الوقت المعتاد للمحادثة';
    return 'قد يهمك';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Smart Reply Time Prediction ────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// توقع أفضل وقت للرد
  Future<Map<String, dynamic>> predictBestReplyTime({
    required String userId,
    required String recipientId,
  }) async {
    try {
      // جمع أوقات الردود السابقة
      final chatQuery = await _firestore
          .collection(AppConstants.colChats)
          .where('participantIds', arrayContains: userId)
          .get();

      final replyTimes = <int, int>{}; // hour -> count
      
      for (final chatDoc in chatQuery.docs) {
        final data = chatDoc.data();
        final participants = List<String>.from(data['participantIds'] ?? []);
        
        if (participants.contains(recipientId)) {
          final messages = await chatDoc.reference
              .collection('messages')
              .where('senderId', isEqualTo: recipientId)
              .orderBy('createdAt', descending: true)
              .limit(100)
              .get();
          
          for (final msgDoc in messages.docs) {
            final timestamp = (msgDoc.data()['createdAt'] as Timestamp?)?.toDate();
            if (timestamp != null) {
              final hour = timestamp.hour;
              replyTimes[hour] = (replyTimes[hour] ?? 0) + 1;
            }
          }
        }
      }
      
      if (replyTimes.isEmpty) {
        return {
          'bestHour': 12,
          'confidence': 'low',
          'message': 'لا توجد بيانات كافية',
        };
      }
      
      // العثور على أكثر ساعة نشاطاً
      final bestHour = replyTimes.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      final totalReplies = replyTimes.values.reduce((a, b) => a + b);
      final confidence = (replyTimes[bestHour]! / totalReplies * 100).round();
      
      return {
        'bestHour': bestHour,
        'confidence': confidence > 60 ? 'high' : (confidence > 30 ? 'medium' : 'low'),
        'message': 'عادة يرد بين ${bestHour}:00 - ${(bestHour + 1) % 24}:00',
        'confidencePercent': confidence,
      };
    } catch (e) {
      return {
        'bestHour': 12,
        'confidence': 'low',
        'message': 'غير متاح',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Smart Notification Timing ──────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحديد ما إذا كان يجب إرسال إشعار الآن
  Future<bool> shouldSendNotificationNow({
    required String userId,
    required String messageType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentHour = DateTime.now().hour;
      
      // ساعات النوم المحتملة (لا إشعارات)
      if (currentHour >= 0 && currentHour < 7) {
        final allowNightKey = 'settings_${userId}_allow_night_notifications';
        if (!(prefs.getBool(allowNightKey) ?? false)) {
          return false;
        }
      }
      
      // فترات عدم الإزعاج
      final dndKey = 'settings_${userId}_dnd_active';
      if (prefs.getBool(dndKey) ?? false) {
        return false;
      }
      
      // تحليل نمط استخدام المستخدم
      final activityKey = 'behavior_${userId}_app_activity';
      final activityMeta = prefs.getString(activityKey);
      
      if (activityMeta != null) {
        final activities = List<Map<String, dynamic>>.from(jsonDecode(activityMeta));
        
        // حساب متوسط الاستخدام في هذه الساعة
        final hourActivity = activities.where((a) {
          final time = DateTime.parse(a['timestamp'] as String);
          return time.hour == currentHour;
        }).length;
        
        // إذا كان المستخدم نادراً ما يستخدم التطبيق في هذا الوقت
        if (hourActivity == 0 && activities.length > 50) {
          return false; // قد لا يراها
        }
      }
      
      return true;
    } catch (e) {
      return true; // افتراضياً نرسل
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Content Recommendations ───────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// اقتراح محتوى بناءً على الاهتمامات
  Future<List<Map<String, dynamic>>> recommendContent({
    required String userId,
    String contentType = 'all', // stories, groups, channels
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recommendations = <Map<String, dynamic>>[];
      
      // تحليل اهتمامات المستخدم من رسائله
      final interests = await _extractUserInterests(userId);
      
      // اقتراح مجموعات
      if (contentType == 'all' || contentType == 'groups') {
        final groups = await _recommendGroups(userId, interests);
        recommendations.addAll(groups);
      }
      
      // اقتراح قصص
      if (contentType == 'all' || contentType == 'stories') {
        final stories = await _recommendStories(userId, interests);
        recommendations.addAll(stories);
      }
      
      return recommendations;
    } catch (e) {
      return [];
    }
  }

  Future<Set<String>> _extractUserInterests(String userId) async {
    final interests = <String>{};
    
    try {
      // تحليل الرسائل الأخيرة
      final chatsSnapshot = await _firestore
          .collection(AppConstants.colChats)
          .where('participantIds', arrayContains: userId)
          .limit(10)
          .get();
      
      for (final chatDoc in chatsSnapshot.docs) {
        final messages = await chatDoc.reference
            .collection('messages')
            .where('senderId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get();
        
        for (final msgDoc in messages.docs) {
          final text = msgDoc.data()['text'] as String?;
          if (text != null) {
            // استخراج كلمات مفتاحية
            final keywords = _extractKeywords(text);
            interests.addAll(keywords);
          }
        }
      }
    } catch (e) {
      print('Error extracting interests: $e');
    }
    
    return interests;
  }

  Set<String> _extractKeywords(String text) {
    final keywords = <String>{};
    final lowerText = text.toLowerCase();
    
    // قوائم الكلمات المفتاحية حسب الموضوع
    final topicKeywords = {
      'tech': ['تطبيق', 'برمجة', 'كود', 'app', 'code', 'software'],
      'sports': ['كرة', 'مباراة', 'football', 'game', 'match'],
      'food': ['طعام', 'مطعم', 'food', 'restaurant'],
      'travel': ['سفر', 'رحلة', 'travel', 'trip'],
      'music': ['أغنية', 'موسيقى', 'music', 'song'],
      'movies': ['فيلم', 'مسلسل', 'movie', 'series'],
    };
    
    for (final entry in topicKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          keywords.add(entry.key);
        }
      }
    }
    
    return keywords;
  }

  Future<List<Map<String, dynamic>>> _recommendGroups(
    String userId,
    Set<String> interests,
  ) async {
    final recommendations = <Map<String, dynamic>>[];
    
    try {
      // البحث عن مجموعات مطابقة
      final groupsSnapshot = await _firestore
          .collection(AppConstants.colGroups)
          .where('isPublic', isEqualTo: true)
          .limit(50)
          .get();
      
      for (final groupDoc in groupsSnapshot.docs) {
        final data = groupDoc.data();
        final members = List<String>.from(data['members'] ?? []);
        
        // تخطي إذا كان المستخدم عضو بالفعل
        if (members.contains(userId)) continue;
        
        // حساب التطابق
        double matchScore = 0.0;
        final groupName = (data['name'] as String? ?? '').toLowerCase();
        final groupDesc = (data['description'] as String? ?? '').toLowerCase();
        
        for (final interest in interests) {
          if (groupName.contains(interest) || groupDesc.contains(interest)) {
            matchScore += 1.0;
          }
        }
        
        if (matchScore > 0) {
          recommendations.add({
            'type': 'group',
            'id': groupDoc.id,
            'data': data,
            'matchScore': matchScore,
            'reason': 'يطابق اهتماماتك',
          });
        }
      }
    } catch (e) {
      print('Error recommending groups: $e');
    }
    
    return recommendations;
  }

  Future<List<Map<String, dynamic>>> _recommendStories(
    String userId,
    Set<String> interests,
  ) async {
    final recommendations = <Map<String, dynamic>>[];
    
    try {
      // جلب قصص من الأصدقاء
      final contactsScores = await suggestContacts(userId: userId, limit: 10);
      final contactIds = contactsScores.map((c) => c['userId'] as String).toList();
      
      // جلب قصصهم
      final now = DateTime.now();
      final expiryThreshold = now.subtract(const Duration(hours: 48));
      
      final storiesSnapshot = await _firestore
          .collection(AppConstants.colStories)
          .where('userId', whereIn: contactIds.take(10).toList())
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(expiryThreshold))
          .orderBy('expiresAt', descending: true)
          .limit(20)
          .get();
      
      for (final storyDoc in storiesSnapshot.docs) {
        recommendations.add({
          'type': 'story',
          'id': storyDoc.id,
          'data': storyDoc.data(),
          'reason': 'من أصدقائك المقربين',
        });
      }
    } catch (e) {
      print('Error recommending stories: $e');
    }
    
    return recommendations;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Predictive Text ────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// التنبؤ بالكلمة التالية
  Future<List<String>> predictNextWord({
    required String userId,
    required String currentText,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final predictions = <String>[];
      
      // جمع الرسائل السابقة
      final messageHistoryKey = 'behavior_${userId}_message_history';
      final historyJson = prefs.getString(messageHistoryKey);
      
      if (historyJson != null) {
        final history = List<String>.from(jsonDecode(historyJson));
        
        // البحث عن أنماط
        final words = currentText.split(' ');
        if (words.isNotEmpty) {
          final lastWord = words.last.toLowerCase();
          
          for (final message in history) {
            final messageWords = message.split(' ');
            for (int i = 0; i < messageWords.length - 1; i++) {
              if (messageWords[i].toLowerCase() == lastWord) {
                final nextWord = messageWords[i + 1];
                if (!predictions.contains(nextWord) && nextWord.length > 1) {
                  predictions.add(nextWord);
                }
              }
            }
          }
        }
      }
      
      return predictions.take(3).toList();
    } catch (e) {
      return [];
    }
  }

  /// حفظ الرسالة في السجل للتعلم
  Future<void> saveMessageForLearning({
    required String userId,
    required String message,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'behavior_${userId}_message_history';
      
      final historyJson = prefs.getString(key);
      final history = historyJson != null 
          ? List<String>.from(jsonDecode(historyJson))
          : <String>[];
      
      history.add(message);
      
      // الاحتفاظ بآخر 200 رسالة فقط
      if (history.length > 200) {
        history.removeRange(0, history.length - 200);
      }
      
      await prefs.setString(key, jsonEncode(history));
    } catch (e) {
      print('Error saving message: $e');
    }
  }
}
