import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../widgets/app_responsive.dart';
import '../widgets/stores_list.dart';
import '../widgets/carouse.dart';
import '../widgets/category_list.dart';
import '../models/coupon.dart';
import '../models/offers.dart';
import '../models/store.dart';
import '../services/home_data_service.dart';
import '../services/unified_search_service.dart';
import '../widgets/coupon_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/search_widget.dart';
import 'coupon_screen.dart';
import 'stores_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _homeBg = Color(0xFFF8F8FD);
  static const Color _ink = Color.fromARGB(255, 62, 57, 156);

  String? selectedStoreId;
  String? selectedCategoryId;
  String searchQuery = ''; // نص البحث
  _HomeSearchFilter selectedSearchFilter = _HomeSearchFilter.all;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final storeItemExtent = AppResponsive.isTablet(context) ? 88.0 : 76.0;

    return Scaffold(
      resizeToAvoidBottomInset: false, // يمنع انضغاط الواجهة عند ظهور الكيبورد
      backgroundColor: _homeBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 80,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Constants.primaryColor.withValues(alpha: 0.08),
                _homeBg,
              ],
            ),
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: _HomeHeader(
          localizations: localizations,
          onSearchChanged: (value) {
            setState(() {
              searchQuery = value;
              if (value.trim().isEmpty) {
                selectedSearchFilter = _HomeSearchFilter.all;
              }
            });
          },
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Constants.primaryColor.withValues(alpha: 0.08),
              _homeBg,
            ],
            stops: const [0.0, 0.1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 2, 10, 8),
                  children: searchQuery.trim().isNotEmpty
                      ? [
                          _HomeUnifiedSearchResults(
                            selectedCategoryId: selectedCategoryId,
                            searchQuery: searchQuery,
                            selectedFilter: selectedSearchFilter,
                            onFilterSelected: (filter) {
                              setState(() => selectedSearchFilter = filter);
                            },
                          ),
                          const SizedBox(height: 132),
                        ]
                      : [
                          const CustomCarousel(),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: CategoryList.preferredHeight(context),
                            child: CategoryList(
                              selectedCategoryId: selectedCategoryId,
                              onCategorySelected: (categoryId) {
                                setState(() {
                                  selectedCategoryId = categoryId;
                                  selectedStoreId = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          _HomeSectionHeader(
                            title: 'المتاجر',
                            icon: Icons.storefront_rounded,
                            actionText: 'عرض الكل',
                            onActionTap: () => _openPage(
                              const BottomNavBar(initialIndex: 0),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: storeItemExtent + 16,
                            child: StoresList(
                              selectedStoreId: selectedStoreId,
                              selectedCategoryId: selectedCategoryId,
                              itemExtent: storeItemExtent,
                              useBottomSelectionIndicator: true,
                              onStoreSelected: (storeId) {
                                setState(() {
                                  selectedStoreId = storeId;
                                  selectedCategoryId = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 22),
                          _HomeSectionHeader(
                            title: 'أحدث الكوبونات والعروض',
                            icon: Icons.confirmation_number_rounded,
                            actionText: null,
                            onActionTap: () => _openPage(const CouponScreen()),
                          ),
                          const SizedBox(height: 12),
                          _HomeDealsList(
                            selectedCategoryId: selectedCategoryId,
                            selectedStoreId: selectedStoreId,
                            searchQuery: searchQuery,
                          ),
                          const SizedBox(height: 22),
                          _HomeSectionHeader(
                            title: 'الأكثر استخدامًا',
                            icon: Icons.trending_up_rounded,
                            actionText: null,
                            onActionTap: null,
                          ),
                          const SizedBox(height: 10),
                          const _MostUsedCouponsList(),
                          const SizedBox(height: 132),
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

enum _HomeSearchFilter { all, stores, coupons, offers }

class _HomeDeal {
  final Coupon? coupon;
  final Offer? offer;
  final DateTime createdAt;

  const _HomeDeal.coupon(this.coupon, this.createdAt) : offer = null;
  const _HomeDeal.offer(this.offer, this.createdAt) : coupon = null;
}

class _MostUsedCouponsList extends StatefulWidget {
  const _MostUsedCouponsList();

  @override
  State<_MostUsedCouponsList> createState() => _MostUsedCouponsListState();
}

class _MostUsedCouponsListState extends State<_MostUsedCouponsList> {
  Future<List<Coupon>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _fetchCoupons();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Coupon>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomLoadingIndicator(
            message: 'جاري تجهيز الأكثر استخدامًا',
            itemCount: 2,
            padding: EdgeInsets.symmetric(vertical: 4),
          );
        }

        if (snapshot.hasError) {
          return const _HomeEmptyState(
            text: 'لا توجد كوبونات مستخدمة حالياً',
          );
        }

        final coupons = snapshot.data ?? [];
        if (coupons.isEmpty) {
          return const _HomeEmptyState(
            text: 'لا توجد كوبونات مستخدمة حالياً',
          );
        }

        final screenWidth = MediaQuery.sizeOf(context).width;
        final cardWidth = AppResponsive.isTablet(context)
            ? 390.0
            : (screenWidth - 42).clamp(312.0, 348.0);
        final cardHeight = AppResponsive.isTablet(context) ? 118.0 : 112.0;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            height: (cardHeight * 2) + 14,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              itemCount: coupons.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: cardWidth,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                return CouponCard(
                  coupon: coupons[index],
                  margin: EdgeInsets.zero,
                  height: cardHeight,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<List<Coupon>> _fetchCoupons() async {
    final langCode = Localizations.localeOf(context).languageCode;
    try {
      // This section must reflect a new copy immediately after testing.
      var rows = await HomeDataService.fetchMostUsedCoupons(
        limit: 6,
        forceRefresh: true,
      );
      if (rows.isEmpty) {
        final homeRows = await HomeDataService.fetchMobileDealsData(
          allForStore: false,
          forceRefresh: true,
        );
        rows = homeRows.coupons.take(6).toList();
      }
      if (rows.isEmpty) {
        // Last fallback: load the public rows directly, without relying on
        // approval/status columns that may differ between deployments.
        try {
          rows = await Supabase.instance.client
              .from('coupons')
              .select('*')
              .order('created_at', ascending: false)
              .limit(6);
        } catch (_) {
          rows = const [];
        }
      }

      List<Map<String, dynamic>> storesData = const [];
      try {
        storesData = await HomeDataService.fetchStores();
      } catch (_) {
        storesData = const [];
      }
      final storesByKey = _storesByKey(storesData, langCode);

      final coupons = <Coupon>[];
      for (final row in rows) {
        try {
          final storeId =
              (row['store_id'] ?? row['storeId'] ?? '').toString().trim();
          final store = storesByKey[storeId.toLowerCase()];
          final coupon = Coupon.fromSupabase(
            _withStoreData(row, store, langCode),
            langCode,
          );
          if (coupon.id.trim().isNotEmpty) coupons.add(coupon);
        } catch (_) {
          // Ignore one malformed row and keep the remaining coupons visible.
        }
      }
      return coupons;
    } catch (_) {
      return const <Coupon>[];
    }
  }

  Map<String, Store> _storesByKey(
    List<Map<String, dynamic>> rows,
    String langCode,
  ) {
    final storesByKey = <String, Store>{};
    for (final row in rows) {
      final store = Store.fromSupabase(row, langCode);
      for (final key in [
        store.id,
        store.slug,
        store.name,
        store.nameAr,
        store.nameEn,
      ]) {
        final normalized = key.trim().toLowerCase();
        if (normalized.isNotEmpty) storesByKey[normalized] = store;
      }
    }
    return storesByKey;
  }

  Map<String, dynamic> _withStoreData(
    Map<String, dynamic> row,
    Store? store,
    String langCode,
  ) {
    if (store == null) return row;
    final displayName = langCode == 'en' ? store.nameEn : store.nameAr;
    return {
      ...row,
      'store_display_name': displayName,
      'store_name': displayName,
      'store_name_ar': store.nameAr,
      'store_name_en': store.nameEn,
      'store_image': store.image,
    };
  }
}

class _HomeUnifiedSearchResults extends StatefulWidget {
  final String? selectedCategoryId;
  final String searchQuery;
  final _HomeSearchFilter selectedFilter;
  final ValueChanged<_HomeSearchFilter> onFilterSelected;

  const _HomeUnifiedSearchResults({
    required this.selectedCategoryId,
    required this.searchQuery,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  State<_HomeUnifiedSearchResults> createState() =>
      _HomeUnifiedSearchResultsState();
}

class _HomeUnifiedSearchResultsState extends State<_HomeUnifiedSearchResults> {
  late Future<_HomeSearchData> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = _fetchSearchData();
  }

  @override
  void didUpdateWidget(covariant _HomeUnifiedSearchResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      setState(() {
        _future = _fetchSearchData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeSearchData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomLoadingIndicator(
            message: 'جاري تجهيز نتائج البحث',
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const _HomeEmptyState(text: 'لا توجد نتائج مطابقة لبحثك');
        }

        final data = snapshot.data!;
        final results = UnifiedSearchService.search(
          query: widget.searchQuery,
          stores: data.stores,
          coupons: data.coupons,
          offers: data.offers,
          selectedCategoryId: widget.selectedCategoryId,
        );

        if (results.isEmpty) {
          return const _HomeEmptyState(text: 'لا توجد نتائج مطابقة لبحثك');
        }

        final bool showStores = _shouldShowSection(_HomeSearchFilter.stores) &&
            results.stores.isNotEmpty;
        final bool showCoupons =
            _shouldShowSection(_HomeSearchFilter.coupons) &&
                results.coupons.isNotEmpty;
        final bool showOffers = _shouldShowSection(_HomeSearchFilter.offers) &&
            results.offers.isNotEmpty;
        final bool hasVisibleSections = showStores || showCoupons || showOffers;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HomeSearchFilterBar(
                selectedFilter: widget.selectedFilter,
                storesCount: results.stores.length,
                couponsCount: results.coupons.length,
                offersCount: results.offers.length,
                onFilterSelected: widget.onFilterSelected,
              ),
              const SizedBox(height: 12),
              if (!hasVisibleSections)
                const _HomeEmptyState(text: 'لا توجد نتائج مطابقة لبحثك'),
              if (showStores)
                _SearchResultSection(
                  title: 'متاجر',
                  icon: Icons.storefront_rounded,
                  count: results.stores.length,
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: results.stores.take(6).length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: AppResponsive.isTablet(context) ? 5 : 3,
                      crossAxisSpacing:
                          AppResponsive.isTablet(context) ? 18 : 12,
                      mainAxisSpacing:
                          AppResponsive.isTablet(context) ? 22 : 16,
                      childAspectRatio:
                          AppResponsive.isTablet(context) ? 0.96 : 0.82,
                    ),
                    itemBuilder: (context, index) =>
                        StoreGridCard(store: results.stores[index]),
                  ),
                ),
              if (showStores && (showCoupons || showOffers))
                const SizedBox(height: 14),
              if (showCoupons)
                _SearchResultSection(
                  title: 'كوبونات',
                  icon: Icons.confirmation_number_rounded,
                  count: results.coupons.length,
                  child: _SearchDealsList(
                    itemCount: results.coupons.take(8).length,
                    itemBuilder: (context, index) => CouponCard(
                      coupon: results.coupons[index],
                      margin: EdgeInsets.zero,
                    ),
                  ),
                ),
              if (showCoupons && showOffers) const SizedBox(height: 14),
              if (showOffers)
                _SearchResultSection(
                  title: 'عروض',
                  icon: Icons.local_offer_rounded,
                  count: results.offers.length,
                  child: _SearchDealsList(
                    itemCount: results.offers.take(8).length,
                    itemBuilder: (context, index) => CouponCard(
                      coupon: _couponFromOffer(results.offers[index]),
                      margin: EdgeInsets.zero,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _shouldShowSection(_HomeSearchFilter filter) {
    return widget.selectedFilter == _HomeSearchFilter.all ||
        widget.selectedFilter == filter;
  }

  Future<_HomeSearchData> _fetchSearchData() async {
    final langCode = Localizations.localeOf(context).languageCode;
    final rows = await HomeDataService.fetchMobileDealsData(
      allForStore: true,
    );
    final stores = rows.stores
        .where((item) {
          final importSource = (item['import_source'] ?? 'manual').toString();
          final approvalStatus =
              (item['approval_status'] ?? 'approved').toString();
          return importSource == 'manual' || approvalStatus == 'approved';
        })
        .map((item) => Store.fromSupabase(item, langCode))
        .toList();
    final storesByKey = _storesByKey(stores);

    final coupons = rows.coupons
        .map((item) {
          final storeId =
              (item['store_id'] ?? item['storeId'] ?? '').toString().trim();
          final store = storesByKey[storeId.toLowerCase()];
          return Coupon.fromSupabase(
              _withStoreData(item, store, langCode), langCode);
        })
        .where((coupon) => coupon.id.trim().isNotEmpty)
        .toList();

    final offers = rows.offers
        .map((item) {
          final storeId =
              (item['store_id'] ?? item['storeId'] ?? '').toString().trim();
          final store = storesByKey[storeId.toLowerCase()];
          return Offer.fromSupabase(
              _withStoreData(item, store, langCode), langCode);
        })
        .where((offer) => offer.id.trim().isNotEmpty)
        .toList();

    return _HomeSearchData(
      stores: stores,
      coupons: coupons,
      offers: offers,
    );
  }

  Map<String, Store> _storesByKey(List<Store> stores) {
    final map = <String, Store>{};
    for (final store in stores) {
      for (final key in [
        store.id,
        store.slug,
        store.key,
        store.name,
        store.nameAr,
        store.nameEn,
      ]) {
        final normalized = key.trim().toLowerCase();
        if (normalized.isNotEmpty) map[normalized] = store;
      }
    }
    return map;
  }

  Map<String, dynamic> _withStoreData(
    Map<String, dynamic> row,
    Store? store,
    String langCode,
  ) {
    if (store == null) return row;
    final displayName = langCode == 'en' ? store.nameEn : store.nameAr;
    return {
      ...row,
      'store_display_name': displayName,
      'store_name': displayName,
      'store_name_ar': store.nameAr,
      'store_name_en': store.nameEn,
      'store_image': store.image,
    };
  }

  Coupon _couponFromOffer(Offer offer) {
    final storeName = offer.storeName.trim().isNotEmpty
        ? offer.storeName.trim()
        : offer.storeId.trim();
    final storeNameAr = offer.storeNameAr.trim().isNotEmpty
        ? offer.storeNameAr.trim()
        : storeName;
    final storeNameEn = offer.storeNameEn.trim().isNotEmpty
        ? offer.storeNameEn.trim()
        : storeName;

    return Coupon(
      id: offer.id,
      storeId: offer.storeId,
      code: offer.code,
      name: offer.name,
      description: offer.description,
      nameAr: offer.nameAr,
      nameEn: offer.nameEn,
      descriptionAr: offer.descriptionAr,
      descriptionEn: offer.descriptionEn,
      image: offer.image,
      web: offer.web,
      storeName: storeName,
      storeNameAr: storeNameAr,
      storeNameEn: storeNameEn,
      storeImage: offer.storeImage,
      discountPercent: null,
      couponType: 'offer',
      terms: '',
      termsAr: '',
      termsEn: '',
      isActive: true,
      tags: offer.tags,
      createdAt: offer.createdAt,
      expiryDate: offer.expiryDate,
    );
  }
}

class _HomeSearchData {
  final List<Store> stores;
  final List<Coupon> coupons;
  final List<Offer> offers;

  const _HomeSearchData({
    required this.stores,
    required this.coupons,
    required this.offers,
  });
}

class _HomeSearchFilterBar extends StatelessWidget {
  final _HomeSearchFilter selectedFilter;
  final int storesCount;
  final int couponsCount;
  final int offersCount;
  final ValueChanged<_HomeSearchFilter> onFilterSelected;

  const _HomeSearchFilterBar({
    required this.selectedFilter,
    required this.storesCount,
    required this.couponsCount,
    required this.offersCount,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      _HomeSearchFilterItem(
        filter: _HomeSearchFilter.all,
        label: 'الكل',
        count: storesCount + couponsCount + offersCount,
        icon: Icons.apps_rounded,
      ),
      _HomeSearchFilterItem(
        filter: _HomeSearchFilter.stores,
        label: 'متاجر',
        count: storesCount,
        icon: Icons.storefront_rounded,
      ),
      _HomeSearchFilterItem(
        filter: _HomeSearchFilter.coupons,
        label: 'كوبونات',
        count: couponsCount,
        icon: Icons.confirmation_number_rounded,
      ),
      _HomeSearchFilterItem(
        filter: _HomeSearchFilter.offers,
        label: 'عروض',
        count: offersCount,
        icon: Icons.local_offer_rounded,
      ),
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final selected = selectedFilter == item.filter;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onFilterSelected(item.filter),
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? Constants.primaryColor
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? Constants.primaryColor
                        : Constants.primaryColor.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? Constants.primaryColor.withValues(alpha: 0.16)
                          : Colors.black.withValues(alpha: 0.025),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 17,
                      color: selected ? Colors.white : Constants.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: selected ? Colors.white : Constants.primaryColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.count}',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? Colors.white.withValues(alpha: 0.82)
                            : Constants.primaryColor.withValues(alpha: 0.70),
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeSearchFilterItem {
  final _HomeSearchFilter filter;
  final String label;
  final int count;
  final IconData icon;

  const _HomeSearchFilterItem({
    required this.filter,
    required this.label,
    required this.count,
    required this.icon,
  });
}

class _SearchResultSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final Widget child;

  const _SearchResultSection({
    required this.title,
    required this.icon,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.09),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: Constants.primaryColor, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _HomeScreenState._ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Constants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SearchDealsGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const _SearchDealsGrid({
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = AppResponsive.isTablet(context)
        ? 390.0
        : (screenWidth - 68).clamp(288.0, 336.0);
    final rows = itemCount <= 1 ? 1 : 2;
    final rowHeight = AppResponsive.isTablet(context) ? 147.0 : 143.0;
    final gridHeight = (rowHeight * rows) + (rows > 1 ? 10 : 0);
    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: rows,
          mainAxisExtent: cardWidth,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

class _SearchDealsList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const _SearchDealsList({
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.hardEdge,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: itemBuilder,
    );
  }
}

class _CategoryStoreCouponsFallback extends StatelessWidget {
  final String selectedCategoryId;
  final String message;

  const _CategoryStoreCouponsFallback({
    required this.selectedCategoryId,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Coupon>>(
      future: _fetchCoupons(context),
      builder: (context, snapshot) {
        final coupons = snapshot.data ?? const <Coupon>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomLoadingIndicator(
            message: 'جاري تجهيز كوبونات الفئة',
            itemCount: 1,
            padding: EdgeInsets.symmetric(vertical: 4),
          );
        }

        if (coupons.isEmpty) {
          return _HomeEmptyState(text: message);
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: _SearchDealsGrid(
            itemCount: coupons.length,
            itemBuilder: (context, index) => CouponCard(
              coupon: coupons[index],
              margin: EdgeInsets.zero,
            ),
          ),
        );
      },
    );
  }

  Future<List<Coupon>> _fetchCoupons(BuildContext context) async {
    final langCode = Localizations.localeOf(context).languageCode;
    final rows = await HomeDataService.fetchMobileDealsData(allForStore: true);
    final categoryId = selectedCategoryId.trim();
    final categoryStores = rows.stores
        .map((row) => Store.fromSupabase(row, langCode))
        .where((store) => store.categoryId?.trim() == categoryId)
        .toList();
    final storesByKey = <String, Store>{};
    for (final store in categoryStores) {
      for (final key in [store.id, store.slug, store.key]) {
        final normalized = key.trim().toLowerCase();
        if (normalized.isNotEmpty) storesByKey[normalized] = store;
      }
    }

    final coupons = <Coupon>[];
    for (final row in rows.coupons) {
      final storeId =
          (row['store_id'] ?? row['storeId'] ?? '').toString().trim();
      final store = storesByKey[storeId.toLowerCase()];
      if (store == null) continue;
      final displayName = langCode == 'en' ? store.nameEn : store.nameAr;
      coupons.add(Coupon.fromSupabase({
        ...row,
        'store_display_name': displayName,
        'store_name': displayName,
        'store_name_ar': store.nameAr,
        'store_name_en': store.nameEn,
        'store_image': store.image,
      }, langCode));
    }

    coupons.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return coupons.take(3).toList();
  }
}

class _HomeDealsList extends StatefulWidget {
  final String? selectedCategoryId;
  final String? selectedStoreId;
  final String searchQuery;

  const _HomeDealsList({
    required this.selectedCategoryId,
    required this.selectedStoreId,
    required this.searchQuery,
  });

  @override
  State<_HomeDealsList> createState() => _HomeDealsListState();
}

class _HomeDealsListState extends State<_HomeDealsList> {
  late Future<List<_HomeDeal>> _future;
  bool _didStartLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didStartLoading) {
      _didStartLoading = true;
      _future = _fetchDealsWithRetry();
    }
  }

  @override
  void didUpdateWidget(covariant _HomeDealsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId ||
        oldWidget.selectedStoreId != widget.selectedStoreId) {
      setState(() {
        _future = _fetchDealsWithRetry();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_HomeDeal>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomLoadingIndicator(
            message: 'جاري تجهيز أحدث التوفير',
          );
        }

        if (snapshot.hasError) {
          return _HomeEmptyState(text: 'لا توجد كوبونات أو عروض حالياً');
        }

        final deals = _filterDeals(snapshot.data ?? []);
        if (deals.isEmpty) {
          final hasSelectedStore = widget.selectedStoreId != null &&
              widget.selectedStoreId!.trim().isNotEmpty;
          if (_hasSelectedCategory && !hasSelectedStore) {
            return _CategoryStoreCouponsFallback(
              selectedCategoryId: widget.selectedCategoryId!,
              message: _emptyStateText,
            );
          }
          return _HomeEmptyState(text: _emptyStateText);
        }

        final screenWidth = MediaQuery.sizeOf(context).width;
        final cardWidth = AppResponsive.isTablet(context)
            ? 390.0
            : (screenWidth - 42).clamp(312.0, 348.0);
        final cardHeight = AppResponsive.isTablet(context) ? 118.0 : 112.0;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            height: (cardHeight * 2) + 14,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              itemCount: deals.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: cardWidth,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final deal = deals[index];
                final coupon = deal.coupon ?? _couponFromOffer(deal.offer!);
                return CouponCard(
                  coupon: coupon,
                  margin: EdgeInsets.zero,
                  height: cardHeight,
                );
              },
            ),
          ),
        );
      },
    );
  }

  String get _emptyStateText {
    if (_hasSelectedCategory) {
      return 'لا توجد كوبونات أو عروض لهذه الفئة حالياً';
    }

    return 'لا توجد كوبونات أو عروض حالياً';
  }

  bool get _hasSelectedCategory {
    return widget.selectedCategoryId != null &&
        widget.selectedCategoryId!.trim().isNotEmpty;
  }

  List<_HomeDeal> _filterDeals(List<_HomeDeal> deals) {
    final query = widget.searchQuery.trim().toLowerCase();
    return deals.where((deal) {
      if (query.isEmpty) return true;

      final coupon = deal.coupon;
      if (coupon != null) {
        return coupon.name.toLowerCase().contains(query) ||
            coupon.description.toLowerCase().contains(query) ||
            coupon.code.toLowerCase().contains(query) ||
            coupon.storeName.toLowerCase().contains(query) ||
            coupon.tags.any((tag) => tag.toLowerCase().contains(query));
      }

      final offer = deal.offer;
      if (offer != null) {
        return offer.name.toLowerCase().contains(query) ||
            offer.description.toLowerCase().contains(query) ||
            offer.storeName.toLowerCase().contains(query) ||
            offer.tags.any((tag) => tag.toLowerCase().contains(query));
      }

      return false;
    }).toList();
  }

  Coupon _couponFromOffer(Offer offer) {
    final storeName = offer.storeName.trim().isNotEmpty
        ? offer.storeName.trim()
        : offer.storeId.trim();
    final storeNameAr = offer.storeNameAr.trim().isNotEmpty
        ? offer.storeNameAr.trim()
        : storeName;
    final storeNameEn = offer.storeNameEn.trim().isNotEmpty
        ? offer.storeNameEn.trim()
        : storeName;

    return Coupon(
      id: offer.id,
      storeId: offer.storeId,
      code: offer.code,
      name: offer.name,
      description: offer.description,
      nameAr: offer.nameAr,
      nameEn: offer.nameEn,
      descriptionAr: offer.descriptionAr,
      descriptionEn: offer.descriptionEn,
      image: offer.image,
      web: offer.web,
      storeName: storeName,
      storeNameAr: storeNameAr,
      storeNameEn: storeNameEn,
      storeImage: offer.storeImage,
      discountPercent: null,
      couponType: 'offer',
      terms: '',
      termsAr: '',
      termsEn: '',
      isActive: true,
      tags: offer.tags,
      createdAt: offer.createdAt,
      expiryDate: offer.expiryDate,
    );
  }

  Future<List<_HomeDeal>> _fetchDeals() async {
    final langCode = Localizations.localeOf(context).languageCode;
    final selectedStoreId = widget.selectedStoreId?.trim();
    final hasSelectedStore =
        selectedStoreId != null && selectedStoreId.isNotEmpty;

    final data = await HomeDataService.fetchMobileDealsData(
      allForStore: hasSelectedStore,
    );

    final storesByKey = _storesByKey(data.stores, langCode);
    final deals = <_HomeDeal>[];
    final selectedCategoryId = widget.selectedCategoryId?.trim();
    final shouldFilterByCategory = !hasSelectedStore &&
        selectedCategoryId != null &&
        selectedCategoryId.isNotEmpty;

    for (final row in data.coupons) {
      try {
        final storeId =
            (row['store_id'] ?? row['storeId'] ?? '').toString().trim();
        final store = _findStore(storesByKey, storeId);
        if (!_matchesSelectedStore(storeId, store, selectedStoreId)) continue;

        final enriched = _withStoreData(row, store, langCode);
        final coupon = Coupon.fromSupabase(enriched, langCode);
        final deal = _HomeDeal.coupon(
          coupon,
          coupon.createdAt ?? DateTime(1970),
        );
        if (!shouldFilterByCategory ||
            _matchesSelectedCategory(store, selectedCategoryId)) {
          deals.add(deal);
        }
      } catch (error) {
        // Keep rendering valid rows when one record is malformed.
      }
    }

    for (final row in data.offers) {
      try {
        final storeId =
            (row['store_id'] ?? row['storeId'] ?? '').toString().trim();
        final store = _findStore(storesByKey, storeId);
        if (!_matchesSelectedStore(storeId, store, selectedStoreId)) continue;

        final enriched = _withStoreData(row, store, langCode);
        final offer = Offer.fromSupabase(enriched, langCode);
        final deal = _HomeDeal.offer(
          offer,
          offer.createdAt ?? DateTime(1970),
        );
        if (!shouldFilterByCategory ||
            _matchesSelectedCategory(store, selectedCategoryId)) {
          deals.add(deal);
        }
      } catch (error) {
        // Keep rendering valid rows when one record is malformed.
      }
    }

    deals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return deals;
  }

  Future<List<_HomeDeal>> _fetchDealsWithRetry() async {
    try {
      final firstAttempt = await _fetchDeals();
      if (firstAttempt.isNotEmpty) return firstAttempt;

      await Future<void>.delayed(const Duration(milliseconds: 700));
      return await _fetchDeals();
    } catch (error) {
      return const <_HomeDeal>[];
    }
  }

  Map<String, Store> _storesByKey(
    List<Map<String, dynamic>> rows,
    String langCode,
  ) {
    final storesByKey = <String, Store>{};
    for (final row in rows) {
      final store = Store.fromSupabase(row, langCode);
      for (final key in [
        store.id,
        store.slug,
        store.name,
        store.nameAr,
        store.nameEn,
      ]) {
        final normalized = key.trim().toLowerCase();
        if (normalized.isNotEmpty) storesByKey[normalized] = store;
      }
    }
    return storesByKey;
  }

  Store? _findStore(Map<String, Store> storesByKey, String storeId) {
    final normalized = storeId.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    return storesByKey[normalized];
  }

  bool _matchesSelectedStore(
    String itemStoreId,
    Store? store,
    String? selectedStoreId,
  ) {
    if (selectedStoreId == null || selectedStoreId.isEmpty) return true;

    final selected = selectedStoreId.trim().toLowerCase();
    final itemId = itemStoreId.trim().toLowerCase();
    return itemId == selected ||
        store?.id.trim().toLowerCase() == selected ||
        store?.slug.trim().toLowerCase() == selected ||
        store?.key.trim().toLowerCase() == selected;
  }

  bool _matchesSelectedCategory(Store? store, String? selectedCategoryId) {
    if (selectedCategoryId == null || selectedCategoryId.isEmpty) return true;
    return store?.categoryId?.trim() == selectedCategoryId;
  }

  Map<String, dynamic> _withStoreData(
    Map<String, dynamic> row,
    Store? store,
    String langCode,
  ) {
    if (store == null) return row;
    final displayName = langCode == 'en' ? store.nameEn : store.nameAr;
    return {
      ...row,
      'store_display_name': displayName,
      'store_name': displayName,
      'store_name_ar': store.nameAr,
      'store_name_en': store.nameEn,
      'store_image': store.image,
    };
  }
}

class _HomeEmptyState extends StatelessWidget {
  final String text;

  const _HomeEmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Constants.primaryColor.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6F6A80),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final AppLocalizations? localizations;
  final ValueChanged<String> onSearchChanged;

  const _HomeHeader({
    required this.localizations,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SearchWidget(
        hintText: 'ابحث عن متجر - كوبون - عرض',
        onSearch: onSearchChanged,
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onActionTap;

  const _HomeSectionHeader({
    required this.title,
    required this.icon,
    required this.actionText,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Constants.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Constants.primaryColor.withValues(alpha: 0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: Constants.primaryColor.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Constants.primaryColor, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18.5,
                fontWeight: FontWeight.w900,
                color: _HomeScreenState._ink,
                height: 1.2,
              ),
            ),
          ),
          if (actionText != null && onActionTap != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onActionTap,
                borderRadius: BorderRadius.circular(10),
                child: Ink(
                  height: 48,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                    color: Constants.primaryColor.withValues(alpha: 0.075),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Constants.primaryColor.withValues(alpha: 0.13),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Constants.primaryColor.withValues(alpha: 0.055),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      actionText!,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Constants.primaryColor,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
