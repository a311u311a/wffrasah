import 'package:flutter/material.dart';

import '../models/ali_product.dart';
import '../services/ali_products_service.dart';
import 'ali_product_card.dart';

/// شريط أفقي لمنتجات علي إكسبرس في الصفحة الرئيسية.
/// يتبع الفئة المختارة، ويختفي بالكامل (مع العنوان) إذا ما فيه منتجات.
class AliProductsSection extends StatefulWidget {
  final String? categoryId;
  final Widget header;

  const AliProductsSection({
    super.key,
    required this.categoryId,
    required this.header,
  });

  @override
  State<AliProductsSection> createState() => _AliProductsSectionState();
}

class _AliProductsSectionState extends State<AliProductsSection> {
  late Future<List<AliProduct>> _future;

  @override
  void initState() {
    super.initState();
    _future = AliProductsService.fetch(categoryId: widget.categoryId);
  }

  @override
  void didUpdateWidget(covariant AliProductsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      _future = AliProductsService.fetch(categoryId: widget.categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AliProduct>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AliProduct>[];
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.header,
            const SizedBox(height: 12),
            SizedBox(
              height: 292,
              // RTL حتى يبدأ الشريط من اليمين مثل باقي أقسام الصفحة.
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) =>
                      AliProductCard(product: items[i], width: 156),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const AliAffiliateNote(),
          ],
        );
      },
    );
  }
}
