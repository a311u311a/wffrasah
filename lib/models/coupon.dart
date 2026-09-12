import 'dart:convert';

class Coupon {
  final String id;
  final String storeId;

  final String code;

  final String name;
  final String description;

  final String nameAr;
  final String nameEn;

  final String descriptionAr;
  final String descriptionEn;

  final String image;
  final String web;

  final String storeName;
  final String storeNameAr;
  final String storeNameEn;
  final String storeImage;
  final String? discountPercent;
  final String couponType;
  final String terms;
  final String termsAr;
  final String termsEn;
  final bool isActive;
  final DateTime? lastUsedAt;

  final List<String> tags;

  final DateTime? createdAt;
  final DateTime? expiryDate;

  Coupon({
    required this.id,
    required this.storeId,
    required this.code,
    required this.name,
    required this.description,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.image,
    required this.web,
    required this.storeName,
    required this.storeNameAr,
    required this.storeNameEn,
    required this.storeImage,
    required this.discountPercent,
    required this.couponType,
    required this.terms,
    required this.termsAr,
    required this.termsEn,
    required this.isActive,
    this.lastUsedAt,
    required this.tags,
    required this.createdAt,
    this.expiryDate,
  });

  /// من Supabase (DB) مع اختيار الاسم/الوصف حسب اللغة
  factory Coupon.fromSupabase(Map<String, dynamic> row, String langCode) {
    final isAr = (langCode.toLowerCase() == 'ar');

    final id = _asString(row['id']);
    final storeId = _asString(row['store_id']);

    final code = _asString(row['code']);

    final nameAr = _asString(row['name_ar'] ?? row['name']);
    final nameEn = _asString(row['name_en'] ?? row['name']);

    final descAr = _asString(row['description_ar'] ?? row['description']);
    final descEn = _asString(row['description_en'] ?? row['description']);

    final image = _asString(row['image']);
    final web = _asString(row['web']);

    final storeNameAr = _asString(row['store_name_ar'] ?? row['store_name']);
    final storeNameEn = _asString(row['store_name_en'] ?? row['store_name']);
    final storeImage = _asString(row['store_image']);
    final discountPercent = _asString(row['discount_percent']);
    final couponType = _normalizeCouponType(row['coupon_type']);
    final termsAr = _asString(row['terms_ar'] ?? row['terms']);
    final termsEn = _asString(row['terms_en'] ?? row['terms']);
    final isActive = _parseBool(row['is_active'], fallback: true);
    final lastUsedAt = _parseDate(row['last_used_at']);

    final tags = _parseTags(row['tags']);

    final createdAt = _parseDate(row['created_at']);
    final expiryDate = _parseDate(row['expiry_date']);

    final displayName = isAr
        ? (nameAr.isNotEmpty ? nameAr : nameEn)
        : (nameEn.isNotEmpty ? nameEn : nameAr);

    final displayDesc = isAr
        ? (descAr.isNotEmpty ? descAr : descEn)
        : (descEn.isNotEmpty ? descEn : descAr);

    final displayStoreName = isAr
        ? (storeNameAr.isNotEmpty ? storeNameAr : storeNameEn)
        : (storeNameEn.isNotEmpty ? storeNameEn : storeNameAr);

    final displayTerms = isAr
        ? (termsAr.isNotEmpty ? termsAr : termsEn)
        : (termsEn.isNotEmpty ? termsEn : termsAr);

    return Coupon(
      id: id,
      storeId: storeId,
      code: code,
      name: displayName,
      description: displayDesc,
      nameAr: nameAr,
      nameEn: nameEn,
      descriptionAr: descAr,
      descriptionEn: descEn,
      image: image,
      web: web,
      storeName: displayStoreName,
      storeNameAr: storeNameAr,
      storeNameEn: storeNameEn,
      storeImage: storeImage,
      discountPercent: discountPercent,
      couponType: couponType,
      terms: displayTerms,
      termsAr: termsAr,
      termsEn: termsEn,
      isActive: isActive,
      lastUsedAt: lastUsedAt,
      tags: tags,
      createdAt: createdAt,
      expiryDate: expiryDate,
    );
  }

  /// من JSON (للمفضلة/التخزين المحلي)
  /// نفس فكرة fromSupabase لكن المصدر Map جاهز.
  factory Coupon.fromJson(Map<String, dynamic> json, String langCode) {
    // نستخدم fromSupabase لأن المنطق نفسه + مقاومة الأخطاء
    return Coupon.fromSupabase(json, langCode);
  }

  /// تحويل لـ JSON (للمفضلة/التخزين المحلي)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'code': code,

      // نخزن النسختين عشان ما نفقد الترجمة
      'name': name,
      'description': description,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,

      'image': image,
      'web': web,
      'store_name': storeName,
      'store_name_ar': storeNameAr,
      'store_name_en': storeNameEn,
      'store_image': storeImage,
      'discount_percent': discountPercent,
      'coupon_type': couponType,
      'terms': terms,
      'terms_ar': termsAr,
      'terms_en': termsEn,
      'is_active': isActive,
      'last_used_at': lastUsedAt?.toIso8601String(),
      'tags': tags, // نخزنها كـ List
      'created_at': createdAt?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }

  // -------------------------
  // Helpers (safe parsing)
  // -------------------------

  static String _asString(dynamic v) {
    if (v == null) return '';
    return v.toString().trim();
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;

    final s = v.toString().trim();
    if (s.isEmpty) return null;

    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  static bool _parseBool(dynamic v, {required bool fallback}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is num) return v != 0;

    final s = v.toString().trim().toLowerCase();
    if (s.isEmpty) return fallback;
    if (['true', 't', 'yes', 'y', '1'].contains(s)) return true;
    if (['false', 'f', 'no', 'n', '0'].contains(s)) return false;

    return fallback;
  }

  static String _normalizeCouponType(dynamic v) {
    final value = _asString(v).toLowerCase();
    if (value == 'رصيد مسترجع' ||
        value == 'رصيد' ||
        value == 'cash back' ||
        value == 'cash-back') {
      return 'cashback';
    }
    if (value == 'عرض' || value == 'offer') return 'offer';
    if (value == 'خصم إضافي' ||
        value == 'خصم اضافي' ||
        value == 'extra discount' ||
        value == 'extra_discount') {
      return 'extra_discount';
    }
    if (value == 'خصم' || value == 'كوبون خصم') return 'coupon';
    if (value == 'cashback' || value == 'offer' || value == 'extra_discount') {
      return value;
    }
    return 'coupon';
  }

  /// يدعم tags كـ:
  /// - `List<dynamic>`
  /// - String JSON مثل '["a","b"]'
  /// - String CSV مثل 'a,b,c'
  /// - null
  static List<String> _parseTags(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (value is String) {
      final v = value.trim();
      if (v.isEmpty) return [];

      if (v.startsWith('[')) {
        try {
          final decoded = jsonDecode(v);
          if (decoded is List) {
            return decoded
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
          return [];
        } catch (_) {
          // إذا فشل JSON decode نعاملها كـ CSV
        }
      }

      return v
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }
}
