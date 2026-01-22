import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/coupon.dart';
import '../models/offers.dart';

class FavoriteProvider with ChangeNotifier {
  final List<dynamic> _favoriteItems = []; // Coupon / Offer

  List<dynamic> get favoriteItems => List.unmodifiable(_favoriteItems);

  FavoriteProvider() {
    _loadFavorites();
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

  Future<void> toggleFavorite(dynamic item) async {
    // حماية: لازم يكون عنده id
    final String id;
    try {
      id = (item as dynamic).id.toString();
    } catch (e) {
      debugPrint('toggleFavorite: item has no id -> $e');
      return;
    }

    final exists = isFavorite(id);

    if (exists) {
      _favoriteItems.removeWhere((fav) {
        try {
          return (fav as dynamic).id.toString() == id;
        } catch (_) {
          return false;
        }
      });
    } else {
      _favoriteItems.add(item);
    }

    await _saveFavorites();
    notifyListeners();
  }

  // ---------------------------
  // Save
  // ---------------------------
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedItems = _favoriteItems.map((item) {
      if (item is Coupon) {
        return jsonEncode({'type': 'coupon', 'data': item.toJson()});
      } else if (item is Offer) {
        return jsonEncode({'type': 'offer', 'data': item.toJson()});
      } else {
        // نتجاهل أي نوع غير مدعوم بدل ما نكسر التطبيق
        return jsonEncode({'type': 'unknown', 'data': {}});
      }
    }).toList();

    await prefs.setStringList('favoriteItems', encodedItems);
  }

  // ---------------------------
  // Load (Robust)
  // ---------------------------
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final savedItems = prefs.getStringList('favoriteItems');

    if (savedItems == null || savedItems.isEmpty) return;

    final List<dynamic> loaded = [];

    for (final jsonString in savedItems) {
      try {
        final decoded = jsonDecode(jsonString);

        if (decoded is! Map<String, dynamic>) continue;

        final type = decoded['type'];
        final dataRaw = decoded['data'];

        // ✅ data قد تكون Map أو String
        final Map<String, dynamic> dataMap = _ensureMap(dataRaw);

        if (type == 'coupon') {
          loaded.add(Coupon.fromJson(dataMap, 'ar'));
        } else if (type == 'offer') {
          loaded.add(Offer.fromJson(dataMap, 'ar'));
        } else {
          // نوع غير معروف: نتجاهله
          continue;
        }
      } catch (e) {
        // ✅ لا نرمي Exception حتى لا ينهار التطبيق
        debugPrint('Failed to load favorite item: $e');
        continue;
      }
    }

    _favoriteItems
      ..clear()
      ..addAll(loaded);

    notifyListeners();
  }

  // ---------------------------
  // Helpers
  // ---------------------------
  Map<String, dynamic> _ensureMap(dynamic data) {
    if (data == null) return <String, dynamic>{};

    if (data is Map<String, dynamic>) return data;

    // أحيانًا تكون Map لكن dynamic
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }

    // أحيانًا تكون String JSON
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
