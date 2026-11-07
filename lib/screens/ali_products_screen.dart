import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/ali_product.dart';
import '../services/ali_products_service.dart';
import '../widgets/ali_product_card.dart';
import '../widgets/category_list.dart';

/// كل عروض علي إكسبرس، مع فلترة حسب الفئة.
class AliProductsScreen extends StatefulWidget {
  final String? initialCategoryId;

  const AliProductsScreen({super.key, this.initialCategoryId});

  @override
  State<AliProductsScreen> createState() => _AliProductsScreenState();
}

class _AliProductsScreenState extends State<AliProductsScreen> {
  String? _categoryId;
  late Future<List<AliProduct>> _future;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    _load();
  }

  void _load({bool force = false}) {
    _future = AliProductsService.fetch(
      categoryId: _categoryId,
      limit: 60,
      forceRefresh: force,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Constants.textColor,
        title: const Text(
          'عروض علي إكسبرس',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 10),
            SizedBox(
              height: CategoryList.preferredHeight(context),
              child: CategoryList(
                selectedCategoryId: _categoryId,
                activeCategoryIds: AliProductsService.fetchCategoryIds,
                onCategorySelected: (id) {
                  setState(() {
                    _categoryId = id;
                    _load();
                  });
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() => _load(force: true));
                  await _future;
                },
                child: FutureBuilder<List<AliProduct>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data ?? const <AliProduct>[];
                    if (items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Icon(Icons.shopping_bag_outlined,
                              size: 48, color: Constants.disabledTextColor),
                          SizedBox(height: 12),
                          Text(
                            'لا توجد عروض من علي إكسبرس في هذه الفئة حالياً',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Constants.secondaryTextColor,
                            ),
                          ),
                        ],
                      );
                    }
                    final width = MediaQuery.sizeOf(context).width;
                    final columns = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
                    // الصورة مربعة بعرض البطاقة، والباقي (العنوان والسعر والزر) ثابت.
                    final cellWidth = (width - 28 - 12 * (columns - 1)) / columns;
                    final cellHeight = cellWidth + 140;
                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: cellHeight,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) =>
                                  AliProductCard(product: items[i]),
                              childCount: items.length,
                            ),
                          ),
                        ),
                        const SliverPadding(
                          padding: EdgeInsets.fromLTRB(24, 4, 24, 32),
                          sliver: SliverToBoxAdapter(child: AliAffiliateNote()),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
