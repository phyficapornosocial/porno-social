import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    await _saveToken(token);

    _messaging.onTokenRefresh.listen((token) async {
      await _saveToken(token);
    });

    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';
      debugPrint('Foreground notification: $title | $body');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification tapped: ${message.data}');
    });
  }

  Future<void> _saveToken(String? token) async {
    if (token == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmToken': token,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}
