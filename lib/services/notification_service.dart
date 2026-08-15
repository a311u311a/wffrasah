import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../constants.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static FirebaseMessaging? _firebaseMessaging;
  static StreamSubscription? _subscription;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static bool _isFirebaseInitialized = false;
  static String? _lastShownId;
  static const String _webVapidKey =
      String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');
  static const Set<TargetPlatform> _apnsPlatforms = {
    TargetPlatform.iOS,
    TargetPlatform.macOS,
  };

  /// Initialize Firebase Core and Messaging (System/Background)
  static Future<void> initFirebase() async {
    try {
      if (_isFirebaseInitialized) return;

      // 0. Initialize Firebase Core
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isFirebaseInitialized = true;
      debugPrint('✅ Firebase Initialized');

      // 1. Initialize FCM
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
      }
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
        if (kIsWeb) {
          await _registerWebToken();
          return;
        }
        if (!await _isNativeMessagingReady()) return;
        await _firebaseMessaging!.subscribeToTopic('all');
        debugPrint('✅ Subscribed to topic "all" (User Enabled)');
      } else {
        if (kIsWeb) {
          await _deleteWebToken();
          return;
        }
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
          }, onError: (Object error, StackTrace stackTrace) {
            // Realtime errors must not escape into Flutter's error handler.
            debugPrint('⚠️ Supabase realtime notification error: $error');
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
          if (kIsWeb) {
            await _registerWebToken();
            _tokenRefreshSubscription?.cancel();
            _tokenRefreshSubscription =
                _firebaseMessaging!.onTokenRefresh.listen(_saveWebToken);
          } else {
            if (!await _isNativeMessagingReady()) return;
            await _firebaseMessaging!.subscribeToTopic('all');
          }
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

  static Future<bool> _isNativeMessagingReady() async {
    if (kIsWeb || !_apnsPlatforms.contains(defaultTargetPlatform)) {
      return true;
    }

    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        final token = await _firebaseMessaging!.getAPNSToken();
        if (token != null && token.isNotEmpty) return true;
      } on FirebaseException catch (e) {
        if (e.code != 'apns-token-not-set') rethrow;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    debugPrint(
      '⚠️ APNS token is not ready yet; skipping FCM topic subscription for now.',
    );
    return false;
  }

  static Future<void> _registerWebToken() async {
    if (!kIsWeb) return;
    if (_webVapidKey.isEmpty) {
      debugPrint(
        'Web push is missing FIREBASE_WEB_VAPID_KEY. '
        'Run with --dart-define=FIREBASE_WEB_VAPID_KEY=YOUR_KEY',
      );
      return;
    }

    final token = await _firebaseMessaging!.getToken(vapidKey: _webVapidKey);
    if (token == null || token.isEmpty) {
      debugPrint('FCM web token is empty');
      return;
    }

    await _saveWebToken(token);
  }

  static Future<void> _saveWebToken(String token) async {
    await _supabase.from('fcm_tokens').upsert(
      {
        'token': token,
        'user_id': _supabase.auth.currentUser?.id,
        'platform': 'web',
        'is_enabled': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'token',
    );
    debugPrint('Web FCM token registered');
  }

  static Future<void> _deleteWebToken() async {
    if (!kIsWeb || _webVapidKey.isEmpty) return;

    final token = await _firebaseMessaging!.getToken(vapidKey: _webVapidKey);
    if (token != null && token.isNotEmpty) {
      await _supabase.from('fcm_tokens').delete().eq('token', token);
    }
    await _firebaseMessaging!.deleteToken();
    debugPrint('Web FCM token deleted');
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

  static Future<PushNotificationResult> sendPushNotificationDetailed({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-push-notification',
        body: {
          'title': title,
          'body': body,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        },
      );

      final data = response.data;
      if (response.status >= 200 &&
          response.status < 300 &&
          data is Map &&
          data['success'] == true) {
        return PushNotificationResult(
          success: true,
          message: data.toString(),
        );
      }

      return PushNotificationResult(
        success: false,
        message: 'Status ${response.status}: ${_formatFunctionError(data)}',
      );
    } catch (e) {
      return PushNotificationResult(success: false, message: e.toString());
    }
  }

  static String _formatFunctionError(dynamic data) {
    if (data is Map) {
      final error = data['error'];
      if (error is Map) {
        final message = error['message'];
        if (message != null) return message.toString();
      }
      if (error != null) return error.toString();
      final message = data['message'];
      if (message != null) return message.toString();
    }
    if (data != null) return data.toString();
    return 'Unknown push notification error';
  }

  /// Send Push Notification via Supabase Edge Function
  /// The Firebase Service Account key is stored securely on the server side
  static Future<bool> sendPushNotification({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-push-notification',
        body: {
          'title': title,
          'body': body,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        },
      );

      if (response.status == 200) {
        final data = response.data;
        if (data != null && data['success'] == true) {
          debugPrint('✅ Push notification sent successfully via Edge Function');
          return true;
        }
      }

      debugPrint('❌ Failed to send push via Edge Function: ${response.data}');
      return false;
    } catch (e) {
      debugPrint('❌ Error sending push via Edge Function: $e');
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

class PushNotificationResult {
  const PushNotificationResult({
    required this.success,
    this.message,
  });

  final bool success;
  final String? message;
}
