import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ali_category.dart';
import '../models/ali_product.dart';

/// يقرأ منتجات علي إكسبرس من جدول ali_category_products وفئاتها من
/// ali_categories (منفصلة عن فئات المتاجر). الجداول تتحدّث كل 6 ساعات،
/// فنحتفظ بالنتائج في الذاكرة لمدة قصيرة.
class AliProductsService {
  static const _productsTable = 'ali_category_products';
  static const _cacheTtl = Duration(minutes: 15);
  static final Map<String, _CacheEntry> _cache = {};

  static List<AliCategory>? _categories;
  static DateTime? _categoriesAt;

  /// الفئات المفعّلة اللي فيها منتجات، بالترتيب المحدد في لوحة التحكم.
  static Future<List<AliCategory>> fetchCategories({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _categories != null &&
        DateTime.now().difference(_categoriesAt!) < _cacheTtl) {
      return _categories!;
    }
    try {
      final client = Supabase.instance.client;
      final results = await Future.wait([
        client
            .from('ali_categories')
            .select('id, name_ar, name_en, icon, sort_order')
            .eq('active', true)
            .order('sort_order', ascending: true),
        client.from('ali_category_counts').select('id').gt('products', 0),
      ]);
      final withProducts =
          (results[1] as List).map((r) => (r['id'] ?? '').toString()).toSet();
      _categories = (results[0] as List)
          .map((r) => AliCategory.fromMap(Map<String, dynamic>.from(r)))
          .where((c) => withProducts.contains(c.id))
          .toList();
      _categoriesAt = DateTime.now();
      return _categories!;
    } catch (e) {
      debugPrint('AliProductsService.fetchCategories error: $e');
      return _categories ?? const [];
    }
  }

  /// [categoryId] فارغ = أفضل المنتجات من كل الفئات.
  static Future<List<AliProduct>> fetch({
    String? categoryId,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final key = '${categoryId ?? '*'}:$limit';
    final cached = _cache[key];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.at) < _cacheTtl) {
      return cached.items;
    }

    try {
      var query = Supabase.instance.client.from(_productsTable).select(
          'product_id, category_id, title, image, sale_price, original_price, '
          'discount_percent, currency, commission_rate, promotion_link, '
          'orders_count, rating');
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }
      final all = categoryId == null || categoryId.isEmpty;
      // "الكل": نطلب أكثر بكثير ثم نخلط بالتناوب بين الفئات، حتى لا تطغى
      // فئة واحدة (مثل الشواحن) على الصفحة.
      final rows = await query
          .order('sort_score', ascending: false)
          .limit(all ? (limit * 6).clamp(200, 600) : limit);

      final seen = <int>{};
      final items = <AliProduct>[];
      for (final row in all ? _interleaveByCategory(rows) : rows) {
        final p = AliProduct.fromMap(row);
        if (p.productId == 0 ||
            p.promotionLink.isEmpty ||
            !seen.add(p.productId)) {
          continue;
        }
        items.add(p);
        if (items.length >= limit) break;
      }

      _cache[key] = _CacheEntry(items, DateTime.now());
      return items;
    } catch (e) {
      debugPrint('AliProductsService.fetch error: $e');
      return cached?.items ?? const [];
    }
  }

  /// يرتب الصفوف بالتناوب بين الفئات مع الحفاظ على ترتيب كل فئة.
  static List<Map<String, dynamic>> _interleaveByCategory(List rows) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      final row = Map<String, dynamic>.from(r);
      groups
          .putIfAbsent((row['category_id'] ?? '').toString(), () => [])
          .add(row);
    }
    final lists = groups.values.toList();
    final out = <Map<String, dynamic>>[];
    for (var i = 0; out.length < rows.length; i++) {
      for (final list in lists) {
        if (i < list.length) out.add(list[i]);
      }
    }
    return out;
  }

  /// يمسح الذاكرة المؤقتة (بعد تعديل الفئات من لوحة التحكم).
  static void clearCache() {
    _cache.clear();
    _categories = null;
  }
}

class _CacheEntry {
  final List<AliProduct> items;
  final DateTime at;
  _CacheEntry(this.items, this.at);
}
