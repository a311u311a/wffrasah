import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  bool _isNotificationsEnabled = true;

  bool get isNotificationsEnabled => _isNotificationsEnabled;

  NotificationProvider() {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ التحقق من حالة الإذن الفعلية في النظام عند بدء التشغيل
    final permissionStatus = await Permission.notification.status;
    final isSystemEnabled = permissionStatus.isGranted;

    // نأخذ الحالة المحفوظة كمرجع أولي
    final savedPreference = prefs.getBool('notifications_enabled') ?? true;

    // إذا كان النظام يرفض الإشعارات، يجب أن يكون السويتش مغلقاً بغض النظر عن الحالة المحفوظة
    // وإذا كان النظام يسمح، نستخدم الحالة المحفوظة
    if (!isSystemEnabled) {
      _isNotificationsEnabled = false;
      // تحديث التخزين ليتوافق مع النظام
      await prefs.setBool('notifications_enabled', false);
    } else {
      _isNotificationsEnabled = savedPreference;
    }

    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _isNotificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);

    // تحديث الواجهة فوراً قبل عملية FCM
    notifyListeners();

    // Update FCM Subscription في الخلفية (fire-and-forget)
    // لا ننتظر اكتمالها لتجنب تجميد الواجهة
    NotificationService.updateFCMSubscription(value);
  }
}
