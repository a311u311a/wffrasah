import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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

/// صفحة الكوبونات للويب
class WebCouponsScreen extends StatefulWidget {
  const WebCouponsScreen({super.key});

  @override
  State<WebCouponsScreen> createState() => _WebCouponsScreenState();
}

class _WebCouponsScreenState extends State<WebCouponsScreen> {
  final supabase = Supabase.instance.client;
  List<Coupon> coupons = []; // الكوبونات المفلترة
  List<Coupon> allCoupons = []; // كل الكوبونات (للفلاتر)
  List<Store> stores = [];
  Map<String, Store> storesMap = {};
  bool isLoading = true;
  String? selectedStoreId;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final langCode = localeProvider.locale.languageCode;

    try {
      // تحميل المتاجر
      final storesData = await supabase
          .from('stores')
          .select()
          .order('name_ar', ascending: true);

      final loadedStores = (storesData as List)
          .map((store) => Store.fromSupabase(store, langCode))
          .toList();

      storesMap = {for (var store in loadedStores) store.id: store};

      // تحميل الكوبونات
      // ⚠️ مهم: الكوبونات تستخدم slug في store_id، ليس UUID!
      dynamic couponsData;

      if (selectedStoreId != null) {
        couponsData = await supabase
            .from('coupons')
            .select()
            .eq('store_id', selectedStoreId!)
            .order('created_at', ascending: false);
      } else {
        couponsData = await supabase
            .from('coupons')
            .select()
            .order('created_at', ascending: false);
      }

      final loadedCoupons = (couponsData as List)
          .map((coupon) => Coupon.fromSupabase(coupon, langCode))
          .toList();

      setState(() {
        stores = loadedStores;
        coupons = loadedCoupons;
        // حفظ كل الكوبونات عند التحميل الأول فقط
        if (selectedStoreId == null) {
          allCoupons = loadedCoupons;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  List<Coupon> get filteredCoupons {
    if (searchQuery.isEmpty) return coupons;

    return coupons.where((coupon) {
      final store = storesMap[coupon.storeId];
      return coupon.code.toLowerCase().contains(searchQuery.toLowerCase()) ||
          coupon.description
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          (store?.name.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const WebNavigationBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildFilters(),
            _buildCouponsGrid(),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: ResponsivePadding.page(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEC4899).withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.confirmation_number_rounded,
                  color: Color(0xFFEC4899),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'جميع الكوبونات',
                style: TextStyle(
                  fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFEC4899),
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '🎁 اكتشف أفضل الكوبونات والخصومات الحصرية من متاجرك المفضلة',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    // المتاجر التي لديها كوبونات - استخدام allCoupons بدلاً من coupons
    final storesWithCoupons = stores
        .where((store) {
          return allCoupons.any((coupon) => coupon.storeId == store.slug);
        })
        .take(20)
        .toList(); // زيادة العدد إلى 20

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsivePadding.page(context).horizontal,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط البحث
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'ابحث عن كوبون أو متجر...',
                hintStyle: const TextStyle(fontFamily: 'Tajawal'),
                prefixIcon: Icon(Icons.search, color: Constants.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Constants.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // عنوان الفلاتر
          Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                color: Constants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'فلترة حسب المتجر:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // القائمة الأفقية للفلاتر
          SizedBox(
            height: 48,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
                scrollbars: false,
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  // زر "الكل"
                  _buildFilterButton(
                    label: 'الكل 🎯',
                    isSelected: selectedStoreId == null,
                    onTap: () {
                      setState(() => selectedStoreId = null);
                      _loadData();
                    },
                    isPrimary: true,
                  ),
                  const SizedBox(width: 12),

                  // أزرار المتاجر
                  ...storesWithCoupons.map((store) {
                    final couponCount =
                        allCoupons.where((c) => c.storeId == store.slug).length;
                    return Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _buildFilterButton(
                        label: '${store.name} ($couponCount)',
                        isSelected: selectedStoreId == store.slug,
                        onTap: () {
                          setState(() => selectedStoreId = store.slug);
                          _loadData();
                        },
                        isPrimary: false,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: isPrimary
                        ? [
                            const Color(0xFFEC4899),
                            const Color(0xFFEC4899).withOpacity(0.8),
                          ]
                        : [
                            const Color(0xFF6366F1),
                            const Color(0xFF6366F1).withOpacity(0.8),
                          ],
                  )
                : null,
            color: isSelected ? null : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isPrimary
                      ? const Color(0xFFEC4899)
                      : const Color(0xFF6366F1))
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isPrimary
                              ? const Color(0xFFEC4899)
                              : const Color(0xFF6366F1))
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected && isPrimary)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponsGrid() {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Constants.primaryColor),
          ),
        ),
      );
    }

    final displayCoupons = filteredCoupons;

    if (displayCoupons.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(60),
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
                searchQuery.isNotEmpty
                    ? 'لا توجد نتائج للبحث'
                    : 'لا توجد كوبونات متاحة حالياً',
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
      );
    }

    return Container(
      padding: ResponsivePadding.page(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عداد النتائج
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'تم العثور على ${displayCoupons.length} كوبون',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // الشبكة
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveGrid.columns(context, max: 4),
              crossAxisSpacing: ResponsiveGrid.spacing(context),
              mainAxisSpacing: ResponsiveGrid.spacing(context),
              childAspectRatio: 0.75,
            ),
            itemCount: displayCoupons.length,
            itemBuilder: (context, index) {
              final coupon = displayCoupons[index];
              final store = storesMap[coupon.storeId];

              return WebCouponCard(
                coupon: coupon,
                storeName: store?.name ?? 'متجر',
              );
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
