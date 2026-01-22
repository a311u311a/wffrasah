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

  final List<String> tags;

  final DateTime? createdAt;

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
    required this.tags,
    required this.createdAt,
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

    final tags = _parseTags(row['tags']);

    final createdAt = _parseDate(row['created_at']);

    final displayName = isAr
        ? (nameAr.isNotEmpty ? nameAr : nameEn)
        : (nameEn.isNotEmpty ? nameEn : nameAr);

    final displayDesc = isAr
        ? (descAr.isNotEmpty ? descAr : descEn)
        : (descEn.isNotEmpty ? descEn : descAr);

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
      tags: tags,
      createdAt: createdAt,
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
      'tags': tags, // نخزنها كـ List
      'created_at': createdAt?.toIso8601String(),
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

  /// يدعم tags كـ:
  /// - List<dynamic>
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
