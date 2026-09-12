import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/carousel.dart';
import '../models/category.dart';
import '../models/coupon.dart';
import '../models/offers.dart';
import '../models/store.dart';
import '../providers/locale_provider.dart';
import '../services/home_data_service.dart';
import '../services/unified_search_service.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_banner_carousel.dart';
import '../web_widgets/web_coupon_card.dart';
import '../web_widgets/web_footer.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_offer_card.dart';

class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  static const Color bg = Color(0xFFF6F7FB);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color stroke = Color(0xFFE5E2F5);
  static const Color ink = Color(0xFF25213B);
  static const Color orange = Color(0xFF6C63FF);
  static const Color pink = Color(0xFF8B84FF);
  static const Color secondary = Color(0xFF68627F);
  static const Color faded = Color(0xFF9B96B6);

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  List<Carousel> carouselItems = [];
  List<Category> categories = [];
  List<Store> stores = [];
  List<Coupon> coupons = [];
  List<Offer> offers = [];
  bool isLoading = true;
  bool hasLoadError = false;
  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() => setState(() {}));
    searchFocusNode.addListener(() => setState(() {}));
    _loadHomeData();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    final langCode =
        Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;

    try {
      setState(() {
        isLoading = true;
        hasLoadError = false;
      });

      final data = await HomeDataService.fetchWebHomeData(
        forceRefresh: hasLoadError,
      );

      final loadedStores = data.stores
          .where((item) {
            final importSource = (item['import_source'] ?? 'manual').toString();
            final approvalStatus =
                (item['approval_status'] ?? 'approved').toString();
            return importSource == 'manual' || approvalStatus == 'approved';
          })
          .map((item) => Store.fromSupabase(item, langCode))
          .toList();
      final loadedStoresMap = _buildStoresMap(loadedStores);

      if (!mounted) return;
      setState(() {
        carouselItems = data.carousel
            .map((item) => Carousel.fromMap(item, langCode))
            .toList();
        categories = data.categories
            .map((item) => Category.fromSupabase(item, langCode))
            .toList();
        stores = loadedStores;
        coupons = data.coupons
            .map((item) => Coupon.fromSupabase(
                  _withStoreData(
                    item,
                    loadedStoresMap,
                  ),
                  langCode,
                ))
            .toList();
        offers = data.offers
            .map((item) => Offer.fromSupabase(item, langCode))
            .toList();
        isLoading = false;
        hasLoadError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        carouselItems = [];
        categories = [];
        stores = [];
        coupons = [];
        offers = [];
        isLoading = false;
        hasLoadError = true;
      });
    }
  }

  Map<String, Store> get _storesMap {
    return _buildStoresMap(stores);
  }

  Map<String, Store> _buildStoresMap(List<Store> sourceStores) {
    final map = <String, Store>{};
    for (final store in sourceStores) {
      if (store.id.trim().isNotEmpty) {
        map[store.id.toLowerCase().trim()] = store;
      }
      if (store.slug.trim().isNotEmpty) {
        map[store.slug.toLowerCase().trim()] = store;
      }
    }
    return map;
  }

  Map<String, dynamic> _withStoreData(
    Map<String, dynamic> row,
    Map<String, Store> sourceStores,
  ) {
    final storeId = (row['store_id'] ?? row['storeId'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final store = sourceStores[storeId];
    if (store == null) return row;

    return {
      ...row,
      'store_name_ar': store.nameAr,
      'store_name_en': store.nameEn,
      'store_image': store.image,
    };
  }

  String _t(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

  String get _searchQuery => searchController.text.trim().toLowerCase();

  bool get _hasSearch => _searchQuery.isNotEmpty;

  UnifiedSearchResults get _searchResults {
    return UnifiedSearchService.search(
      query: searchController.text,
      stores: stores,
      coupons: coupons,
      offers: offers,
      selectedCategoryId: selectedCategoryId,
    );
  }

  List<Store> get _filteredStores {
    return _searchResults.stores;
  }

  List<Coupon> get _filteredCoupons {
    return _searchResults.coupons;
  }

  List<Offer> get _filteredOffers {
    return _searchResults.offers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic =
        Provider.of<LocaleProvider>(context).locale.languageCode == 'ar';
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Theme(
        data: theme.copyWith(
          scaffoldBackgroundColor: bg,
          textTheme: GoogleFonts.cairoTextTheme(theme.textTheme),
        ),
        child: Scaffold(
          backgroundColor: bg,
          appBar: const WebNavigationBar(),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1440),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 26, 24, 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              WebBannerCarousel(items: carouselItems),
                              if (carouselItems.isNotEmpty)
                                const SizedBox(height: 30),
                              _buildSearch(),
                              const SizedBox(height: 26),
                              _buildCategoriesSection(),
                              const SizedBox(height: 34),
                              if (hasLoadError) ...[
                                _buildFeedbackPanel(
                                  icon: Icons.wifi_off_rounded,
                                  title: _localized(
                                    'تعذر تحميل بيانات الصفحة الرئيسية',
                                    'Home data could not be loaded',
                                  ),
                                  message: _localized(
                                    'تحقق من الاتصال وحاول مرة أخرى.',
                                    'Check your connection and try again.',
                                  ),
                                  actionLabel: _localized(
                                    'إعادة المحاولة',
                                    'Try again',
                                  ),
                                  onAction: _loadHomeData,
                                ),
                                const SizedBox(height: 34),
                              ],
                              _buildStoresSection(_filteredStores),
                              const SizedBox(height: 34),
                              _buildCouponsSection(_filteredCoupons),
                              const SizedBox(height: 34),
                              _buildOffersSection(_filteredOffers),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const WebFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    final focused = searchFocusNode.hasFocus;
    final hasText = searchController.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: focused ? orange : stroke.withValues(alpha: 0.88),
          width: focused ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: focused
                ? orange.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.035),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final field = Expanded(
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              style: GoogleFonts.cairo(
                color: ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: _t('search_hint_web'),
                hintStyle: GoogleFonts.cairo(
                  color: faded,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                suffixIcon: hasText
                    ? IconButton(
                        tooltip: _localized('مسح البحث', 'Clear search'),
                        onPressed: searchController.clear,
                        icon: const Icon(Icons.close_rounded),
                        color: secondary,
                      )
                    : null,
              ),
            ),
          );

          if (compact) {
            return Column(
              children: [
                Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.search_rounded,
                        color: orange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  field
                ]),
                const SizedBox(height: 12),
                SizedBox(
                    width: double.infinity,
                    child: _gradientButton(
                      label: _hasSearch
                          ? _localized('عرض النتائج', 'Show results')
                          : _t('search'),
                      onPressed: () => searchFocusNode.requestFocus(),
                    )),
              ],
            );
          }

          return Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child:
                    const Icon(Icons.search_rounded, color: orange, size: 23),
              ),
              const SizedBox(width: 12),
              field,
              const SizedBox(width: 12),
              _gradientButton(
                label: _hasSearch
                    ? _localized('عرض النتائج', 'Show results')
                    : _t('search'),
                onPressed: () => searchFocusNode.requestFocus(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (isLoading) {
      return _buildSectionShell(
        title: _t('categories'),
        icon: Icons.category_rounded,
        actionRoute: '/stores',
        child: const _WebHomeCategoryLoadingRow(),
      );
    }

    return _buildSectionShell(
      title: _t('categories'),
      icon: Icons.category_rounded,
      actionRoute: '/stores',
      child: categories.isEmpty
          ? _buildInlineEmptyState(
              icon: Icons.category_rounded,
              text: _localized(
                'لا توجد فئات متاحة حالياً.',
                'No categories are available right now.',
              ),
            )
          : SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCategoryChip(
                      categoryId: null,
                      label: _t('all'),
                      icon: Icons.apps_rounded,
                    );
                  }

                  final category = categories[index - 1];
                  return _buildCategoryChip(
                    categoryId: category.id,
                    label: category.name,
                    icon: Icons.label_rounded,
                    imageUrl: category.image,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildCategoryChip({
    required String? categoryId,
    required String label,
    required IconData icon,
    String? imageUrl,
  }) {
    final isSelected = selectedCategoryId == categoryId;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: _categoryChipAvatar(
        icon: icon,
        imageUrl: imageUrl,
        isSelected: isSelected,
      ),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.cairo(
          color: isSelected ? Colors.white : secondary,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
      selectedColor: orange,
      backgroundColor: panel,
      side: BorderSide(color: isSelected ? orange : stroke),
      elevation: isSelected ? 2 : 0,
      pressElevation: 0,
      shadowColor: orange.withValues(alpha: 0.18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      onSelected: (_) {
        setState(() {
          selectedCategoryId = categoryId;
        });
      },
    );
  }

  Widget _categoryChipAvatar({
    required IconData icon,
    required bool isSelected,
    String? imageUrl,
  }) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            icon,
            color: isSelected ? Colors.white : orange,
            size: 20,
          ),
        ),
      );
    }

    return Icon(
      icon,
      color: isSelected ? Colors.white : orange,
      size: 20,
    );
  }

  Widget _buildStoresSection(List<Store> sectionStores) {
    if (isLoading) {
      return _buildSectionShell(
        title: _t('top_stores'),
        icon: Icons.storefront_rounded,
        actionRoute: '/stores',
        child: const _WebHomeLoadingGrid(tileCount: 8, minTileHeight: 112),
      );
    }

    return _buildSectionShell(
      title: _hasSearch
          ? _localized('متاجر مطابقة', 'Matching stores')
          : _t('top_stores'),
      icon: Icons.storefront_rounded,
      actionRoute: '/stores',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (sectionStores.isEmpty) {
            return _buildInlineEmptyState(
              icon: Icons.storefront_rounded,
              text: _hasSearch
                  ? _localized('لا توجد متاجر مطابقة للبحث.',
                      'No matching stores found.')
                  : _localized(
                      'لا توجد متاجر متاحة حالياً.',
                      'No stores are available right now.',
                    ),
            );
          }

          final width = constraints.maxWidth;
          final columns = width >= 1180
              ? 6
              : width >= 1024
                  ? 5
                  : width >= 768
                      ? 4
                      : width >= 600
                          ? 3
                          : 2;
          final visibleStores = sectionStores.take(columns * 2).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleStores.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: width < 600
                      ? 1.05
                      : width < 1024
                          ? 1.18
                          : 1.12,
                ),
                itemBuilder: (context, index) {
                  return _storeTile(visibleStores[index]);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _storeTile(Store store) {
    return InkWell(
      onTap: () {
        final routeKey = store.slug.isNotEmpty ? store.slug : store.id;
        Navigator.pushNamed(
          context,
          '/store/$routeKey',
          arguments: store,
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: stroke.withValues(alpha: 0.84)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.045),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: store.image.isEmpty
                      ? Icon(Icons.store_rounded, color: orange, size: 40)
                      : Image.network(
                          store.image,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.store_rounded,
                              color: orange,
                              size: 40),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              store.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: ink,
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponsSection(List<Coupon> sectionCoupons) {
    if (isLoading) {
      return _buildSectionShell(
        title: _t('latest_coupons'),
        icon: Icons.confirmation_number_rounded,
        actionRoute: '/coupons',
        child: const _WebHomeLoadingGrid(tileCount: 6, minTileHeight: 260),
      );
    }

    return _buildSectionShell(
      title: _hasSearch
          ? _localized('كوبونات مطابقة', 'Matching coupons')
          : _t('latest_coupons'),
      icon: Icons.confirmation_number_rounded,
      actionRoute: '/coupons',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (sectionCoupons.isEmpty) {
            return _buildInlineEmptyState(
              icon: Icons.confirmation_number_rounded,
              text: _hasSearch
                  ? _localized('لا توجد كوبونات مطابقة للبحث.',
                      'No matching coupons found.')
                  : _localized(
                      'لا توجد كوبونات متاحة حالياً.',
                      'No coupons are available right now.',
                    ),
            );
          }

          final width = constraints.maxWidth;
          final columns =
              width >= 1024 ? 3 : ResponsiveGrid.columnsForWidth(width, max: 3);
          final visibleCoupons = sectionCoupons.take(columns * 2).toList();
          final storesMap = _storesMap;
          final spacing = ResponsiveGrid.spacingForWidth(width);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleCoupons.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: width >= 1024 ? 2.5 : 0.62,
                ),
                itemBuilder: (context, index) {
                  final coupon = visibleCoupons[index];
                  final store = storesMap[coupon.storeId.toLowerCase().trim()];
                  return WebCouponCard(
                    coupon: coupon,
                    storeName: store?.name ?? _t('store'),
                    compact: true,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOffersSection(List<Offer> sectionOffers) {
    if (isLoading) {
      return _buildSectionShell(
        title: _t('latest_offers'),
        icon: Icons.local_offer_rounded,
        actionRoute: '/offers',
        child: const _WebHomeLoadingGrid(tileCount: 4, minTileHeight: 220),
      );
    }

    return _buildSectionShell(
      title: _hasSearch
          ? _localized('عروض مطابقة', 'Matching offers')
          : _t('latest_offers'),
      icon: Icons.local_offer_rounded,
      actionRoute: '/offers',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (sectionOffers.isEmpty) {
            return _buildInlineEmptyState(
              icon: Icons.local_offer_rounded,
              text: _hasSearch
                  ? _localized(
                      'لا توجد عروض مطابقة للبحث.',
                      'No matching offers found.',
                    )
                  : _localized(
                      'لا توجد عروض متاحة حالياً.',
                      'No offers are available right now.',
                    ),
            );
          }

          final width = constraints.maxWidth;
          final columns = ResponsiveGrid.columnsForWidth(width, max: 4);
          final visibleOffers = sectionOffers.take(columns).toList();
          final storesMap = _storesMap;
          final spacing = ResponsiveGrid.spacingForWidth(width);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleOffers.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: width >= 1024 ? 0.86 : 0.78,
                ),
                itemBuilder: (context, index) {
                  final offer = visibleOffers[index];
                  final store = storesMap[offer.storeId.toLowerCase().trim()];
                  return WebOfferCard(
                    offer: offer,
                    storeName: store?.name ?? _t('store'),
                    storeImage: store?.image,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionShell({
    required String title,
    required IconData icon,
    required String actionRoute,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stroke.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: orange, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, actionRoute),
                style: TextButton.styleFrom(
                  foregroundColor: orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(
                  _t('view_more'),
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildInlineEmptyState({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 34),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: stroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: faded, size: 42),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: secondary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackPanel({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stroke),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final copy = Column(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
            children: [
              Text(
                title,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: GoogleFonts.cairo(
                  color: ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: GoogleFonts.cairo(
                  color: secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
          final action =
              _gradientButton(label: actionLabel, onPressed: onAction);

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(icon, color: orange, size: 34),
                const SizedBox(height: 12),
                copy,
                const SizedBox(height: 16),
                action,
              ],
            );
          }

          return Row(
            children: [
              Icon(icon, color: orange, size: 34),
              const SizedBox(width: 16),
              Expanded(child: copy),
              const SizedBox(width: 16),
              action,
            ],
          );
        },
      ),
    );
  }

  String _localized(String ar, String en) {
    final isArabic = Provider.of<LocaleProvider>(context, listen: false)
            .locale
            .languageCode ==
        'ar';
    return isArabic ? ar : en;
  }

  Widget _gradientButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [orange, pink]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }
}

class _WebHomeLoadingGrid extends StatelessWidget {
  final int tileCount;
  final double minTileHeight;

  const _WebHomeLoadingGrid({
    required this.tileCount,
    required this.minTileHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = ResponsiveGrid.columnsForWidth(width, max: 4);
        final spacing = ResponsiveGrid.spacingForWidth(width);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tileCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: minTileHeight,
          ),
          itemBuilder: (context, index) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _WebHomeScreenState.stroke),
              ),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: _WebHomeScreenState.orange.withValues(alpha: 0.72),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WebHomeCategoryLoadingRow extends StatelessWidget {
  const _WebHomeCategoryLoadingRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _WebHomeScreenState.stroke),
            ),
            child: const SizedBox(width: 132, height: 48),
          );
        },
      ),
    );
  }
}
