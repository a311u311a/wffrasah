import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../constants.dart';
import '../models/coupon.dart';
import '../models/store.dart';
import '../models/carousel.dart';
import '../models/offers.dart';

import '../providers/locale_provider.dart';

import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';
import '../web_widgets/web_coupon_card.dart';
import '../web_widgets/web_banner_carousel.dart';

import '../web_widgets/web_store_card.dart';
import '../web_widgets/web_offer_card.dart';
import '../localization/app_localizations.dart';

/// الصفحة الرئيسية الاحترافية المحدثة للويب (UI فقط)
class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  final supabase = Supabase.instance.client;

  List<dynamic> displayItems = []; // كوبونات + عروض
  List<Store> stores = [];
  List<Carousel> carouselItems = [];
  List<Offer> latestOffers = []; // أحدث العروض للقسم الجديد
  bool isLoading = true;
  bool isFiltering = false;
  String? selectedStoreId;
  final GlobalKey _couponsSectionKey = GlobalKey(); // ✅ مفتاح التمرير

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      if (stores.isNotEmpty && selectedStoreId != null) {
        isFiltering = true;
      } else {
        isLoading = true;
      }
    });

    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final langCode = localeProvider.locale.languageCode;

    try {
      List<Store> loadedStores = stores;
      List<Carousel> loadedCarousel = carouselItems;

      // 1) تحميل المتاجر والبنر مرة واحدة
      if (stores.isEmpty) {
        final storesData = await supabase
            .from('stores')
            .select()
            .order('name_ar', ascending: true);

        loadedStores = (storesData as List)
            .map((store) => Store.fromSupabase(store, langCode))
            .toList();

        final carouselData = await supabase.from('carousel').select();
        loadedCarousel = (carouselData as List)
            .map((item) => Carousel.fromMap(item, langCode))
            .toList();
      }

      // 2) حالة الفلترة حسب المتجر
      if (selectedStoreId != null) {
        final selectedStore = loadedStores.firstWhere(
          (s) => s.id == selectedStoreId,
          orElse: () => Store(
            id: selectedStoreId!,
            slug: selectedStoreId!,
            name: '',
            description: '',
            nameAr: '',
            nameEn: '',
            descriptionAr: '',
            descriptionEn: '',
            image: '',
          ),
        );

        final storeKey = selectedStore.slug.isNotEmpty
            ? selectedStore.slug
            : selectedStoreId!;

        // جلب الكوبونات
        final couponsResponse = await supabase
            .from('coupons')
            .select()
            .eq('store_id', storeKey.trim())
            .order('created_at', ascending: false);

        // جلب العروض
        final offersResponse = await supabase
            .from('offers')
            .select()
            .eq('store_id', storeKey.trim())
            .order('created_at', ascending: false);

        final loadedCoupons = (couponsResponse as List)
            .map((data) => Coupon.fromSupabase(data, langCode))
            .toList();

        final loadedOffers = (offersResponse as List)
            .map((data) => Offer.fromSupabase(data, langCode))
            .toList();

        final List<dynamic> allItems = [...loadedCoupons, ...loadedOffers];

        if (mounted) {
          setState(() {
            stores = loadedStores;
            carouselItems = loadedCarousel;
            displayItems = allItems;
            isLoading = false;
            isFiltering = false;
          });
        }
        return;
      }

      // 3) الحالة الافتراضية: أحدث الكوبونات
      final couponsData = await supabase
          .from('coupons')
          .select()
          .order('created_at', ascending: false)
          .limit(20);

      final offersData = await supabase
          .from('offers')
          .select()
          .order('created_at', ascending: false)
          .limit(20);

      final loadedCoupons = (couponsData as List)
          .map((coupon) => Coupon.fromSupabase(coupon, langCode))
          .toList();

      final loadedOffers = (offersData as List)
          .map((offer) => Offer.fromSupabase(offer, langCode))
          .toList();

      if (mounted) {
        setState(() {
          stores = loadedStores;
          carouselItems = loadedCarousel;
          displayItems = loadedCoupons;
          latestOffers = loadedOffers;
          isLoading = false;
          isFiltering = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isFiltering = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.translate('error_loading_data')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =========================
  // ✅ ستايل موحّد (UI فقط)
  // =========================
  static const String _font = 'Tajawal';

  TextStyle _h1(BuildContext context) => TextStyle(
        fontSize: ResponsiveLayout.isDesktop(context) ? 34 : 26,
        fontWeight: FontWeight.w900,
        fontFamily: _font,
        color: Colors.grey[900],
        height: 1.2,
      );

  TextStyle _sub(BuildContext context) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        fontFamily: _font,
        color: Colors.grey[600],
        height: 1.4,
      );

  TextStyle _chipText() => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        fontFamily: _font,
      );

  BoxDecoration _softCard() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[100]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      );

  BoxDecoration _sectionBackground() => const BoxDecoration(
        color: Colors.white,
      );

  Widget _sectionHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Constants.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Constants.primaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              icon,
              color: Constants.primaryColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _h1(context)),
                const SizedBox(height: 8),
                Text(subtitle, style: _sub(context)),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _pillButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Constants.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Constants.primaryColor.withValues(alpha: 0.18)),
      ),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Constants.primaryColor),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            fontFamily: _font,
          ).copyWith(color: Constants.primaryColor),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const WebNavigationBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchSection(localizations),
            _buildHeroSection(localizations),
            _buildCouponsSection(localizations),
            _buildOffersSection(localizations),
            _buildStoresSection(localizations),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  // شريط البحث (مُحسّن شكلاً)
  Widget _buildSearchSection(AppLocalizations? localizations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    );
  }

  // Hero
  Widget _buildHeroSection(AppLocalizations? localizations) {
    if (isLoading && stores.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: _sectionBackground(),
      child: Padding(
        padding: ResponsivePadding.page(context),
        child: ResponsiveLayout.isDesktop(context)
            ? SizedBox(
                height: 400,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: _softCard().copyWith(boxShadow: []),
                        clipBehavior: Clip.antiAlias,
                        child: _buildFeaturedCarousel(),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 2,
                      child: _buildBestStoresSidePanel(localizations),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Container(
                    decoration: _softCard().copyWith(boxShadow: []),
                    clipBehavior: Clip.antiAlias,
                    child: _buildFeaturedCarousel(),
                  ),
                  const SizedBox(height: 14),
                  _buildBestStoresSidePanel(localizations),
                ],
              ),
      ),
    );
  }

  Widget _buildBestStoresSidePanel(AppLocalizations? localizations) {
    final topStores = stores.take(9).toList();
    if (topStores.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  localizations?.translate('top_stores') ?? 'أشهر المتاجر',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: _font,
                    color: Colors.grey[900],
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/stores'),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    localizations?.translate('show_all') ?? 'عرض الكل',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontFamily: _font,
                      color: Constants.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grid 3x3
          Column(
            children: [
              for (int i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Row(
                  children: [
                    for (int j = 0; j < 3; j++) ...[
                      if (j > 0) const SizedBox(width: 10),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final index = i * 3 + j;
                            if (index >= topStores.length) {
                              return const SizedBox();
                            }
                            final store = topStores[index];
                            final isSelected = selectedStoreId == store.id;

                            return InkWell(
                              onTap: () {
                                setState(() => selectedStoreId = store.id);
                                _loadData();

                                Future.delayed(
                                    const Duration(milliseconds: 250), () {
                                  if (_couponsSectionKey.currentContext !=
                                      null) {
                                    Scrollable.ensureVisible(
                                      _couponsSectionKey.currentContext!,
                                      duration:
                                          const Duration(milliseconds: 600),
                                      curve: Curves.easeInOut,
                                      alignment: 0.1,
                                    );
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Constants.primaryColor
                                          .withValues(alpha: 0.08)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? Constants.primaryColor
                                            .withValues(alpha: 0.55)
                                        : Colors.grey[200]!,
                                    width: isSelected ? 1.6 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 74,
                                      height: 74,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey[100]!),
                                      ),
                                      child: store.image.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: CachedNetworkImage(
                                                imageUrl: store.image,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                  color: Colors.grey[200],
                                                ),
                                                errorWidget: (context, url,
                                                        error) =>
                                                    Icon(Icons.store,
                                                        color:
                                                            Colors.grey[500]),
                                              ),
                                            )
                                          : Icon(
                                              Icons.store_rounded,
                                              color: Constants.primaryColor,
                                              size: 22,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (selectedStoreId != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Constants.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Constants.primaryColor.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_alt_rounded,
                      color: Constants.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${localizations?.translate('offers_for') ?? 'عروض'} ${_getStoreName(selectedStoreId!)}',
                      style: _chipText().copyWith(color: Colors.grey[900]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    if (carouselItems.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: ResponsiveLayout.isDesktop(context) ? 400 : 300,
      child: WebBannerCarousel(items: carouselItems),
    );
  }

  Widget _buildStoresSection(AppLocalizations? localizations) {
    if (isLoading && stores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Constants.primaryColor),
          ),
        ),
      );
    }

    if (stores.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 38),
      decoration: _sectionBackground(),
      child: Padding(
        padding: ResponsivePadding.page(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              context: context,
              icon: Icons.store_rounded,
              title: localizations?.translate('popular_stores') ??
                  'المتاجر الشهيرة',
              subtitle: localizations?.translate('popular_stores_subtitle') ??
                  '🛍️ تسوق من أفضل المتاجر وابدأ التوفير',
              trailing: ResponsiveLayout.isDesktop(context)
                  ? _pillButton(
                      text: localizations?.translate('show_all') ?? 'عرض الكل',
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pushNamed(context, '/stores'),
                    )
                  : null,
            ),
            const SizedBox(height: 26),

            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveLayout.isDesktop(context)
                    ? ResponsiveGrid.columns(context, max: 6)
                    : ResponsiveGrid.columns(context, max: 2),
                crossAxisSpacing: ResponsiveGrid.spacing(context),
                mainAxisSpacing: ResponsiveGrid.spacing(context),
                mainAxisExtent: 220,
              ),
              itemCount: () {
                final cols = ResponsiveLayout.isDesktop(context)
                    ? ResponsiveGrid.columns(context, max: 6)
                    : ResponsiveGrid.columns(context, max: 2);
                final limit = cols * 2;
                return stores.length > limit ? limit : stores.length;
              }(),
              itemBuilder: (context, index) {
                return WebStoreCard(
                  store: stores[index],
                  onTap: () {
                    setState(() {
                      selectedStoreId = stores[index].id;
                    });
                    _loadData();
                  },
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponsSection(AppLocalizations? localizations) {
    if (isLoading && displayItems.isEmpty) return const SizedBox.shrink();

    final title = selectedStoreId != null
        ? '${localizations?.translate('offers_for') ?? 'عروض'} ${_getStoreName(selectedStoreId!)}'
        : (localizations?.translate('latest_coupons') ?? 'أحدث الكوبونات');

    return Container(
      margin: const EdgeInsets.only(top: 38),
      child: Padding(
        padding: ResponsivePadding.page(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              key: _couponsSectionKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _sectionHeader(
                    context: context,
                    icon: Icons.local_offer_rounded,
                    title: title,
                    subtitle:
                        localizations?.translate('coupons_section_subtitle') ??
                            '🎁 احصل على أفضل العروض والخصومات',
                    trailing: (selectedStoreId == null &&
                            ResponsiveLayout.isDesktop(context))
                        ? _pillButton(
                            text: localizations?.translate('show_all') ??
                                'عرض الكل',
                            icon: Icons.arrow_back,
                            onTap: () =>
                                Navigator.pushNamed(context, '/coupons'),
                          )
                        : null,
                  ),
                ),
                if (selectedStoreId != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => selectedStoreId = null);
                        _loadData();
                      },
                      icon: const Icon(Icons.clear),
                      label: Text(localizations?.translate('clear_filter') ??
                          'إلغاء الفلتر'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        textStyle: const TextStyle(
                          fontFamily: _font,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 22),

            // Loading state when filtering
            if (isFiltering)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Constants.primaryColor),
                  ),
                ),
              )
            // Empty state
            else if (displayItems.isEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(56),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 18),
                      Text(
                        localizations?.translate('no_results_for_store') ??
                            'لا توجد كوبونات أو عروض متاحة لهذا المتجر',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontFamily: _font,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            // Grid items
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveGrid.columns(context, max: 6),
                  crossAxisSpacing: ResponsiveGrid.spacing(context),
                  mainAxisSpacing: ResponsiveGrid.spacing(context),
                  mainAxisExtent: _couponCardExtent(context),
                ),
                itemCount: () {
                  final cols = ResponsiveGrid.columns(context, max: 6);
                  final limit = cols * 6; // ✅ زيادة من 2 إلى 6 صفوف
                  return displayItems.length > limit
                      ? limit
                      : displayItems.length;
                }(),
                itemBuilder: (context, index) {
                  final item = displayItems[index];

                  if (item is Coupon) {
                    final store = stores.firstWhere(
                      (s) => s.id == item.storeId || s.slug == item.storeId,
                      orElse: () => Store(
                        id: '',
                        slug: '',
                        name: 'متجر',
                        description: '',
                        nameAr: 'متجر',
                        nameEn: 'Store',
                        descriptionAr: '',
                        descriptionEn: '',
                        image: '',
                      ),
                    );

                    return WebCouponCard(
                      coupon: item,
                      storeName: store.name,
                    );
                  } else if (item is Offer) {
                    final store = stores.firstWhere(
                      (s) => s.id == item.storeId || s.slug == item.storeId,
                      orElse: () => Store(
                        id: '',
                        slug: '',
                        name: 'متجر',
                        description: '',
                        nameAr: 'متجر',
                        nameEn: 'Store',
                        descriptionAr: '',
                        descriptionEn: '',
                        image: '',
                      ),
                    );

                    return WebOfferCard(
                      offer: item,
                      storeName: store.name,
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

            const SizedBox(height: 34),

            // CTA button (محسّن)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Constants.primaryColor,
                      Constants.primaryColor.withValues(alpha: 0.82),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Constants.primaryColor.withValues(alpha: 0.30),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  label: Text(
                    localizations?.translate('view_more') ?? 'عرض المزيد',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      fontFamily: _font,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 54, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersSection(AppLocalizations? localizations) {
    if (isLoading && latestOffers.isEmpty) return const SizedBox.shrink();
    if (latestOffers.isEmpty && selectedStoreId != null) {
      return const SizedBox.shrink();
    }

    // في حالة اختيار متجر، العروض تظهر مدمجة في قسم الكوبونات الرئيسي
    // لذا هذا القسم يظهر فقط في الصفحة الرئيسية العامة
    if (selectedStoreId != null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 38),
      child: Padding(
        padding: ResponsivePadding.page(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _sectionHeader(
              context: context,
              icon: Icons.flash_on_rounded,
              title: localizations?.translate('latest_offers') ??
                  'أحدث العروض والخصومات',
              subtitle: localizations?.translate('offers_subtitle') ??
                  '🔥 وفر أكثر مع أقوى العروض الحصرية والمتجددة',
              trailing: ResponsiveLayout.isDesktop(context)
                  ? _pillButton(
                      text: localizations?.translate('show_all') ?? 'عرض الكل',
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pushNamed(context, '/offers'),
                    )
                  : null,
            ),
            const SizedBox(height: 26),

            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveLayout.isDesktop(context)
                    ? ResponsiveGrid.columns(context,
                        max: 4) // ✅ توحيد مع صفحة العروض
                    : ResponsiveGrid.columns(context, max: 2),
                crossAxisSpacing: ResponsiveGrid.spacing(context),
                mainAxisSpacing: ResponsiveGrid.spacing(context),
                mainAxisExtent: _couponCardExtent(context),
              ),
              itemCount: () {
                final cols = ResponsiveLayout.isDesktop(context)
                    ? ResponsiveGrid.columns(context, max: 6)
                    : ResponsiveGrid.columns(context, max: 2);
                final limit = cols * 6; // ✅ زيادة من 2 إلى 6 صفوف
                return latestOffers.length > limit
                    ? limit
                    : latestOffers.length;
              }(),
              itemBuilder: (context, index) {
                final offer = latestOffers[index];
                final store = stores.firstWhere(
                  (s) =>
                      s.id.toLowerCase().trim() ==
                          offer.storeId.toLowerCase().trim() ||
                      s.slug.toLowerCase().trim() ==
                          offer.storeId.toLowerCase().trim(),
                  orElse: () => Store(
                    id: '',
                    slug: '',
                    name: 'متجر',
                    description: '',
                    nameAr: 'متجر',
                    nameEn: 'Store',
                    descriptionAr: '',
                    descriptionEn: '',
                    image: '',
                  ),
                );

                return WebOfferCard(
                  offer: offer,
                  storeName: store.name,
                  storeImage: store.image, // ✅ تمرير الشعار
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ارتفاع ثابت للكارد (متجاوب) — يمنع overflow نهائيًا
  double _couponCardExtent(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 410; // زيادة من 390
    if (width >= 1100) return 410; // زيادة من 390
    if (width >= 900) return 420; // زيادة من 400
    if (width >= 700) return 440; // زيادة من 420
    return 480; // زيادة من 460
  }

  String _getStoreName(String storeId) {
    try {
      final store = stores.firstWhere(
        (s) => s.id == storeId || s.slug == storeId,
      );
      return store.name;
    } catch (_) {
      return 'المتجر';
    }
  }
}
