import 'dart:convert';

class Offer {
  final String id;
  final String categoryId;

  // ✅ الجديد: ربط العرض بالمتجر (offers.store_id = stores.slug)
  final String storeId;

  final String name;
  final String description;

  final String nameAr;
  final String nameEn;

  final String descriptionAr;
  final String descriptionEn;

  final String web;
  final String image;

  final List<String> tags;
  final DateTime? expiryDate;

  /// ✅ الكود يُخزّن كأول عنصر في tags (اختياري)
  String get code => tags.isNotEmpty ? tags.first : '';

  Offer({
    required this.id,
    required this.categoryId,
    this.storeId = '', // ✅ لا يكسر الكود القديم

    required this.name,
    required this.description,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.web,
    required this.image,
    required this.tags,
    this.expiryDate,
  });

  // ✅ من Supabase
  factory Offer.fromSupabase(Map<String, dynamic> data, String langCode) {
    final isAr = langCode.toLowerCase() == 'ar';

    final nAr = _asString(data['name_ar'] ?? data['name']);
    final nEn = _asString(data['name_en'] ?? data['name']);
    final dAr = _asString(data['description_ar'] ?? data['description']);
    final dEn = _asString(data['description_en'] ?? data['description']);

    return Offer(
      id: _asString(data['id']),
      categoryId: _asString(data['category_id'] ?? data['categoryId']),

      // ✅ مهم جدًا: store_id (slug)
      storeId: _asString(data['store_id'] ?? data['storeId']),

      name: isAr ? (nAr.isNotEmpty ? nAr : nEn) : (nEn.isNotEmpty ? nEn : nAr),
      description:
          isAr ? (dAr.isNotEmpty ? dAr : dEn) : (dEn.isNotEmpty ? dEn : dAr),
      nameAr: nAr,
      nameEn: nEn,
      descriptionAr: dAr,
      descriptionEn: dEn,
      web: _asString(data['web']),
      image: _asString(data['image']),
      tags: _parseTags(data['tags']),
      expiryDate: data['expiry_date'] != null
          ? DateTime.tryParse(data['expiry_date'].toString())
          : null,
    );
  }

  // ✅ للمفضلة/التخزين المحلي
  factory Offer.fromJson(Map<String, dynamic> data, String langCode) {
    return Offer.fromSupabase(data, langCode);
  }

  // ✅ للمفضلة/التخزين المحلي
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'categoryId': categoryId,

      // ✅ نخزنها علشان الفلترة بالمتجر تشتغل محليًا بعد
      'store_id': storeId,
      'storeId': storeId,

      'name': name,
      'description': description,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'web': web,
      'image': image,
      'tags': tags,
      'expiryDate': expiryDate?.toIso8601String(), // For local consistency
      'expiry_date': expiryDate?.toIso8601String(), // For Supabase consistency
    };
  }

  // -------------------------
  // Helpers
  // -------------------------
  static String _asString(dynamic v) {
    if (v == null) return '';
    return v.toString().trim();
  }

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

      // JSON array كنص
      if (v.startsWith('[')) {
        try {
          final decoded = jsonDecode(v);
          if (decoded is List) {
            return decoded
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        } catch (_) {
          // إذا فشل decode نعاملها CSV
        }
      }

      // CSV
      return v
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }
}
