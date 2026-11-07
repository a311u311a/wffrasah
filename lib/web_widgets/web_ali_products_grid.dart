import 'package:flutter/material.dart';

import '../models/ali_product.dart';
import '../services/ali_products_service.dart';
import '../widgets/ali_product_card.dart';
import 'responsive_layout.dart';

/// شبكة منتجات علي إكسبرس للموقع. الصورة مربعة بعرض البطاقة،
/// والباقي (العنوان والسعر والزر) ارتفاعه ثابت.
class WebAliProductsGrid extends StatelessWidget {
  final List<AliProduct> items;

  /// أقصى عدد صفوف يُعرض (null = الكل).
  final int? maxRows;

  const WebAliProductsGrid({super.key, required this.items, this.maxRows});

  static int columnsForWidth(double width) => (width / 200).floor().clamp(2, 6);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = columnsForWidth(width);
        final spacing = ResponsiveGrid.spacingForWidth(width);
        final cellWidth = (width - spacing * (columns - 1)) / columns;
        final visible =
            maxRows == null ? items : items.take(columns * maxRows!).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: cellWidth + 140,
          ),
          itemBuilder: (context, i) => AliProductCard(product: visible[i]),
        );
      },
    );
  }
}

/// قسم عروض علي إكسبرس في الصفحة الرئيسية للموقع. يتبع الفئة المختارة
/// ويختفي بالكامل (مع الإطار والعنوان) إذا ما فيه منتجات.
class WebAliProductsSection extends StatefulWidget {
  final String? categoryId;
  final Widget Function(Widget child) shellBuilder;

  const WebAliProductsSection({
    super.key,
    required this.categoryId,
    required this.shellBuilder,
  });

  @override
  State<WebAliProductsSection> createState() => _WebAliProductsSectionState();
}

class _WebAliProductsSectionState extends State<WebAliProductsSection> {
  late Future<List<AliProduct>> _future;

  @override
  void initState() {
    super.initState();
    _future =
        AliProductsService.fetch(categoryId: widget.categoryId, limit: 12);
  }

  @override
  void didUpdateWidget(covariant WebAliProductsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      _future =
          AliProductsService.fetch(categoryId: widget.categoryId, limit: 12);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AliProduct>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AliProduct>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 34),
          child: widget.shellBuilder(
            WebAliProductsGrid(items: items, maxRows: 2),
          ),
        );
      },
    );
  }
}
