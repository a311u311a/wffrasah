import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../models/coupon.dart';
import '../models/offers.dart';
import '../localization/app_localizations.dart';
import '../screens/signin.dart';
import '../screens/login_signup/widgets/snackbar.dart';
import '../constants.dart';
import 'user_provider.dart';

class FavoriteProvider with ChangeNotifier {
  final List<dynamic> _favoriteItems = []; // Coupon / Offer
  bool _isLoading = false;

  List<dynamic> get favoriteItems => List.unmodifiable(_favoriteItems);
  bool get isLoading => _isLoading;

  FavoriteProvider() {
    _init();
  }

  void _init() {
    // سيتم تحميل المفضلة عند تسجيل الدخول من خلال UserProvider
    _listenToAuthChanges();
  }

  /// الاستماع لتغييرات المصادقة
  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final User? user = data.session?.user;
      if (user != null) {
        // المستخدم سجل دخول - تحميل مفضلته
        loadFavorites();
      } else {
        // المستخدم سجل خروج - مسح المفضلة المحلية
        _favoriteItems.clear();
        notifyListeners();
      }
    });
  }

  bool isFavorite(String itemId) {
    return _favoriteItems.any((item) {
      try {
        return (item as dynamic).id == itemId;
      } catch (_) {
        return false;
      }
    });
  }

  /// للحصول على قائمة IDs فقط (للويب)
  Set<String> get favoriteIds {
    return _favoriteItems
        .map((item) {
          try {
            return (item as dynamic).id.toString();
          } catch (_) {
            return '';
          }
        })
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  /// إضافة/إزالة من المفضلة مع فحص تسجيل الدخول
  Future<void> toggleFavorite(dynamic item, BuildContext context) async {
    // 1. التحقق من تسجيل الدخول
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;

    if (currentUser == null) {
      // عرض رسالة تحذيرية
      _showLoginRequiredMessage(context);
      return;
    }

    // 2. الحصول على ID
    final String id;
    try {
      id = (item as dynamic).id.toString();
    } catch (e) {
      debugPrint('toggleFavorite: item has no id -> $e');
      return;
    }

    final exists = isFavorite(id);
    final localizations = AppLocalizations.of(context)!;

    try {
      if (exists) {
        // إزالة من المفضلة
        await _removeFromFavorites(id, currentUser.id);

        // إظهار رسالة نجاح
        if (context.mounted) {
          showSnackBar(
            context,
            localizations.translate('removed_from_favorites'),
          );
        }
      } else {
        // إضافة للمفضلة
        await _addToFavorites(item, currentUser.id);

        // إظهار رسالة نجاح
        if (context.mounted) {
          showSnackBar(
            context,
            localizations.translate('added_to_favorites'),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      if (context.mounted) {
        showSnackBar(
          context,
          localizations.translate('error_occurred'),
          isError: true,
        );
      }
    }
  }

  /// إضافة عنصر للمفضلة في Supabase
  Future<void> _addToFavorites(dynamic item, String userId) async {
    // تحديد نوع العنصر
    final String itemType;
    final Map<String, dynamic> itemData;

    if (item is Coupon) {
      itemType = 'coupon';
      itemData = item.toJson();
    } else if (item is Offer) {
      itemType = 'offer';
      itemData = item.toJson();
    } else {
      debugPrint('Unknown item type');
      return;
    }

    final String itemId = (item as dynamic).id.toString();

    // إدراج في قاعدة البيانات
    await Supabase.instance.client.from('favorites').insert({
      'user_id': userId,
      'item_id': itemId,
      'item_type': itemType,
      'item_data': itemData,
    });

    // إضافة محلياً
    _favoriteItems.add(item);
    notifyListeners();
  }

  /// إزالة عنصر من المفضلة في Supabase
  Future<void> _removeFromFavorites(String itemId, String userId) async {
    // حذف من قاعدة البيانات
    await Supabase.instance.client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('item_id', itemId);

    // إزالة محلياً
    _favoriteItems.removeWhere((fav) {
      try {
        return (fav as dynamic).id.toString() == itemId;
      } catch (_) {
        return false;
      }
    });
    notifyListeners();
  }

  /// تحميل المفضلة من Supabase
  Future<void> loadFavorites() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      _favoriteItems.clear();
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final response = await Supabase.instance.client
          .from('favorites')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      final List<dynamic> loaded = [];

      for (final row in response) {
        try {
          final itemType = row['item_type'] as String;
          final itemDataRaw = row['item_data'];

          // تحويل item_data إلى Map
          final Map<String, dynamic> itemData = _ensureMap(itemDataRaw);

          if (itemType == 'coupon') {
            loaded.add(Coupon.fromJson(itemData, 'ar'));
          } else if (itemType == 'offer') {
            loaded.add(Offer.fromJson(itemData, 'ar'));
          }
        } catch (e) {
          debugPrint('Error loading favorite item: $e');
          continue;
        }
      }

      _favoriteItems
        ..clear()
        ..addAll(loaded);
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// عرض رسالة تطلب تسجيل الدخول
  void _showLoginRequiredMessage(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: X في اليمين
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.black54, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // أيقونة القفل
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Constants.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: Constants.primaryColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),

                // العنوان
                Text(
                  localizations.translate('login_required'),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // الرسالة
                Text(
                  localizations.translate('login_to_add_favorites'),
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // زر تسجيل الدخول
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignIn()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      localizations.translate('go_to_login'),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// تحويل البيانات إلى Map
  Map<String, dynamic> _ensureMap(dynamic data) {
    if (data == null) return <String, dynamic>{};

    if (data is Map<String, dynamic>) return data;

    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }

    if (data is String) {
      final s = data.trim();
      if (s.isEmpty) return <String, dynamic>{};

      try {
        final decoded = jsonDecode(s);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {
        return <String, dynamic>{};
      }
    }

    return <String, dynamic>{};
  }
}
