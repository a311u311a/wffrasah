import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../constants.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static FirebaseMessaging? _firebaseMessaging;
  static StreamSubscription? _subscription;
  static String? _lastShownId;

  /// Initialize Firebase Core and Messaging (System/Background)
  static Future<void> initFirebase() async {
    try {
      // 0. Initialize Firebase Core
      await Firebase.initializeApp();
      debugPrint('✅ Firebase Initialized');

      // 1. Initialize FCM
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      await _initFCM();
    } catch (e) {
      debugPrint('❌ Firebase Init Error: $e');
    }
  }

  /// Toggle FCM subscription based on user preference
  static Future<void> updateFCMSubscription(bool isEnabled) async {
    try {
      _firebaseMessaging ??= FirebaseMessaging.instance;
      if (isEnabled) {
        await _firebaseMessaging!.subscribeToTopic('all');
        debugPrint('✅ Subscribed to topic "all" (User Enabled)');
      } else {
        await _firebaseMessaging!.unsubscribeFromTopic('all');
        debugPrint('🔕 Unsubscribed from topic "all" (User Disabled)');
      }
    } catch (e) {
      debugPrint('❌ Error updating FCM subscription: $e');
    }
  }

  /// Start Listening to Supabase Realtime (In-App UI)
  /// Should be called after Splash Screen (e.g. in BottomNavBar)
  static void listenToInAppNotifications(BuildContext context) {
    // Cancel previous subscription to prevent duplicates
    _subscription?.cancel();
    _subscription = _initSupabaseRealtime(context);
  }

  /// Stop listening to Supabase Realtime
  /// Should be called when app goes to background
  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('🛑 Stopped In-App Notifications stream');
  }

  static StreamSubscription? _initSupabaseRealtime(BuildContext context) {
    try {
      debugPrint('🔔 Initializing In-App Notifications (Supabase)...');
      return _supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(1)
          .listen((List<Map<String, dynamic>> data) {
            if (data.isNotEmpty) {
              _handleSupabaseNotification(context, data.first);
            }
          });
    } catch (e) {
      debugPrint('❌ Error initializing Supabase realtime: $e');
      return null;
    }
  }

  static Future<void> _initFCM() async {
    try {
      debugPrint('🔔 Initializing FCM...');
      _firebaseMessaging = FirebaseMessaging.instance;

      // Request Permission (iOS / Android 13+)
      NotificationSettings settings =
          await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted permission');

        // Check preference before subscribing
        final prefs = await SharedPreferences.getInstance();
        final isEnabled = prefs.getBool('notifications_enabled') ?? true;

        if (isEnabled) {
          await _firebaseMessaging!.subscribeToTopic('all');
          debugPrint('✅ Subscribed to topic "all"');
        } else {
          debugPrint('🔕 Notifications disabled, skipping subscription');
        }
      } else {
        debugPrint('❌ User declined or has not accepted permission');
      }

      // Listen to foreground messages to debug receipt
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 FCM Foreground Message Received: ${message.messageId}');
        if (message.notification != null) {
          debugPrint('   Title: ${message.notification!.title}');
          debugPrint('   Body: ${message.notification!.body}');
        }
      });
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  static void _handleSupabaseNotification(
      BuildContext context, Map<String, dynamic> notification) {
    // ✅ فحص مبكر للتأكد من أن الـ context صالح
    if (!context.mounted) {
      debugPrint('⚠️ Context not mounted, skipping notification');
      return;
    }

    final id = notification['id']?.toString();
    if (id != null && id == _lastShownId) {
      debugPrint('🚫 Skipping duplicate notification: $id');
      return;
    }

    // Check if user has enabled notifications
    final isEnabled = Provider.of<NotificationProvider>(context, listen: false)
        .isNotificationsEnabled;
    if (!isEnabled) {
      debugPrint('🔕 In-app notifications are disabled by user');
      return;
    }

    // Logic for showing the dialog when app is open
    final title = notification['title'] ?? 'إشعار جديد';
    final body = notification['body'] ?? '';
    final isBroadcast = notification['is_broadcast'] ?? false;
    final userId = notification['user_id'];
    final currentUserId = _supabase.auth.currentUser?.id;

    // Show if broadcast OR specific to this user
    if (isBroadcast || (userId != null && userId == currentUserId)) {
      _lastShownId = id; // Mark as shown

      // ✅ فحص نهائي قبل عرض الحوار
      if (context.mounted) {
        _showNotificationDialog(
            context, title, body, notification['image_url']);
      }
    }
  }

  /// Send Push Notification using FCM HTTP v1 API
  static Future<bool> sendPushNotification({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    try {
      final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(Constants.fcmServiceAccountJson),
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      final projectId = Constants.fcmServiceAccountJson['project_id'];
      final response = await client.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': {
            'topic': 'all',
            'notification': {
              'title': title,
              'body': body,
              if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              if (imageUrl != null && imageUrl.isNotEmpty)
                'image_url': imageUrl,
            },
            'android': {
              'priority': 'HIGH',
              'notification': {
                'sound': 'default',
                'channel_id': 'high_importance_channel',
              }
            },
            'apns': {
              'headers': {
                'apns-priority': '10',
              },
              'payload': {
                'aps': {
                  'sound': 'default',
                }
              }
            }
          }
        }),
      );

      client.close();

      if (response.statusCode == 200) {
        debugPrint('✅ Push notification sent successfully (v1)');
        return true;
      } else {
        debugPrint('❌ Failed to send push (v1): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending push (v1): $e');
      return false;
    }
  }

  static void _showNotificationDialog(
      BuildContext context, String title, String body, String? imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image,
                        size: 50, color: Colors.grey),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Constants.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'إغلاق',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
