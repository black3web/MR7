import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class MusicAiService {
  static final MusicAiService _i = MusicAiService._();
  factory MusicAiService() => _i;
  MusicAiService._();

  final _db = FirebaseFirestore.instance;

  static const List<Map<String, String>> supportedTags = [
    {'id': 'sad',       'label': '😢 حزين'},
    {'id': 'happy',     'label': '😊 سعيد'},
    {'id': 'romantic',  'label': '❤️ رومانسي'},
    {'id': 'energetic', 'label': '⚡ حماسي'},
  ];

  Future<String> generateMusic({
    required String prompt,
    required String userId,
    String tag = 'sad',
  }) async {
    Exception? last;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        // Try GET first (viscodev API)
        final res = await http.get(
          Uri.parse('${AppConstants.musicAiUrl}?prompt=${Uri.encodeComponent(prompt)}&tags=$tag'),
        ).timeout(const Duration(seconds: 100));

        if (res.statusCode == 200) {
          final d = jsonDecode(res.body) as Map;
          final url = d['audio_url'] as String?;
          if (d['success'] == true && url != null && url.isNotEmpty) {
            await _saveToHistory(userId, prompt, tag, url);
            return url;
          }
          throw Exception(d['message']?.toString() ?? 'فشل توليد الموسيقى');
        }

        // Fallback: try POST
        if (res.statusCode != 200) {
          final resPost = await http.post(
            Uri.parse(AppConstants.musicAiUrl),
            body: {'prompt': prompt, 'tags': tag},
          ).timeout(const Duration(seconds: 100));
          if (resPost.statusCode == 200) {
            final d = jsonDecode(resPost.body) as Map;
            final url = d['audio_url'] as String?;
            if (d['success'] == true && url != null && url.isNotEmpty) {
              await _saveToHistory(userId, prompt, tag, url);
              return url;
            }
          }
          throw Exception('خطأ في الخادم (${res.statusCode})');
        }
      } on Exception catch (e) {
        last = e;
        if (attempt < 2) await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw last ?? Exception('تعذر توليد الموسيقى');
  }

  Future<void> _saveToHistory(String uid, String prompt, String tag, String url) async {
    try {
      await _db.collection(AppConstants.colAiLogs).add({
        'userId':  uid,
        'service': 'musicAi',
        'prompt':  prompt,
        'success': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'extra':   {'tag': tag, 'audioUrl': url},
      }).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Stream<List<Map<String, dynamic>>> getUserMusicHistory(String userId) =>
      _db.collection(AppConstants.colAiLogs)
          .where('userId',  isEqualTo: userId)
          .where('service', isEqualTo: 'musicAi')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .snapshots()
          .map((s) => s.docs.map((d) => {...d.data(), 'docId': d.id}).toList())
          .handleError((_) => <Map<String, dynamic>>[]);
}
