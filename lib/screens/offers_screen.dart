import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../localization/app_localizations.dart';
import '../models/store.dart';
import '../widgets/app_responsive.dart';
import '../widgets/carouse.dart';
import '../widgets/category_list.dart';
import '../widgets/search_widget.dart';
import 'store_coupons_screen.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  String? selectedCategoryId;
  String searchQuery = '';

  late Future<List<Store>> _offerStoresFuture;
  late Future<List<Map<String, dynamic>>> _offersFuture;

  @override
  void initState() {
    super.initState();
    _offerStoresFuture = _fetchOfferStores();
    _offersFuture = _fetchOffers();
  }

  // ============================================================
  // جلب المتاجر التي تحتوي على عروض
  // ============================================================

  Future<List<Store>> _fetchOfferStores() async {
    final sb = Supabase.instance.client;

    final results = await Future.wait([
      sb
          .from('offers')
          .select('store_id')
          .order('created_at', ascending: false),
      sb.from('stores').select().order('created_at', ascending: false),
    ]);

    final offerStoreIds = (results[0] as List)
        .map((offer) => (offer['store_id'] ?? '').toString().trim())
        .where((storeId) => storeId.isNotEmpty)
        .toSet();

    if (offerStoreIds.isEmpty) return [];

    final stores = (results[1] as List)
        .cast<Map<String, dynamic>>()
        .map((row) => Store.fromSupabase(row, 'ar'))
        .toList();

    final seen = <String>{};
    final ordered = <Store>[];

    for (final store in stores) {
      final storeKeys = {
        store.id,
        store.slug,
        store.name,
        store.nameAr,
        store.nameEn,
      }.map((value) => value.trim()).where((value) => value.isNotEmpty).toSet();

      if (!storeKeys.any(offerStoreIds.contains)) continue;
      if (seen.contains(store.key)) continue;

      seen.add(store.key);
      ordered.add(store);
    }

    return ordered;
  }

  // ============================================================
  // جلب العروض
  // ============================================================

  Future<List<Map<String, dynamic>>> _fetchOffers() async {
    final sb = Supabase.instance.client;

    try {
      final rows = await sb.from('offers').select('''
            id,
            category_id,
            created_at,
            description,
            description_ar,
            description_en,
            image,
            name,
            name_ar,
            name_en,
            web,
            store_id,
            expiry_date
            ''').order('created_at', ascending: false).limit(100);

      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Offers fetch error: $e');
      rethrow;
    }
  }

  // ============================================================
  // تحديث الصفحة
  // ============================================================

  Future<void> _refreshData() async {
    setState(() {
      _offerStoresFuture = _fetchOfferStores();
      _offersFuture = _fetchOffers();
    });

    await Future.wait([
      _offerStoresFuture,
      _offersFuture,
    ]);
  }

  // ============================================================
  // فتح رابط العرض
  // ============================================================

  Future<void> _openOffer(String? url) async {
    if (url == null || url.trim().isEmpty) return;

    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح رابط العرض')),
        );
      }
    } catch (e) {
      debugPrint('Open offer error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح رابط العرض')),
      );
    }
  }

  // ============================================================
  // اسم العرض
  // ============================================================

  String _firstNonEmpty(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = (data[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }

    return '';
  }

  String _offerName(Map<String, dynamic> offer) {
    final nameAr = _firstNonEmpty(offer, ['name_ar', 'nameAr']);
    final name = _firstNonEmpty(offer, ['name', 'title']);
    final nameEn = _firstNonEmpty(offer, ['name_en', 'nameEn']);

    if (nameAr.isNotEmpty) return nameAr;
    if (name.isNotEmpty) return name;
    if (nameEn.isNotEmpty) return nameEn;

    return 'عرض';
  }

  // ============================================================
  // وصف العرض
  // ============================================================

  String _offerDescription(Map<String, dynamic> offer) {
    final descriptionAr =
        _firstNonEmpty(offer, ['description_ar', 'descriptionAr']);
    final description = _firstNonEmpty(offer, ['description', 'desc']);
    final descriptionEn =
        _firstNonEmpty(offer, ['description_en', 'descriptionEn']);

    if (descriptionAr.isNotEmpty) return descriptionAr;
    if (description.isNotEmpty) return description;
    if (descriptionEn.isNotEmpty) return descriptionEn;

    return '';
  }

  // ============================================================
  // فلترة العروض
  // ============================================================

  List<Map<String, dynamic>> _filterOffers(List<Map<String, dynamic>> offers) {
    final query = searchQuery.trim().toLowerCase();

    return offers.where((offer) {
      if (selectedCategoryId != null && selectedCategoryId!.trim().isNotEmpty) {
        final categoryId = (offer['category_id'] ?? '').toString();
        if (categoryId != selectedCategoryId) return false;
      }

      if (query.isEmpty) return true;

      final name = _offerName(offer).toLowerCase();
      final description = _offerDescription(offer).toLowerCase();

      return name.contains(query) || description.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> _latestOfferPerStore(
    List<Map<String, dynamic>> offers,
  ) {
    final seenStoreIds = <String>{};
    final latestOffers = <Map<String, dynamic>>[];

    for (final offer in offers) {
      final storeId = (offer['store_id'] ?? '').toString().trim();
      final key = storeId.isNotEmpty ? storeId : (offer['id'] ?? '').toString();

      if (seenStoreIds.contains(key)) continue;

      seenStoreIds.add(key);
      latestOffers.add(offer);
    }

    return latestOffers;
  }

  // ============================================================
  // الصفحة الرئيسية
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: appBarItem(localizations),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 85,
            bottom: 60,
          ),
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // الكاروسيل
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 150,
                    child: CustomCarousel(),
                  ),
                ),

                // التصنيفات
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 95,
                    child: CategoryList(
                      selectedCategoryId: selectedCategoryId,
                      onCategorySelected: (categoryId) {
                        setState(() {
                          selectedCategoryId = categoryId;
                        });
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // المتاجر التي تحتوي على عروض
                SliverToBoxAdapter(
                  child: _buildOfferStoresSection(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // عنوان العروض
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'أحدث العروض',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                          color: Color(0xFF1E2946),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // العروض
                _buildOffersSliver(),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // المتاجر التي تحتوي على عروض
  // ============================================================

  Widget _buildOfferStoresSection() {
    return FutureBuilder<List<Store>>(
      future: _offerStoresFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final stores = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'المتاجر',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                    color: Color(0xFF1E2946),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: AppResponsive.isTablet(context) ? 240 : 210,
              child: GridView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: AppResponsive.isTablet(context) ? 28 : 16,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: stores.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppResponsive.isTablet(context) ? 16 : 12,
                  mainAxisSpacing: AppResponsive.isTablet(context) ? 16 : 12,
                  childAspectRatio:
                      AppResponsive.isTablet(context) ? 0.85 : 0.78,
                ),
                itemBuilder: (context, index) {
                  final store = stores[index];
                  final displayName =
                      store.name.trim().isNotEmpty ? store.name : store.nameAr;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreCouponsScreen(store: store),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (store.image.trim().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: store.image,
                                width: 76,
                                height: 54,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    _fallbackBrandIcon(store.slug),
                              ),
                            )
                          else
                            _fallbackBrandIcon(store.slug),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Tajawal',
                                color: Color(0xFF1E2946),
                              ),
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
        );
      },
    );
  }

  // ============================================================
  // قائمة العروض
  // ============================================================

  Widget _buildOffersSliver() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _offersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'تعذر تحميل العروض',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _offersFuture = _fetchOffers();
                        });
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final offers = _latestOfferPerStore(_filterOffers(snapshot.data!));

        if (offers.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 35, horizontal: 20),
              child: Center(
                child: Text(
                  'لا توجد عروض حالياً',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          );
        }

        if (!AppResponsive.isTablet(context)) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final offer = offers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildOfferCard(offer),
                  );
                },
                childCount: offers.length,
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 460,
              mainAxisExtent: 160,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildOfferCard(offers[index]),
              childCount: offers.length,
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // بطاقة العرض (تم توضيح الارتفاع الثابت لمنع التجميد)
  // ============================================================

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final name = _offerName(offer);
    final description = _offerDescription(offer);
    final image = (offer['image'] ?? '').toString().trim();
    final web = (offer['web'] ?? '').toString().trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: web.isEmpty ? null : () => _openOffer(web),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 140),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // الصورة
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                child: _buildOfferImage(image),
              ),

              // البيانات
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2946),
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (web.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 14,
                              color: Color(0xFF665CFF),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'اذهب للعرض',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF665CFF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // صورة العرض
  // ============================================================

  Widget _buildOfferImage(String image) {
    if (image.isEmpty) {
      return Container(
        width: 125,
        height: 125,
        color: Colors.grey.shade100,
        child: Icon(
          Icons.image_outlined,
          size: 34,
          color: Colors.grey.shade400,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: image,
      width: 125,
      height: 125,
      fit: BoxFit.cover,
      memCacheWidth: 250,
      memCacheHeight: 250,
      placeholder: (context, url) => Container(
        width: 125,
        height: 125,
        color: Colors.grey.shade100,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: 125,
        height: 125,
        color: Colors.grey.shade100,
        child: Icon(
          Icons.broken_image_outlined,
          size: 32,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  // ============================================================
  // أيقونة المتجر الاحتياطية
  // ============================================================

  Widget _fallbackBrandIcon(String slug) {
    final icon = _storeBrandIcon(slug);
    final colors = _storeBrandColors(slug);

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 25,
      ),
    );
  }

  // ============================================================
  // أيقونات المتاجر
  // ============================================================

  IconData _storeBrandIcon(String slug) {
    switch (slug.toLowerCase()) {
      case 'aliexpress':
        return Icons.shopping_bag_rounded;
      case 'temu':
        return Icons.local_offer_rounded;
      case 'shein':
        return Icons.style_rounded;
      case 'amazon':
        return Icons.card_travel_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

  // ============================================================
  // ألوان المتاجر
  // ============================================================

  List<Color> _storeBrandColors(String slug) {
    switch (slug.toLowerCase()) {
      case 'aliexpress':
        return [const Color(0xFFEA5C2B), const Color(0xFFFACF5A)];
      case 'temu':
        return [const Color(0xFF4CAF50), const Color(0xFF7BD389)];
      case 'shein':
        return [const Color(0xFFE91E63), const Color(0xFFFFB3C6)];
      case 'amazon':
        return [const Color(0xFFFFA726), const Color(0xFFFFD54F)];
      default:
        return [const Color(0xFF3F51B5), const Color(0xFF8E99F3)];
    }
  }

  // ============================================================
  // AppBar
  // ============================================================

  PreferredSizeWidget appBarItem(AppLocalizations? localizations) {
    return AppBar(
      toolbarHeight: 80,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Constants.primaryColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: SearchWidget(
        hintText:
            localizations?.translate('search_offer_hint') ?? 'البحث عن عرض',
        onSearch: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }
}
