import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

/// خدمة تخصيص التطبيق الكامل - خلفيات، ألوان، ثيمات
class CustomizationService {
  static final CustomizationService _instance = CustomizationService._internal();
  factory CustomizationService() => _instance;
  CustomizationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Chat Background Management ─────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// حفظ خلفية مخصصة من صورة
  Future<void> setCustomBackground({
    required String userId,
    required String chatId,
    required File imageFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_bg_${userId}_$chatId';
    
    // حفظ مسار الصورة محلياً
    await prefs.setString(key, imageFile.path);
    
    // حفظ في Firestore للمزامنة عبر الأجهزة (اختياري)
    try {
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection('chat_settings')
          .doc(chatId)
          .set({
        'customBackground': imageFile.path,
        'backgroundType': 'image',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// تعيين خلفية من القوالب الجاهزة
  Future<void> setPresetBackground({
    required String userId,
    required String chatId,
    required String presetId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_bg_${userId}_$chatId';
    
    await prefs.setString(key, 'preset:$presetId');
    
    try {
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection('chat_settings')
          .doc(chatId)
          .set({
        'presetBackground': presetId,
        'backgroundType': 'preset',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// الحصول على خلفية المحادثة
  Future<Map<String, dynamic>?> getChatBackground({
    required String userId,
    required String chatId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_bg_${userId}_$chatId';
    final value = prefs.getString(key);
    
    if (value == null) return null;
    
    if (value.startsWith('preset:')) {
      final presetId = value.substring(7);
      final preset = AppConstants.chatBackgrounds.firstWhere(
        (bg) => bg['id'] == presetId,
        orElse: () => AppConstants.chatBackgrounds[0],
      );
      return {'type': 'preset', 'data': preset};
    } else {
      return {'type': 'image', 'data': value};
    }
  }

  /// حذف الخلفية المخصصة
  Future<void> clearChatBackground({
    required String userId,
    required String chatId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_bg_${userId}_$chatId';
    await prefs.remove(key);
    
    try {
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection('chat_settings')
          .doc(chatId)
          .delete();
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Theme & Colors ─────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تعيين لون التطبيق الأساسي
  Future<void> setAccentColor({
    required String userId,
    required Color color,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_color_$userId', color.value);
    
    try {
      await _firestore.collection(AppConstants.colUsers).doc(userId).update({
        'settings.accentColor': color.value,
        'settings.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// الحصول على لون التطبيق
  Future<Color> getAccentColor(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('accent_color_$userId');
    return colorValue != null ? Color(colorValue) : const Color(0xFFB22222);
  }

  /// تعيين وضع الثيم (فاتح/داكن/تلقائي)
  Future<void> setThemeMode({
    required String userId,
    required String mode, // 'light', 'dark', 'auto'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode_$userId', mode);
    
    try {
      await _firestore.collection(AppConstants.colUsers).doc(userId).update({
        'settings.themeMode': mode,
        'settings.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// الحصول على وضع الثيم
  Future<String> getThemeMode(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme_mode_$userId') ?? 'dark';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Bubble Style ───────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تعيين نمط فقاعات الرسائل
  Future<void> setBubbleStyle({
    required String userId,
    required String style, // 'modern', 'classic', 'minimal', 'glass'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bubble_style_$userId', style);
    
    try {
      await _firestore.collection(AppConstants.colUsers).doc(userId).update({
        'settings.bubbleStyle': style,
        'settings.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// الحصول على نمط الفقاعات
  Future<String> getBubbleStyle(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('bubble_style_$userId') ?? 'glass';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Font Settings ──────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تعيين حجم الخط
  Future<void> setFontScale({
    required String userId,
    required double scale, // 0.8 - 1.5
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_scale_$userId', scale);
    
    try {
      await _firestore.collection(AppConstants.colUsers).doc(userId).update({
        'settings.fontScale': scale,
        'settings.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// الحصول على حجم الخط
  Future<double> getFontScale(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('font_scale_$userId') ?? 1.0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Notification Settings ──────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تعيين إعدادات الإشعارات للمحادثة
  Future<void> setChatNotificationSettings({
    required String userId,
    required String chatId,
    required bool enabled,
    String? customSound,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled_${userId}_$chatId', enabled);
    if (customSound != null) {
      await prefs.setString('notif_sound_${userId}_$chatId', customSound);
    }
    
    try {
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection('chat_settings')
          .doc(chatId)
          .set({
        'notificationsEnabled': enabled,
        'customSound': customSound,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// الحصول على إعدادات إشعارات المحادثة
  Future<Map<String, dynamic>> getChatNotificationSettings({
    required String userId,
    required String chatId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('notif_enabled_${userId}_$chatId') ?? true,
      'customSound': prefs.getString('notif_sound_${userId}_$chatId'),
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── Advanced Features ──────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// تفعيل/تعطيل الرسوم المتحركة
  Future<void> setAnimationsEnabled({
    required String userId,
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animations_$userId', enabled);
  }

  Future<bool> getAnimationsEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('animations_$userId') ?? true;
  }

  /// تفعيل/تعطيل الاهتزازات
  Future<void> setVibrationsEnabled({
    required String userId,
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrations_$userId', enabled);
  }

  Future<bool> getVibrationsEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('vibrations_$userId') ?? true;
  }

  /// حفظ جميع الإعدادات في السحابة
  Future<void> syncAllSettings(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      final settings = <String, dynamic>{};
      for (final key in allKeys) {
        if (key.contains(userId)) {
          final value = prefs.get(key);
          if (value != null) {
            settings[key] = value;
          }
        }
      }
      
      await _firestore.collection(AppConstants.colUsers).doc(userId).set({
        'syncedSettings': settings,
        'lastSync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// استرجاع الإعدادات من السحابة
  Future<void> restoreSettingsFromCloud(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.colUsers)
          .doc(userId)
          .get();
      
      if (!doc.exists) return;
      
      final settings = doc.data()?['syncedSettings'] as Map<String, dynamic>?;
      if (settings == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      for (final entry in settings.entries) {
        final value = entry.value;
        if (value is bool) {
          await prefs.setBool(entry.key, value);
        } else if (value is int) {
          await prefs.setInt(entry.key, value);
        } else if (value is double) {
          await prefs.setDouble(entry.key, value);
        } else if (value is String) {
          await prefs.setString(entry.key, value);
        }
      }
    } catch (_) {}
  }
}
