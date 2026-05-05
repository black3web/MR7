import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../config/constants.dart';
import 'smart_chat_engine.dart';

/// نظام الأمان والخصوصية الذكي
/// يحمي المستخدم ويكتشف التهديدات تلقائياً
class SmartSecurityService {
  static final SmartSecurityService _instance = SmartSecurityService._internal();
  factory SmartSecurityService() => _instance;
  SmartSecurityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SmartChatEngine _smartEngine = SmartChatEngine();

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Suspicious Activity Detection ──────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// كشف النشاط المشبوه
  Future<Map<String, dynamic>> detectSuspiciousActivity({
    required String userId,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    final result = <String, dynamic>{
      'isSuspicious': false,
      'risk': 'low',
      'reasons': <String>[],
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. معدل النشاط غير الطبيعي
      final actionKey = 'activity_${userId}_$action';
      final count = prefs.getInt(actionKey) ?? 0;
      final lastReset = prefs.getString('${actionKey}_reset');
      
      final now = DateTime.now();
      DateTime resetTime;
      
      if (lastReset != null) {
        resetTime = DateTime.parse(lastReset);
      } else {
        resetTime = now;
        await prefs.setString('${actionKey}_reset', now.toIso8601String());
      }
      
      // إعادة تعيين كل ساعة
      if (now.difference(resetTime).inHours >= 1) {
        await prefs.setInt(actionKey, 1);
        await prefs.setString('${actionKey}_reset', now.toIso8601String());
      } else {
        await prefs.setInt(actionKey, count + 1);
        
        // معدل غير طبيعي
        if (count > 100) { // أكثر من 100 إجراء في الساعة
          result['isSuspicious'] = true;
          result['risk'] = 'high';
          result['reasons'].add('معدل نشاط غير طبيعي');
        }
      }
      
      // 2. تسجيل دخول من أجهزة متعددة
      if (action == 'login') {
        final deviceId = metadata?['deviceId'] as String?;
        if (deviceId != null) {
          final devices = prefs.getStringList('devices_$userId') ?? [];
          
          if (!devices.contains(deviceId)) {
            // جهاز جديد
            if (devices.length >= 3) {
              result['isSuspicious'] = true;
              result['risk'] = 'medium';
              result['reasons'].add('تسجيل دخول من جهاز جديد');
            }
            
            devices.add(deviceId);
            await prefs.setStringList('devices_$userId', devices);
          }
        }
      }
      
      // 3. تغييرات أمنية متكررة
      if (action == 'security_change') {
        final changeCountKey = 'security_changes_$userId';
        final changeCount = prefs.getInt(changeCountKey) ?? 0;
        
        if (changeCount > 5) { // أكثر من 5 تغييرات أمنية في اليوم
          result['isSuspicious'] = true;
          result['risk'] = 'high';
          result['reasons'].add('تغييرات أمنية متكررة');
        }
        
        await prefs.setInt(changeCountKey, changeCount + 1);
      }
      
      // حفظ السجل
      if (result['isSuspicious'] == true) {
        await _logSuspiciousActivity(userId, action, result);
      }
      
    } catch (e) {
      print('Error detecting suspicious activity: $e');
    }
    
    return result;
  }

  Future<void> _logSuspiciousActivity(
    String userId,
    String action,
    Map<String, dynamic> details,
  ) async {
    try {
      await _firestore.collection(AppConstants.colSecurityLogs).add({
        'userId': userId,
        'action': action,
        'risk': details['risk'],
        'reasons': details['reasons'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging suspicious activity: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Phishing Detection ─────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// كشف محاولات الاحتيال والتصيد
  Future<Map<String, dynamic>> detectPhishing(String message) async {
    final result = <String, dynamic>{
      'isPhishing': false,
      'confidence': 0.0,
      'indicators': <String>[],
    };

    final lowerMessage = message.toLowerCase();
    double score = 0.0;

    // 1. روابط مشبوهة
    final urlPattern = RegExp(r'https?://[^\s]+');
    final urls = urlPattern.allMatches(message);
    
    for (final match in urls) {
      final url = match.group(0)!.toLowerCase();
      
      // نطاقات مشبوهة
      if (url.contains('.tk') || url.contains('.ml') || 
          url.contains('bit.ly') || url.contains('tinyurl')) {
        score += 0.3;
        result['indicators'].add('رابط مختصر أو نطاق مشبوه');
      }
      
      // تشابه مع مواقع مشهورة
      if (url.contains('faceb00k') || url.contains('g00gle') || 
          url.contains('whatsap')) {
        score += 0.4;
        result['indicators'].add('محاكاة موقع مشهور');
      }
    }

    // 2. طلبات معلومات حساسة
    final sensitiveKeywords = [
      'كلمة المرور', 'password', 'رقم البطاقة', 'card number',
      'cvv', 'رقم سري', 'pin', 'حسابك', 'account',
    ];
    
    for (final keyword in sensitiveKeywords) {
      if (lowerMessage.contains(keyword)) {
        score += 0.2;
        result['indicators'].add('طلب معلومات حساسة');
        break;
      }
    }

    // 3. عبارات احتيال شائعة
    final phishingPhrases = [
      'ربحت', 'you won', 'جائزة', 'prize',
      'انقر هنا', 'click here', 'اضغط الآن',
      'حسابك معلق', 'account suspended',
      'تحديث', 'update', 'تأكيد هويتك', 'verify',
    ];
    
    int phishingCount = 0;
    for (final phrase in phishingPhrases) {
      if (lowerMessage.contains(phrase)) {
        phishingCount++;
      }
    }
    
    if (phishingCount >= 2) {
      score += 0.3;
      result['indicators'].add('عبارات احتيال متعددة');
    }

    // 4. إلحاح غير مبرر
    if (lowerMessage.contains('فوراً') || lowerMessage.contains('الآن') ||
        lowerMessage.contains('urgent') || lowerMessage.contains('immediate')) {
      score += 0.15;
      result['indicators'].add('إلحاح غير مبرر');
    }

    // 5. أخطاء إملائية كثيرة (علامة على رسالة آلية)
    if (_hasExcessiveTypos(message)) {
      score += 0.1;
      result['indicators'].add('أخطاء إملائية كثيرة');
    }

    result['confidence'] = score;
    result['isPhishing'] = score > 0.5;

    return result;
  }

  bool _hasExcessiveTypos(String text) {
    // منطق بسيط - يمكن تحسينه
    final repeatedChars = RegExp(r'(.)\1{3,}').allMatches(text);
    return repeatedChars.length > 2;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Data Privacy ───────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// كشف تسريب معلومات حساسة
  Future<Map<String, dynamic>> detectSensitiveData(String message) async {
    final result = <String, dynamic>{
      'hasSensitiveData': false,
      'types': <String>[],
      'warnings': <String>[],
    };

    // 1. أرقام بطاقات الائتمان
    if (RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b').hasMatch(message)) {
      result['hasSensitiveData'] = true;
      result['types'].add('credit_card');
      result['warnings'].add('⚠️ رقم بطاقة ائتمان محتمل');
    }

    // 2. أرقام الضمان الاجتماعي / الهوية
    if (RegExp(r'\b\d{10,14}\b').hasMatch(message)) {
      result['hasSensitiveData'] = true;
      result['types'].add('id_number');
      result['warnings'].add('⚠️ رقم هوية محتمل');
    }

    // 3. كلمات مرور
    if (RegExp(r'password|كلمة المرور|رمز|code', caseSensitive: false).hasMatch(message)) {
      if (RegExp(r'[:=]\s*\S+').hasMatch(message)) {
        result['hasSensitiveData'] = true;
        result['types'].add('password');
        result['warnings'].add('⚠️ كلمة مرور محتملة');
      }
    }

    // 4. عناوين دقيقة
    if (RegExp(r'\d+\s+[A-Za-z\u0600-\u06FF]+\s+(street|st|شارع)', caseSensitive: false).hasMatch(message)) {
      result['hasSensitiveData'] = true;
      result['types'].add('address');
      result['warnings'].add('⚠️ عنوان دقيق');
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Screenshot Detection ───────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// إشعار عند أخذ لقطة شاشة (للمحادثات السرية)
  Future<void> notifyScreenshot({
    required String chatId,
    required String userId,
    required String otherUserId,
  }) async {
    try {
      // التحقق من تفعيل الحماية
      final prefs = await SharedPreferences.getInstance();
      final secretMode = prefs.getBool('secret_mode_$chatId') ?? false;
      
      if (secretMode) {
        // إرسال إشعار للطرف الآخر
        await _firestore.collection(AppConstants.colNotifs).add({
          'toUserId': otherUserId,
          'fromUserId': userId,
          'type': 'screenshot',
          'title': 'تنبيه أمني',
          'body': 'قام أحد الأطراف بأخذ لقطة شاشة للمحادثة',
          'chatId': chatId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // تسجيل الحدث
        await _firestore.collection(AppConstants.colSecurityLogs).add({
          'type': 'screenshot',
          'chatId': chatId,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error notifying screenshot: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Message Encryption ─────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تشفير الرسالة (تشفير بسيط - للتوضيح)
  String encryptMessage(String message, String key) {
    final bytes = utf8.encode(message + key);
    final hash = sha256.convert(bytes);
    
    // تشفير بسيط XOR
    final encrypted = <int>[];
    final keyBytes = hash.bytes;
    
    for (int i = 0; i < message.length; i++) {
      encrypted.add(message.codeUnitAt(i) ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64.encode(encrypted);
  }

  /// فك تشفير الرسالة
  String decryptMessage(String encryptedMessage, String key) {
    try {
      final bytes = utf8.encode('dummy' + key);
      final hash = sha256.convert(bytes);
      
      final encrypted = base64.decode(encryptedMessage);
      final keyBytes = hash.bytes;
      
      final decrypted = <int>[];
      for (int i = 0; i < encrypted.length; i++) {
        decrypted.add(encrypted[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return String.fromCharCodes(decrypted);
    } catch (e) {
      return encryptedMessage; // فشل الفك
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Account Security ───────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// فحص قوة كلمة المرور
  Map<String, dynamic> checkPasswordStrength(String password) {
    final result = <String, dynamic>{
      'strength': 'weak',
      'score': 0,
      'suggestions': <String>[],
    };

    int score = 0;

    // الطول
    if (password.length >= 8) score += 20;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;

    // أحرف كبيرة
    if (RegExp(r'[A-Z]').hasMatch(password)) {
      score += 15;
    } else {
      result['suggestions'].add('أضف أحرف كبيرة');
    }

    // أحرف صغيرة
    if (RegExp(r'[a-z]').hasMatch(password)) {
      score += 15;
    } else {
      result['suggestions'].add('أضف أحرف صغيرة');
    }

    // أرقام
    if (RegExp(r'\d').hasMatch(password)) {
      score += 15;
    } else {
      result['suggestions'].add('أضف أرقام');
    }

    // رموز خاصة
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score += 15;
    } else {
      result['suggestions'].add('أضف رموز خاصة');
    }

    // تنوع الأحرف
    if (password.split('').toSet().length >= password.length * 0.6) {
      score += 10;
    }

    result['score'] = score;

    if (score >= 80) result['strength'] = 'very_strong';
    else if (score >= 60) result['strength'] = 'strong';
    else if (score >= 40) result['strength'] = 'medium';
    else result['strength'] = 'weak';

    return result;
  }

  /// التحقق من تسريب كلمة المرور
  Future<bool> checkPasswordBreach(String password) async {
    // في التطبيق الحقيقي، استخدم Have I Been Pwned API
    // هنا مثال بسيط
    
    final commonPasswords = [
      '123456', 'password', '12345678', 'qwerty', 'abc123',
      '111111', 'password1', '123123', '1234567890',
    ];

    return commonPasswords.contains(password.toLowerCase());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Two-Factor Authentication ──────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// توليد رمز 2FA
  String generate2FACode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = (random % 900000 + 100000).toString();
    return code;
  }

  /// التحقق من رمز 2FA
  Future<bool> verify2FACode({
    required String userId,
    required String code,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString('2fa_code_$userId');
      final expiry = prefs.getString('2fa_expiry_$userId');
      
      if (savedCode == null || expiry == null) return false;
      
      final expiryTime = DateTime.parse(expiry);
      if (DateTime.now().isAfter(expiryTime)) {
        // انتهى الرمز
        return false;
      }
      
      return savedCode == code;
    } catch (e) {
      return false;
    }
  }

  /// حفظ رمز 2FA
  Future<void> save2FACode({
    required String userId,
    required String code,
    int validMinutes = 5,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = DateTime.now().add(Duration(minutes: validMinutes));
    
    await prefs.setString('2fa_code_$userId', code);
    await prefs.setString('2fa_expiry_$userId', expiry.toIso8601String());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Privacy Reports ────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تقرير الخصوصية للمستخدم
  Future<Map<String, dynamic>> generatePrivacyReport(String userId) async {
    final report = <String, dynamic>{
      'userId': userId,
      'generatedAt': DateTime.now().toIso8601String(),
      'dataCollected': <String, dynamic>{},
      'permissions': <String, bool>{},
      'securityEvents': <Map<String, dynamic>>[],
    };

    try {
      // 1. البيانات المجمعة
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      final userKeys = allKeys.where((k) => k.contains(userId));
      report['dataCollected'] = {
        'localStorageItems': userKeys.length,
        'behaviourTracking': userKeys.where((k) => k.contains('behavior')).length,
        'preferences': userKeys.where((k) => k.contains('settings')).length,
      };

      // 2. الأذونات
      report['permissions'] = {
        'camera': true, // يجب التحقق فعلياً
        'microphone': true,
        'storage': true,
        'location': false,
        'contacts': false,
      };

      // 3. أحداث الأمان
      final securityLogs = await _firestore
          .collection(AppConstants.colSecurityLogs)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      report['securityEvents'] = securityLogs.docs.map((doc) => doc.data()).toList();

    } catch (e) {
      print('Error generating privacy report: $e');
    }

    return report;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Safe Mode ──────────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تفعيل الوضع الآمن (تحذيرات إضافية)
  Future<void> enableSafeMode(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('safe_mode_$userId', true);
  }

  /// التحقق من الوضع الآمن
  Future<bool> isSafeModeEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('safe_mode_$userId') ?? false;
  }
}
