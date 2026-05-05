import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

/// خدمة إدارة الإعدادات والتخصيص الكامل للتطبيق
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  // ═══════════════════════════════════════════════════════════════════════════
  // Initialize
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs => _prefs!;

  // ═══════════════════════════════════════════════════════════════════════════
  // Theme & Colors - نظام تخصيص الألوان الكامل
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// لون أساسي مخصص
  Color get primaryColor {
    final val = prefs.getInt('theme_primary_color');
    return val != null ? Color(val) : const Color(0xFF8B0000);
  }

  Future<void> setPrimaryColor(Color color) async {
    await prefs.setInt('theme_primary_color', color.value);
  }

  /// لون ثانوي مخصص
  Color get accentColor {
    final val = prefs.getInt('theme_accent_color');
    return val != null ? Color(val) : const Color(0xFFFF1744);
  }

  Future<void> setAccentColor(Color color) async {
    await prefs.setInt('theme_accent_color', color.value);
  }

  /// لون خلفية التطبيق
  Color get backgroundColor {
    final val = prefs.getInt('theme_bg_color');
    return val != null ? Color(val) : const Color(0xFF0A0A0A);
  }

  Future<void> setBackgroundColor(Color color) async {
    await prefs.setInt('theme_bg_color', color.value);
  }

  /// لون فقاعات الرسائل (المرسِل)
  Color get selfBubbleColor {
    final val = prefs.getInt('theme_self_bubble');
    return val != null ? Color(val) : const Color(0x308B0000);
  }

  Future<void> setSelfBubbleColor(Color color) async {
    await prefs.setInt('theme_self_bubble', color.value);
  }

  /// لون فقاعات الرسائل (المستقبِل)
  Color get otherBubbleColor {
    final val = prefs.getInt('theme_other_bubble');
    return val != null ? Color(val) : const Color(0x14FFFFFF);
  }

  Future<void> setOtherBubbleColor(Color color) async {
    await prefs.setInt('theme_other_bubble', color.value);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Chat Background - خلفية المحادثة
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// نوع الخلفية: none, gradient, image
  String get chatBackgroundType {
    return prefs.getString('chat_bg_type') ?? 'gradient';
  }

  Future<void> setChatBackgroundType(String type) async {
    await prefs.setString('chat_bg_type', type);
  }

  /// معرف الخلفية المحددة
  String get chatBackgroundId {
    return prefs.getString('chat_bg_id') ?? 'dark_stars';
  }

  Future<void> setChatBackgroundId(String id) async {
    await prefs.setString('chat_bg_id', id);
  }

  /// مسار صورة الخلفية المخصصة
  String? get customChatBackground {
    return prefs.getString('chat_bg_custom');
  }

  Future<void> setCustomChatBackground(String? path) async {
    if (path != null) {
      await prefs.setString('chat_bg_custom', path);
    } else {
      await prefs.remove('chat_bg_custom');
    }
  }

  /// شفافية الخلفية (0.0 - 1.0)
  double get chatBackgroundOpacity {
    return prefs.getDouble('chat_bg_opacity') ?? 0.6;
  }

  Future<void> setChatBackgroundOpacity(double opacity) async {
    await prefs.setDouble('chat_bg_opacity', opacity);
  }

  /// blur effect للخلفية
  double get chatBackgroundBlur {
    return prefs.getDouble('chat_bg_blur') ?? 8.0;
  }

  Future<void> setChatBackgroundBlur(double blur) async {
    await prefs.setDouble('chat_bg_blur', blur);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Typography - إعدادات النصوص
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// مقياس حجم الخط (0.8 - 1.5)
  double get fontScale {
    return prefs.getDouble(AppConstants.prefFontScale) ?? 1.0;
  }

  Future<void> setFontScale(double scale) async {
    await prefs.setDouble(AppConstants.prefFontScale, scale);
  }

  /// نوع الخط
  String get fontFamily {
    return prefs.getString('font_family') ?? 'default';
  }

  Future<void> setFontFamily(String family) async {
    await prefs.setString('font_family', family);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI Preferences - تفضيلات الواجهة
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// تفعيل الوضع الليلي التلقائي
  bool get autoNightMode {
    return prefs.getBool(AppConstants.prefAutoNight) ?? true;
  }

  Future<void> setAutoNightMode(bool enabled) async {
    await prefs.setBool(AppConstants.prefAutoNight, enabled);
  }

  /// تفعيل تأثير Glassmorphism
  bool get glassEffect {
    return prefs.getBool('glass_effect') ?? true;
  }

  Future<void> setGlassEffect(bool enabled) async {
    await prefs.setBool('glass_effect', enabled);
  }

  /// تفعيل الرسوم المتحركة
  bool get animations {
    return prefs.getBool('animations_enabled') ?? true;
  }

  Future<void> setAnimations(bool enabled) async {
    await prefs.setBool('animations_enabled', enabled);
  }

  /// شكل الفقاعات: rounded, sharp, pill
  String get bubbleShape {
    return prefs.getString('bubble_shape') ?? 'rounded';
  }

  Future<void> setBubbleShape(String shape) async {
    await prefs.setString('bubble_shape', shape);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Privacy & Security - الخصوصية والأمان
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// تفعيل القفل البيومتري
  bool get biometricLock {
    return prefs.getBool(AppConstants.prefBiometric) ?? false;
  }

  Future<void> setBiometricLock(bool enabled) async {
    await prefs.setBool(AppConstants.prefBiometric, enabled);
  }

  /// إخفاء آخر ظهور
  bool get hideLastSeen {
    return prefs.getBool('hide_last_seen') ?? false;
  }

  Future<void> setHideLastSeen(bool hide) async {
    await prefs.setBool('hide_last_seen', hide);
  }

  /// إخفاء صورة الملف الشخصي
  bool get hideProfilePhoto {
    return prefs.getBool('hide_profile_photo') ?? false;
  }

  Future<void> setHideProfilePhoto(bool hide) async {
    await prefs.setBool('hide_profile_photo', hide);
  }

  /// من يمكنه مراسلتي
  String get whoCanMessage {
    return prefs.getString('who_can_message') ?? 'everyone';
  }

  Future<void> setWhoCanMessage(String value) async {
    await prefs.setString('who_can_message', value);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Notifications - الإشعارات
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// تفعيل الإشعارات
  bool get notificationsEnabled {
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await prefs.setBool('notifications_enabled', enabled);
  }

  /// صوت الإشعار
  bool get notificationSound {
    return prefs.getBool('notification_sound') ?? true;
  }

  Future<void> setNotificationSound(bool enabled) async {
    await prefs.setBool('notification_sound', enabled);
  }

  /// اهتزاز الإشعار
  bool get notificationVibration {
    return prefs.getBool('notification_vibration') ?? true;
  }

  Future<void> setNotificationVibration(bool enabled) async {
    await prefs.setBool('notification_vibration', enabled);
  }

  /// عرض محتوى الرسالة في الإشعار
  bool get showMessagePreview {
    return prefs.getBool('show_message_preview') ?? true;
  }

  Future<void> setShowMessagePreview(bool show) async {
    await prefs.setBool('show_message_preview', show);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Chat Features - ميزات المحادثة
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// تفعيل مؤشر الكتابة
  bool get typingIndicator {
    return prefs.getBool('typing_indicator') ?? true;
  }

  Future<void> setTypingIndicator(bool enabled) async {
    await prefs.setBool('typing_indicator', enabled);
  }

  /// تفعيل علامات القراءة
  bool get readReceipts {
    return prefs.getBool('read_receipts') ?? true;
  }

  Future<void> setReadReceipts(bool enabled) async {
    await prefs.setBool('read_receipts', enabled);
  }

  /// إرسال بـ Enter
  bool get sendOnEnter {
    return prefs.getBool('send_on_enter') ?? false;
  }

  Future<void> setSendOnEnter(bool enabled) async {
    await prefs.setBool('send_on_enter', enabled);
  }

  /// حفظ الوسائط تلقائياً
  bool get autoDownloadMedia {
    return prefs.getBool('auto_download_media') ?? true;
  }

  Future<void> setAutoDownloadMedia(bool enabled) async {
    await prefs.setBool('auto_download_media', enabled);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Language - اللغة
  // ═══════════════════════════════════════════════════════════════════════════
  
  String get language {
    return prefs.getString(AppConstants.prefLanguage) ?? 'ar';
  }

  Future<void> setLanguage(String lang) async {
    await prefs.setString(AppConstants.prefLanguage, lang);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Developer Mode - وضع المطور
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// تفعيل وضع المطور
  bool get developerMode {
    return prefs.getBool('developer_mode') ?? false;
  }

  Future<void> setDeveloperMode(bool enabled) async {
    await prefs.setBool('developer_mode', enabled);
  }

  /// عرض معلومات التشخيص
  bool get showDebugInfo {
    return prefs.getBool('show_debug_info') ?? false;
  }

  Future<void> setShowDebugInfo(bool show) async {
    await prefs.setBool('show_debug_info', show);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Presets - إعدادات مسبقة
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// تطبيق ثيم مسبق
  Future<void> applyPreset(String presetName) async {
    switch (presetName) {
      case 'dark_red':
        await setPrimaryColor(const Color(0xFF8B0000));
        await setAccentColor(const Color(0xFFFF1744));
        await setBackgroundColor(const Color(0xFF0A0A0A));
        await setChatBackgroundId('dark_stars');
        break;
      case 'dark_blue':
        await setPrimaryColor(const Color(0xFF1565C0));
        await setAccentColor(const Color(0xFF42A5F5));
        await setBackgroundColor(const Color(0xFF0A0A14));
        await setChatBackgroundId('ocean');
        break;
      case 'dark_green':
        await setPrimaryColor(const Color(0xFF2E7D32));
        await setAccentColor(const Color(0xFF66BB6A));
        await setBackgroundColor(const Color(0xFF0A140A));
        await setChatBackgroundId('forest');
        break;
      case 'dark_purple':
        await setPrimaryColor(const Color(0xFF6A1B9A));
        await setAccentColor(const Color(0xFFAB47BC));
        await setBackgroundColor(const Color(0xFF0A0A14));
        await setChatBackgroundId('midnight');
        break;
      case 'telegram':
        await setPrimaryColor(const Color(0xFF0088CC));
        await setAccentColor(const Color(0xFF00A8E8));
        await setBackgroundColor(const Color(0xFF0E1621));
        await setChatBackgroundId('none');
        break;
      case 'whatsapp':
        await setPrimaryColor(const Color(0xFF075E54));
        await setAccentColor(const Color(0xFF25D366));
        await setBackgroundColor(const Color(0xFF111B21));
        await setChatBackgroundId('none');
        break;
      case 'discord':
        await setPrimaryColor(const Color(0xFF5865F2));
        await setAccentColor(const Color(0xFF7289DA));
        await setBackgroundColor(const Color(0xFF2C2F33));
        await setChatBackgroundId('none');
        break;
    }
  }

  /// إعادة تعيين جميع الإعدادات
  Future<void> resetAllSettings() async {
    await prefs.clear();
  }

  /// تصدير الإعدادات
  Map<String, dynamic> exportSettings() {
    return {
      'theme_primary_color': primaryColor.value,
      'theme_accent_color': accentColor.value,
      'theme_bg_color': backgroundColor.value,
      'chat_bg_type': chatBackgroundType,
      'chat_bg_id': chatBackgroundId,
      'font_scale': fontScale,
      'auto_night': autoNightMode,
      'glass_effect': glassEffect,
      'animations': animations,
      'bubble_shape': bubbleShape,
      'language': language,
    };
  }

  /// استيراد الإعدادات
  Future<void> importSettings(Map<String, dynamic> settings) async {
    for (final entry in settings.entries) {
      switch (entry.key) {
        case 'theme_primary_color':
          await setPrimaryColor(Color(entry.value as int));
          break;
        case 'theme_accent_color':
          await setAccentColor(Color(entry.value as int));
          break;
        case 'theme_bg_color':
          await setBackgroundColor(Color(entry.value as int));
          break;
        case 'chat_bg_type':
          await setChatBackgroundType(entry.value as String);
          break;
        case 'chat_bg_id':
          await setChatBackgroundId(entry.value as String);
          break;
        case 'font_scale':
          await setFontScale(entry.value as double);
          break;
        case 'auto_night':
          await setAutoNightMode(entry.value as bool);
          break;
        case 'glass_effect':
          await setGlassEffect(entry.value as bool);
          break;
        case 'animations':
          await setAnimations(entry.value as bool);
          break;
        case 'bubble_shape':
          await setBubbleShape(entry.value as String);
          break;
        case 'language':
          await setLanguage(entry.value as String);
          break;
      }
    }
  }
}
