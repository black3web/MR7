import 'package:flutter/foundation.dart' show debugPrint;
import '../config/constants.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Retry helper ──────────────────────────────────────────────────────
  Future<T> _retry<T>(Future<T> Function() fn, {int attempts = 3, Duration delay = const Duration(seconds: 2)}) async {
    Exception? last;
    for (int i = 0; i < attempts; i++) {
      try { return await fn(); }
      on TimeoutException catch (e) {
        last = Exception('انتهت مهلة الاتصال');
        debugPrint('[AI] Timeout #${i+1}: $e');
        if (i < attempts - 1) await Future.delayed(delay * (i + 1));
      } on Exception catch (e) {
        final s = e.toString();
        if (s.contains('غير متاحة') || s.contains('لا تعمل')) rethrow;
        last = e;
        debugPrint('[AI] Error #${i+1}: $e');
        if (i < attempts - 1) await Future.delayed(delay);
      }
    }
    throw last ?? Exception('تعذر الاتصال');
  }

  Future<bool> _enabled(String key) async {
    try {
      final d = await _db.collection('settings').doc('ai_services')
          .get().timeout(const Duration(seconds: 5));
      if (!d.exists) return true;
      return (d.data() as Map<String, dynamic>)[key] ?? true;
    } catch (_) { return true; }
  }

  Future<void> _log(String uid, String svc, String prompt, bool ok, [Map<String,dynamic>? extra]) async {
    try {
      await _db.collection(AppConstants.colAiLogs).add({
        'userId': uid, 'service': svc,
        'prompt': prompt.length > 300 ? '${prompt.substring(0,300)}…' : prompt,
        'success': ok, 'timestamp': DateTime.now().millisecondsSinceEpoch,
        'extra': extra,
      }).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  // ── Gemini Chat ───────────────────────────────────────────────────────
  Future<String> geminiChat(String msg, String uid) async {
    if (!await _enabled('gemini')) throw Exception('الخدمة غير متاحة حالياً');
    return _retry(() async {
      final res = await http.get(
        Uri.parse('${AppConstants.geminiUrl}?text=${Uri.encodeComponent(msg)}'),
      ).timeout(const Duration(seconds: 40));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map;
        final reply = d['reply'] as String?;
        if (d['status'] == 'success' && reply != null && reply.isNotEmpty) {
          await _log(uid, 'gemini', msg, true);
          return reply;
        }
        throw Exception(d['message']?.toString() ?? 'خطأ في المعالجة');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    });
  }

  // ── DeepSeek Chat ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> deepSeekChat(String msg, String uid,
      {String model = '1', String? convId}) async {
    if (!await _enabled('deepseek')) throw Exception('الخدمة غير متاحة حالياً');
    return _retry(() async {
      final body = <String, String>{'model': model, 'message': msg};
      if (convId != null) body['conversation_id'] = convId;
      final res = await http.post(Uri.parse(AppConstants.deepSeekUrl), body: body)
          .timeout(const Duration(seconds: 55));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map;
        if (d['success'] == true) {
          final resp = d['response'] as String?;
          if (resp != null && resp.isNotEmpty) {
            await _log(uid, 'deepseek', msg, true, {'model': model});
            return {'response': resp, 'conversation_id': d['conversation_id'] ?? ''};
          }
        }
        throw Exception(d['message']?.toString() ?? 'خطأ في المعالجة');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    });
  }

  // ── Nano Banana 2 (text-to-image) ────────────────────────────────────
  Future<String> generateImageNano(String prompt, String uid) async {
    if (!await _enabled('imageGen')) throw Exception('الخدمة غير متاحة حالياً');
    return _retry(() async {
      final res = await http.get(
        Uri.parse('${AppConstants.imageNanoUrl}?text=${Uri.encodeComponent(prompt)}'),
      ).timeout(const Duration(seconds: 70));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map;
        final url = d['image_url'] as String?;
        if (d['status'] == 'success' && url != null && url.isNotEmpty) {
          await _log(uid, 'imageGen', prompt, true, {'url': url});
          return url;
        }
        throw Exception(d['message']?.toString() ?? 'فشل توليد الصورة');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    });
  }

  // ── GPT Image 2 (NEW) ─────────────────────────────────────────────────
  Future<String> generateGptImage2(String prompt, String uid) async {
    if (!await _enabled('gptImg2')) throw Exception('الخدمة غير متاحة حالياً');
    return _retry(() async {
      final res = await http.get(
        Uri.parse('${AppConstants.gptImg2Url}?text=${Uri.encodeComponent(prompt)}'),
      ).timeout(const Duration(seconds: 90));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map;
        final url = d['image_url'] as String?;
        if (d['status'] == 'success' && url != null && url.isNotEmpty) {
          await _log(uid, 'gptImg2', prompt, true, {'url': url});
          return url;
        }
        throw Exception(d['message']?.toString() ?? 'فشل توليد الصورة');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    }, attempts: 2);
  }

  // ── NanoBanana Pro (create + edit) ────────────────────────────────────
  Future<String> nanoBananaPro({
    required String prompt, required String uid,
    String ratio = '1:1', String resolution = '2K',
    String? imageUrl, List<String>? imageUrls,
  }) async {
    if (!await _enabled('nanoBananaPro')) throw Exception('الخدمة غير متاحة حالياً');
    return _retry(() async {
      final req = http.MultipartRequest('POST', Uri.parse(AppConstants.nanoBanaProUrl));
      req.fields['text'] = prompt;
      req.fields['ratio'] = ratio;
      req.fields['res'] = resolution;
      if (imageUrls != null && imageUrls.isNotEmpty) {
        req.fields['links'] = imageUrls.length == 1 ? imageUrls.first : jsonEncode(imageUrls);
      } else if (imageUrl != null && imageUrl.isNotEmpty) {
        req.fields['links'] = imageUrl;
      }
      final streamed = await req.send().timeout(const Duration(seconds: 100));
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map;
        final url = d['url'] as String?;
        if (d['success'] == true && url != null && url.isNotEmpty) {
          await _log(uid, 'nanoBananaPro', prompt, true, {'url': url});
          return url;
        }
        throw Exception(d['message']?.toString() ?? 'فشل معالجة الصورة');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    }, attempts: 2);
  }

  // ── Seedance Video ────────────────────────────────────────────────────
  Future<String> seedanceGenerate({
    required String prompt, required String uid,
    String model = 'Seedance 1.5 Pro',
    int duration = 8, String resolution = '720p',
    String aspectRatio = '16:9', String? imageUrl,
  }) async {
    if (!await _enabled('seedance')) throw Exception('الخدمة غير متاحة حالياً');
    return _retry(() async {
      final body = <String, dynamic>{
        'prompt': prompt, 'model': model,
        'duration': duration, 'resolution': resolution,
        'aspect_ratio': aspectRatio,
      };
      if (imageUrl != null && imageUrl.isNotEmpty) body['image_url'] = imageUrl;
      final res = await http.post(
        Uri.parse(AppConstants.seedanceUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 200));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map;
        if (d['success'] == true) {
          final vurl = (d['data'] as Map?)?['video_url'] as String?;
          if (vurl != null && vurl.isNotEmpty) {
            await _log(uid, 'seedance', prompt, true, {'url': vurl, 'model': model});
            return vurl;
          }
        }
        throw Exception(d['message']?.toString() ?? 'فشل توليد الفيديو');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    }, attempts: 2);
  }

  // ── Veo 3 Video AI (NEW — two-step: create task → poll result) ────────
  Future<String> veoGenerate({
    required String prompt, required String uid,
    String model = 'veo-3.1', String aspectRatio = '16:9',
    String? imageUrl,
  }) async {
    if (!await _enabled('veoVideo')) throw Exception('الخدمة غير متاحة حالياً');

    // Step 1: Create generation task
    final taskId = await _retry(() async {
      final body = <String, dynamic>{
        'prompt': prompt, 'model': model, 'aspect_ratio': aspectRatio,
      };
      if (imageUrl != null && imageUrl.isNotEmpty) body['images'] = [imageUrl];
      final res = await http.post(
        Uri.parse(AppConstants.veoCreateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map;
        final tid = d['task_id'] as String?;
        if (tid != null && tid.isNotEmpty) return tid;
        throw Exception(d['message']?.toString() ?? 'فشل إنشاء المهمة');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    });

    // Step 2: Poll for result (up to 4 minutes)
    const maxPolls = 48;
    for (int i = 0; i < maxPolls; i++) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final res = await http.get(
          Uri.parse('${AppConstants.veoResultUrl}/$taskId'),
        ).timeout(const Duration(seconds: 20));
        if (res.statusCode == 200) {
          final d = jsonDecode(res.body) as Map;
          final status = d['status'] as String? ?? '';
          if (status == 'completed') {
            final vurl = d['video_url'] as String?;
            if (vurl != null && vurl.isNotEmpty) {
              await _log(uid, 'veoVideo', prompt, true, {'url': vurl, 'model': model});
              return vurl;
            }
          }
          if (status == 'failed') throw Exception(d['message']?.toString() ?? 'فشل توليد الفيديو');
          // Still processing — continue polling
        }
      } catch (e) {
        if (e.toString().contains('فشل')) rethrow;
        debugPrint('[Veo poll #$i]: $e');
      }
    }
    throw Exception('انتهى وقت الانتظار. حاول مجدداً.');
  }

  // ── Kilwa Video (legacy) ──────────────────────────────────────────────
  Future<String> generateVideoKilwa(String prompt, String uid) async {
    if (!await _enabled('kilwaVideo')) throw Exception('الخدمة غير متاحة حالياً');
    return _retry(() async {
      final res = await http.get(
        Uri.parse('${AppConstants.kilwaVideoUrl}?text=${Uri.encodeComponent(prompt)}'),
      ).timeout(const Duration(seconds: 140));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map;
        final url = d['video_url'] as String?;
        if (d['status'] == 'success' && url != null && url.isNotEmpty) {
          await _log(uid, 'kilwaVideo', prompt, true, {'url': url});
          return url;
        }
        throw Exception(d['message']?.toString() ?? 'فشل توليد الفيديو');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    }, attempts: 2);
  }

  // ── Music AI ─────────────────────────────────────────────────────────
  Future<String> generateMusic({required String prompt, required String uid, String tag = 'sad'}) async {
    if (!await _enabled('musicAi')) throw Exception('الخدمة غير متاحة حالياً');
    return _retry(() async {
      // Try GET first (simpler)
      final res = await http.get(
        Uri.parse('${AppConstants.musicAiUrl}?prompt=${Uri.encodeComponent(prompt)}&tags=$tag'),
      ).timeout(const Duration(seconds: 95));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map;
        final url = d['audio_url'] as String?;
        if (d['success'] == true && url != null && url.isNotEmpty) {
          await _log(uid, 'musicAi', prompt, true, {'url': url, 'tag': tag});
          return url;
        }
        throw Exception(d['message']?.toString() ?? 'فشل توليد الموسيقى');
      }
      throw Exception('خطأ في الخادم (${res.statusCode})');
    }, attempts: 2);
  }

  // ── Admin: toggle service ─────────────────────────────────────────────
  Future<void> toggleService(String key, bool enabled) async =>
      _db.collection('settings').doc('ai_services').set({key: enabled}, SetOptions(merge: true));

  Future<Map<String, bool>> getServiceStates() async {
    try {
      final d = await _db.collection('settings').doc('ai_services').get()
          .timeout(const Duration(seconds: 8));
      if (!d.exists) return _defaults();
      final data = d.data() as Map<String, dynamic>;
      return {for (final k in AppConstants.aiServiceKeys) k: data[k] ?? true};
    } catch (_) { return _defaults(); }
  }

  Map<String, bool> _defaults() =>
      {for (final k in AppConstants.aiServiceKeys) k: true};

  Future<Map<String, int>> getUsageStats() async {
    final stats = <String, int>{for (final k in AppConstants.aiServiceKeys) k: 0, 'total': 0};
    try {
      final snap = await _db.collection(AppConstants.colAiLogs).get()
          .timeout(const Duration(seconds: 15));
      for (final d in snap.docs) {
        final s = d.data()['service'] as String? ?? '';
        if (stats.containsKey(s)) stats[s] = (stats[s] ?? 0) + 1;
        stats['total'] = (stats['total'] ?? 0) + 1;
      }
    } catch (_) {}
    return stats;
  }

  Stream<List<Map<String, dynamic>>> logsStream() =>
      _db.collection(AppConstants.colAiLogs)
          .orderBy('timestamp', descending: true).limit(200).snapshots()
          .map((s) => s.docs.map((d) => {...d.data(), 'docId': d.id}).toList());

  // Models list for UI
  static const List<Map<String, dynamic>> seedanceModels = AppConstants.seedanceModels;
  static const List<String> imageRatios = AppConstants.imageRatios;
  static const List<String> imageResolutions = AppConstants.imageResolutions;
  static const Map<String, String> deepSeekModels = AppConstants.deepSeekModels;
}
