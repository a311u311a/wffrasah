import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/carousel.dart';
import '../models/coupon.dart';
import '../models/offers.dart';
import '../models/store.dart';
import '../providers/locale_provider.dart';
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
  static const Color bg = Color(0xFFFAFAFF);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color panelDark = Color(0xFFF2F0FF);
  static const Color stroke = Color(0xFFE2DEFF);
  static const Color ink = Color(0xFF25213B);
  static const Color orange = Color(0xFF6C63FF);
  static const Color pink = Color(0xFF8B84FF);
  static const Color secondary = Color(0xFF68627F);
  static const Color faded = Color(0xFF9B96B6);

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  final SupabaseClient supabase = Supabase.instance.client;
  List<Carousel> carouselItems = [];
  List<Store> stores = [];
  List<Coupon> coupons = [];
  List<Offer> offers = [];
  @override
  void initState() {
    super.initState();
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
      final carouselData = await supabase.from('carousel').select();
      final storesData = await supabase
          .from('stores')
          .select()
          .order('name_ar', ascending: true);
      final couponsData = await supabase
          .from('coupons')
          .select()
          .eq('approval_status', 'approved')
          .order('created_at', ascending: false)
          .limit(24);
      final offersData = await supabase
          .from('offers')
          .select()
          .order('created_at', ascending: false)
          .limit(12);
      if (!mounted) return;
      setState(() {
        carouselItems = (carouselData as List)
            .map((item) => Carousel.fromMap(item, langCode))
            .toList();
        stores = (storesData as List)
            .where((item) {
              final importSource =
                  (item['import_source'] ?? 'manual').toString();
              final approvalStatus =
                  (item['approval_status'] ?? 'approved').toString();
              return importSource == 'manual' || approvalStatus == 'approved';
            })
            .map((item) => Store.fromSupabase(item, langCode))
            .toList();
        coupons = (couponsData as List)
            .map((item) => Coupon.fromSupabase(item, langCode))
            .toList();
        offers = (offersData as List)
            .map((item) => Offer.fromSupabase(item, langCode))
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        carouselItems = [];
        stores = [];
        coupons = [];
        offers = [];
      });
    }
  }

  Map<String, Store> get _storesMap {
    final map = <String, Store>{};
    for (final store in stores) {
      if (store.id.trim().isNotEmpty) {
        map[store.id.toLowerCase().trim()] = store;
      }
      if (store.slug.trim().isNotEmpty) {
        map[store.slug.toLowerCase().trim()] = store;
      }
    }
    return map;
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
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              WebBannerCarousel(items: carouselItems),
                              if (carouselItems.isNotEmpty)
                                const SizedBox(height: 28),
                              _buildSearch(),
                              const SizedBox(height: 36),
                              _buildStoresSection(),
                              const SizedBox(height: 36),
                              _buildCouponsSection(),
                              const SizedBox(height: 36),
                              _buildOffersSection(),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: focused ? orange : stroke, width: 1.4),
        boxShadow: const [
          BoxShadow(
              color: Color(0x126C63FF), blurRadius: 24, offset: Offset(0, 12)),
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
                  color: ink, fontSize: 15, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'ابحث عن متجر، كوبون، أو عرض ساخن...',
                hintStyle: GoogleFonts.cairo(
                    color: faded, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          );

          if (compact) {
            return Column(
              children: [
                Row(children: [
                  const Icon(Icons.search_rounded, color: secondary),
                  const SizedBox(width: 12),
                  field
                ]),
                const SizedBox(height: 12),
                SizedBox(
                    width: double.infinity,
                    child: _gradientButton(label: 'بحث', onPressed: () {})),
              ],
            );
          }

          return Row(
            children: [
              const Icon(Icons.search_rounded, color: secondary),
              const SizedBox(width: 12),
              field,
              const SizedBox(width: 12),
              _gradientButton(label: 'بحث', onPressed: () {}),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStoresSection() {
    if (stores.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panelDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: stroke),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
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
          final visibleStores = stores.take(columns * 2).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'المتاجر',
                      style: GoogleFonts.cairo(
                        color: ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/stores'),
                    style: TextButton.styleFrom(
                      foregroundColor: orange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      'تصفح أكثر',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: stroke),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F6C63FF),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: store.image.isEmpty
                    ? Icon(Icons.store_rounded, color: orange, size: 42)
                    : Image.network(
                        store.image,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.store_rounded, color: orange, size: 42),
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
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponsSection() {
    if (coupons.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panelDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: stroke),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = ResponsiveGrid.columnsForWidth(width, max: 6);
          final visibleCoupons = coupons.take(columns * 2).toList();
          final storesMap = _storesMap;
          final spacing = ResponsiveGrid.spacingForWidth(width);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'الكوبونات',
                      style: GoogleFonts.cairo(
                        color: ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/coupons'),
                    style: TextButton.styleFrom(
                      foregroundColor: orange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      'تصفح أكثر',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleCoupons.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: width >= 1024 ? 0.58 : 0.62,
                ),
                itemBuilder: (context, index) {
                  final coupon = visibleCoupons[index];
                  final store = storesMap[coupon.storeId.toLowerCase().trim()];
                  return WebCouponCard(
                    coupon: coupon,
                    storeName: store?.name ?? 'متجر',
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

  Widget _buildOffersSection() {
    if (offers.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panelDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: stroke),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = ResponsiveGrid.columnsForWidth(width, max: 4);
          final visibleOffers = offers.take(columns).toList();
          final storesMap = _storesMap;
          final spacing = ResponsiveGrid.spacingForWidth(width);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'العروض',
                      style: GoogleFonts.cairo(
                        color: ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/offers'),
                    style: TextButton.styleFrom(
                      foregroundColor: orange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      'تصفح أكثر',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                    storeName: store?.name ?? 'متجر',
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
