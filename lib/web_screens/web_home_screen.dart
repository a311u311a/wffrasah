import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../models/coupon.dart';
import '../models/store.dart';
import '../providers/locale_provider.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';
import '../web_widgets/web_coupon_card.dart';
import '../web_widgets/web_banner_carousel.dart';
import '../web_widgets/web_search_bar.dart';

import '../web_widgets/web_store_card.dart';
import '../web_widgets/web_offer_card.dart';
import '../models/offers.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  bool isLoading = true;
  bool isFiltering = false;
  String? selectedStoreId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // إذا كانت المتاجر محملة بالفعل، فهذا يعني أننا نقوم بفلترة فقط
    if (stores.isNotEmpty) {
      setState(() => isFiltering = true);
    } else {
      setState(() => isLoading = true);
    }

    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final langCode = localeProvider.locale.languageCode;

    try {
      List<Store> loadedStores = stores;

      // تحميل المتاجر فقط إذا لم تكن محملة من قبل
      if (stores.isEmpty) {
        final storesData = await supabase
            .from('stores')
            .select()
            .order('name_ar', ascending: true);

        loadedStores = (storesData as List)
            .map((store) => Store.fromSupabase(store, langCode))
            .toList();
      }

      // إذا تم اختيار متجر، نجلب الكوبونات والعروض الخاصة به
      if (selectedStoreId != null) {
        // 1. جلب الكوبونات
        final couponsFuture = supabase
            .from('coupons')
            .select()
            .eq('store_id', selectedStoreId!)
            .order('created_at', ascending: false);

        // 2. جلب العروض
        // ملاحظة: نفترض أن store_id في جدول offers هو نفسه id المتجر (أو slug حسب التصميم الجديد)
        // وبما أننا نستخدم selectedStoreId (وهو UUID غالبًا)، نتأكد من الجدول.
        // إذا كان الجدول يستخدم slug، سنحتاج لتعديل هذا، لكن سنفترض التناسق حالياً كما في الكوبونات.
        final offersFuture = supabase
            .from('offers')
            .select()
            .eq('store_id', selectedStoreId!)
            .order('created_at', ascending: false);

        final results = await Future.wait([couponsFuture, offersFuture]);

        final loadedCoupons = (results[0] as List)
            .map((data) => Coupon.fromSupabase(data, langCode))
            .toList();

        final loadedOffers = (results[1] as List)
            .map((data) => Offer.fromSupabase(data, langCode))
            .toList();

        // دمج القائمتين
        final List<dynamic> allItems = [...loadedCoupons, ...loadedOffers];

        // ترتيب حسب الأحدث (اختياري - هنا نعتمد على أن كلاهما مرتب، لكن الدمج قد يحتاج إعادة ترتيب)
        // للتبسيط سنعرض الكوبونات ثم العروض، أو يمكن خلطهم إذا كان لديهم timestamp مشترك
        // allItems.shuffle(); // أو ترتيب زمني

        setState(() {
          stores = loadedStores;
          displayItems = allItems;
          isLoading = false;
          isFiltering = false;
        });
        return;
      }

      // الحالة الافتراضية (الصفحة الرئيسية): نجلب أحدث الكوبونات فقط (أو أحدث العروض أيضاً إذا أردنا)
      // حالياً سنبقيها للكوبونات فقط كما كان، أو يمكننا جلب Mix
      final couponsData = await supabase
          .from('coupons')
          .select()
          .order('created_at', ascending: false)
          .limit(12);

      final loadedCoupons = (couponsData as List)
          .map((coupon) => Coupon.fromSupabase(coupon, langCode))
          .toList();

      setState(() {
        stores = loadedStores;
        displayItems = loadedCoupons;
        isLoading = false;
        isFiltering = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isFiltering = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
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
            // شريط البحث
            _buildSearchSection(),

            // قسم Hero الجديد (Grid متاجر + Carousel)
            _buildHeroSection(),

            // Latest Coupons Section
            _buildCouponsSection(),

            // Popular Stores Section
            _buildStoresSection(),

            // Footer
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
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Center(
        child: WebSearchBar(
          hintText: 'ابحث عن الكوبونات والمتاجر...',
          onSearch: (query) {
            // البحث سيتم تنفيذه لاحقاً
          },
        ),
      ),
    );
  }

  // قسم Hero الجديد (Grid متاجر + Carousel)
  Widget _buildHeroSection() {
    if (isLoading && stores.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: ResponsivePadding.page(context),
      child: ResponsiveLayout.isDesktop(context)
          ? SizedBox(
              height: 450, // ✅ تحديد ارتفاع ثابت للديسك توب
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Carousel العروض (الأكبر - يمين في العربي)
                  Expanded(
                    flex: 3,
                    child: _buildFeaturedCarousel(),
                  ),
                  const SizedBox(width: 24),

                  // قائمة المتاجر الجانبية (الأصغر - يسار في العربي)
                  Expanded(
                    flex: 1,
                    child: _buildBestStoresSidePanel(),
                  ),
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
    final topStores = stores.take(5).toList();

    if (topStores.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ مهم عشان يغلف المحتوى
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
          // ✅ إزالة Expanded واستخدام shrinkWrap
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topStores.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final store = topStores[index];
              return InkWell(
                onTap: () {
                  setState(() => selectedStoreId = store.id);
                  _loadData();
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: store.image.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: store.image,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.store, size: 20),
                              ),
                            )
                          : Icon(Icons.store,
                              color: Constants.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: Colors.grey[300]),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    if (stores.isEmpty) return const SizedBox.shrink();

    // نزيد الارتفاع قليلاً ليكون العنصر المهيمن
    return SizedBox(
      height: ResponsiveLayout.isDesktop(context) ? 450 : 300,
      child: WebBannerCarousel(
        stores: stores,
        onStoreTap: (storeId) {
          setState(() => selectedStoreId = storeId);
          _loadData();
        },
      ),
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

    if (stores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: ResponsivePadding.page(context),
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
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
                          color: const Color(0xFF6366F1).withOpacity(0.1),
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
                    color: const Color(0xFF6366F1).withOpacity(0.1),
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
    if (isLoading && displayItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: ResponsivePadding.page(context),
      margin: const EdgeInsets.only(top: 40),
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
                          color: const Color(0xFFEC4899).withOpacity(0.1),
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
                            ? 'أحدث العروض والكوبونات'
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
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveGrid.columns(context, max: 4),
                crossAxisSpacing: ResponsiveGrid.spacing(context),
                mainAxisSpacing: ResponsiveGrid.spacing(context),
                childAspectRatio: 0.75,
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

          // زر عرض المزيد المحسّن
          Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Constants.primaryColor,
                    Constants.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Constants.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Load more
                },
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
}
