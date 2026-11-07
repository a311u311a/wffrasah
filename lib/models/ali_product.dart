/// منتج من علي إكسبرس (جدول ali_products) يتحدّث يومياً من دالة aliexpress-sync.
class AliProduct {
  final int productId;
  final String categoryId;
  final String title;
  final String image;
  final double? salePrice;
  final double? originalPrice;
  final int? discountPercent;
  final String currency;
  final double? commissionRate;
  final String promotionLink;
  final int ordersCount;
  final double? rating;

  const AliProduct({
    required this.productId,
    required this.categoryId,
    required this.title,
    required this.image,
    required this.salePrice,
    required this.originalPrice,
    required this.discountPercent,
    required this.currency,
    required this.commissionRate,
    required this.promotionLink,
    required this.ordersCount,
    required this.rating,
  });

  bool get hasDiscount =>
      (discountPercent ?? 0) > 0 &&
      originalPrice != null &&
      salePrice != null &&
      originalPrice! > salePrice!;

  factory AliProduct.fromMap(Map<String, dynamic> m) {
    double? d(dynamic v) => v == null ? null : double.tryParse(v.toString());
    int? i(dynamic v) => v == null ? null : num.tryParse(v.toString())?.round();

    return AliProduct(
      productId: i(m['product_id']) ?? 0,
      categoryId: (m['category_id'] ?? '').toString(),
      title: (m['title'] ?? '').toString().trim(),
      image: (m['image'] ?? '').toString(),
      salePrice: d(m['sale_price']),
      originalPrice: d(m['original_price']),
      discountPercent: i(m['discount_percent']),
      currency: (m['currency'] ?? 'SAR').toString(),
      commissionRate: d(m['commission_rate']),
      promotionLink: (m['promotion_link'] ?? '').toString(),
      ordersCount: i(m['orders_count']) ?? 0,
      rating: d(m['rating']),
    );
  }

  /// "44.18" أو "44" إذا كان السعر بدون كسور.
  static String formatPrice(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}
