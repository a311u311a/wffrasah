import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ali_product.dart';

/// يقرأ منتجات علي إكسبرس من جدول ali_products.
/// الجدول يتحدّث مرة يومياً، فنحتفظ بالنتائج في الذاكرة لمدة قصيرة.
class AliProductsService {
  static const _cacheTtl = Duration(minutes: 15);
  static final Map<String, _CacheEntry> _cache = {};

  static Set<String>? _categoryIds;
  static DateTime? _categoryIdsAt;

  /// الفئات اللي فيها منتجات حالياً (من view ali_product_categories)،
  /// عشان نخفي الفئات الفاضية في شاشة العروض.
  static Future<Set<String>> fetchCategoryIds({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _categoryIds != null &&
        DateTime.now().difference(_categoryIdsAt!) < _cacheTtl) {
      return _categoryIds!;
    }
    try {
      final rows = await Supabase.instance.client
          .from('ali_product_categories')
          .select('category_id')
          .gt('products', 0);
      _categoryIds = rows
          .map((r) => (r['category_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
      _categoryIdsAt = DateTime.now();
      return _categoryIds!;
    } catch (e) {
      debugPrint('AliProductsService.fetchCategoryIds error: $e');
      return _categoryIds ?? <String>{};
    }
  }

  /// [categoryId] فارغ = أفضل المنتجات من كل الأقسام.
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
      var query = Supabase.instance.client.from('ali_products').select(
          'product_id, category_id, title, image, sale_price, original_price, '
          'discount_percent, currency, commission_rate, promotion_link, '
          'orders_count, rating');
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }
      // نطلب أكثر من المطلوب لأن المنتج نفسه قد يتكرر في أكثر من قسم.
      final rows = await query
          .order('sort_score', ascending: false)
          .limit(categoryId == null ? limit * 2 : limit);

      final seen = <int>{};
      final items = <AliProduct>[];
      for (final row in rows) {
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
}

class _CacheEntry {
  final List<AliProduct> items;
  final DateTime at;
  _CacheEntry(this.items, this.at);
}
