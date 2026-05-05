import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

/// In-app notification service (no FCM required - works on GitHub Pages / web)
class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _db = FirebaseFirestore.instance;
  final _streamController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream => _streamController.stream;

  StreamSubscription<QuerySnapshot>? _sub;

  // ── Start listening ───────────────────────────────────────────────────
  void startListening(String userId) {
    _sub?.cancel();
    _sub = _db.collection(AppConstants.colNotifs)
        .where('toUserId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final d = change.doc.data();
          if (d != null) _streamController.add({...d, 'docId': change.doc.id});
        }
      }
    }, onError: (_) {});
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  // ── Create notification ────────────────────────────────────────────────
  Future<void> createNotification({
    required String toUserId,
    required String fromUserId,
    required String fromName,
    String? fromPhotoUrl,
    required String type, // 'message' | 'group_message' | 'story' | 'reaction' | 'join' | 'ai'
    required String title,
    required String body,
    String? chatId,
    String? groupId,
  }) async {
    if (toUserId == fromUserId) return; // No self-notifications
    try {
      await _db.collection(AppConstants.colNotifs).add({
        'toUserId':     toUserId,
        'fromUserId':   fromUserId,
        'fromName':     fromName,
        'fromPhotoUrl': fromPhotoUrl,
        'type':         type,
        'title':        title,
        'body':         body,
        'chatId':       chatId,
        'groupId':      groupId,
        'read':         false,
        'createdAt':    FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  // ── Get unread count ────────────────────────────────────────────────────
  Stream<int> unreadCount(String userId) => _db
      .collection(AppConstants.colNotifs)
      .where('toUserId', isEqualTo: userId)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.length)
      .handleError((_) => 0);

  // ── Get notifications list ─────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> getNotifications(String userId) => _db
      .collection(AppConstants.colNotifs)
      .where('toUserId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(80)
      .snapshots()
      .map((s) => s.docs.map((d) => {...d.data(), 'docId': d.id}).toList())
      .handleError((_) => <Map<String, dynamic>>[]);

  // ── Mark as read ────────────────────────────────────────────────────────
  Future<void> markRead(String docId) async {
    try {
      await _db.collection(AppConstants.colNotifs)
          .doc(docId).update({'read': true}).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<void> markAllRead(String userId) async {
    try {
      final snap = await _db.collection(AppConstants.colNotifs)
          .where('toUserId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get().timeout(const Duration(seconds: 10));
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.update(d.reference, {'read': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  // ── Delete notification ────────────────────────────────────────────────
  Future<void> deleteNotif(String docId) async {
    try {
      await _db.collection(AppConstants.colNotifs).doc(docId).delete();
    } catch (_) {}
  }

  // ── Clear all ────────────────────────────────────────────────────────
  Future<void> clearAll(String userId) async {
    try {
      final snap = await _db.collection(AppConstants.colNotifs)
          .where('toUserId', isEqualTo: userId).get();
      final b = _db.batch();
      for (final d in snap.docs) b.delete(d.reference);
      await b.commit();
    } catch (_) {}
  }

  void dispose() {
    _sub?.cancel();
    _streamController.close();
  }
}
