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
import '../web_widgets/web_search_bar.dart';
import '../web_widgets/web_store_card.dart';
import '../web_widgets/web_offer_card.dart';

/// الصفحة الرئيسية الاحترافية المحدثة للويب
class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  final supabase = Supabase.instance.client;

  List<dynamic> displayItems = []; // قائمة مختلطة (كوبونات + عروض)
  List<Store> stores = [];
  List<Carousel> carouselItems = [];
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

      final loadedCoupons = (couponsData as List)
          .map((coupon) => Coupon.fromSupabase(coupon, langCode))
          .toList();

      if (mounted) {
        setState(() {
          stores = loadedStores;
          carouselItems = loadedCarousel;
          displayItems = loadedCoupons;
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
            content: Text('حدث خطأ أثناء تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const WebNavigationBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchSection(),
            _buildHeroSection(),
            _buildCouponsSection(),
            _buildStoresSection(),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  // شريط البحث
  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsivePadding.page(context).horizontal,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Center(
        child: WebSearchBar(
          hintText: 'ابحث عن الكوبونات والمتاجر...',
          onSearch: (query) {},
        ),
      ),
    );
  }

  // Hero
  Widget _buildHeroSection() {
    if (isLoading && stores.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: ResponsivePadding.page(context),
      child: ResponsiveLayout.isDesktop(context)
          ? SizedBox(
              height: 380,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: _buildFeaturedCarousel()),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildBestStoresSidePanel()),
                ],
              ),
            )
          : Column(
              children: [
                _buildFeaturedCarousel(),
                const SizedBox(height: 20),
                _buildBestStoresSidePanel(),
              ],
            ),
    );
  }

  Widget _buildBestStoresSidePanel() {
    final topStores = stores.take(9).toList();
    if (topStores.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أشهر المتاجر',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Tajawal',
                  color: Colors.grey[800],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/stores'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'عرض الكل',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Tajawal',
                    color: Constants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3x3
          Column(
            children: [
              for (int i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                Row(
                  children: [
                    for (int j = 0; j < 3; j++) ...[
                      if (j > 0) const SizedBox(width: 8),
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
                                    const Duration(milliseconds: 300), () {
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
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Constants.primaryColor
                                          .withValues(alpha: 0.05)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Constants.primaryColor
                                        : Colors.grey[200]!,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 75,
                                      height: 75,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey[100]!),
                                      ),
                                      child: store.image.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: CachedNetworkImage(
                                                imageUrl: store.image,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                  color: Colors.grey[200],
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.store,
                                                            size: 16),
                                              ),
                                            )
                                          : Icon(Icons.store,
                                              color: Constants.primaryColor,
                                              size: 20),
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
        ],
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    if (carouselItems.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: ResponsiveLayout.isDesktop(context) ? 380 : 300,
      child: WebBannerCarousel(items: carouselItems),
    );
  }

  Widget _buildStoresSection() {
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
      padding: ResponsivePadding.page(context),
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.grey[50]!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.store_rounded,
                          color: Color(0xFF6366F1),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'المتاجر الشهيرة',
                        style: TextStyle(
                          fontSize:
                              ResponsiveLayout.isDesktop(context) ? 36 : 26,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF6366F1),
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '🛍️ تسوق من أفضل المتاجر وابدأ التوفير',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (ResponsiveLayout.isDesktop(context))
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/stores'),
                    icon:
                        const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
                    label: const Text(
                      'عرض الكل',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 40),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveGrid.columns(context, max: 6),
              crossAxisSpacing: ResponsiveGrid.spacing(context),
              mainAxisSpacing: ResponsiveGrid.spacing(context),
              childAspectRatio: 0.85,
            ),
            itemCount: stores.length > 12 ? 12 : stores.length,
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCouponsSection() {
    if (isLoading && displayItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: ResponsivePadding.page(context),
      margin: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            key: _couponsSectionKey,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_offer_rounded,
                          color: Color(0xFFEC4899),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        selectedStoreId != null
                            ? 'عروض ${_getStoreName(selectedStoreId!)}'
                            : 'أحدث الكوبونات',
                        style: TextStyle(
                          fontSize:
                              ResponsiveLayout.isDesktop(context) ? 36 : 26,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFEC4899),
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '🎁 احصل على أفضل العروض والخصومات',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (selectedStoreId != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() => selectedStoreId = null);
                      _loadData();
                    },
                    icon: const Icon(Icons.clear, color: Colors.red),
                    label: const Text(
                      'إلغاء الفلتر',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 40),
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
          else if (displayItems.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(60),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'لا توجد كوبونات أو عروض متاحة لهذا المتجر',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),

              // ✅✅ الحل 1 هنا: mainAxisExtent بدل childAspectRatio
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveGrid.columns(context, max: 4),
                crossAxisSpacing: ResponsiveGrid.spacing(context),
                mainAxisSpacing: ResponsiveGrid.spacing(context),
                mainAxisExtent: _couponCardExtent(context),
              ),

              itemCount: displayItems.length,
              itemBuilder: (context, index) {
                final item = displayItems[index];

                if (item is Coupon) {
                  final store = stores.firstWhere(
                    (s) => s.id == item.storeId,
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
                    (s) => s.id == item.storeId,
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
          const SizedBox(height: 50),
          Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Constants.primaryColor,
                    Constants.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Constants.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: const Text(
                  'عرض المزيد',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    fontFamily: 'Tajawal',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ارتفاع ثابت للكارد (متجاوب) — يمنع overflow نهائيًا
  double _couponCardExtent(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 390;
    if (width >= 1100) return 390;
    if (width >= 900) return 400;
    if (width >= 700) return 420;
    return 460;
  }

  String _getStoreName(String storeId) {
    try {
      final store = stores.firstWhere((s) => s.id == storeId);
      return store.name;
    } catch (_) {
      return 'المتجر';
    }
  }
}
