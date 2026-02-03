import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/coupon.dart';
import '../models/offers.dart';
import '../models/store.dart';
import '../providers/favorites_provider.dart';
import '../providers/locale_provider.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';
import '../web_widgets/web_coupon_card.dart';
import '../web_widgets/web_offer_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// صفحة المفضلة للويب
class WebFavoritesScreen extends StatefulWidget {
  const WebFavoritesScreen({super.key});

  @override
  State<WebFavoritesScreen> createState() => _WebFavoritesScreenState();
}

class _WebFavoritesScreenState extends State<WebFavoritesScreen> {
  final supabase = Supabase.instance.client;
  List<Coupon> favoriteCoupons = [];
  List<Offer> favoriteOffers = [];
  Map<String, Store> storesMap = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => isLoading = true);

    final favoriteProvider =
        Provider.of<FavoriteProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final langCode = localeProvider.locale.languageCode;

    try {
      // Load stores for displaying store names
      final storesData = await supabase.from('stores').select();
      final loadedStores = (storesData as List)
          .map((store) => Store.fromSupabase(store, langCode))
          .toList();

      final tempMap = <String, Store>{};
      for (var store in loadedStores) {
        tempMap[store.id.toLowerCase().trim()] = store;
        if (store.slug.isNotEmpty) {
          tempMap[store.slug.toLowerCase().trim()] = store;
        }
      }
      storesMap = tempMap;

      // Get favorites from provider (contains both Coupons and Offers)
      final allFavorites = favoriteProvider.favoriteItems;

      // Separate coupons and offers
      final coupons = <Coupon>[];
      final offers = <Offer>[];

      for (final item in allFavorites) {
        if (item is Coupon) {
          coupons.add(item);
        } else if (item is Offer) {
          offers.add(item);
        }
      }

      setState(() {
        favoriteCoupons = coupons;
        favoriteOffers = offers;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const WebNavigationBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildFavoritesGrid(),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final totalItems = favoriteCoupons.length + favoriteOffers.length;
    return Container(
      padding: ResponsivePadding.page(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Constants.primaryColor.withValues(alpha: 0.1),
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
              Icon(
                Icons.favorite,
                color: Constants.primaryColor,
                size: ResponsiveLayout.isDesktop(context) ? 48 : 36,
              ),
              const SizedBox(width: 16),
              Text(
                'المفضلة',
                style: TextStyle(
                  fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
                  fontWeight: FontWeight.w900,
                  color: Constants.primaryColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'الكوبونات والعروض المحفوظة في قائمتك المفضلة',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontFamily: 'Tajawal',
            ),
          ),
          if (!isLoading && totalItems > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'لديك $totalItems عنصر في المفضلة',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFavoritesGrid() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isEmpty = favoriteCoupons.isEmpty && favoriteOffers.isEmpty;

    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Column(
            children: [
              Icon(
                Icons.favorite_border,
                size: 100,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 20),
              Text(
                'لا توجد عناصر في المفضلة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ابدأ بإضافة الكوبونات والعروض التي تعجبك إلى المفضلة',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/'),
                icon: const Icon(Icons.explore_rounded),
                label: const Text(
                  'استكشف الكوبونات والعروض',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Tajawal',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
          // قسم العروض
          if (favoriteOffers.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.local_offer,
                    color: Constants.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'العروض المفضلة (${favoriteOffers.length})',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Constants.primaryColor,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveGrid.columns(context, max: 4),
                crossAxisSpacing: ResponsiveGrid.spacing(context),
                mainAxisSpacing: ResponsiveGrid.spacing(context),
                childAspectRatio: 0.8,
              ),
              itemCount: favoriteOffers.length,
              itemBuilder: (context, index) {
                final offer = favoriteOffers[index];
                final store = storesMap[offer.storeId.toLowerCase().trim()];
                return WebOfferCard(
                  offer: offer,
                  storeName: store?.name,
                  storeImage: store?.image,
                );
              },
            ),
            const SizedBox(height: 40),
          ],

          // قسم الكوبونات
          if (favoriteCoupons.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.confirmation_number,
                    color: Constants.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'الكوبونات المفضلة (${favoriteCoupons.length})',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Constants.primaryColor,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveGrid.columns(context, max: 4),
                crossAxisSpacing: ResponsiveGrid.spacing(context),
                mainAxisSpacing: ResponsiveGrid.spacing(context),
                childAspectRatio: 0.75,
              ),
              itemCount: favoriteCoupons.length,
              itemBuilder: (context, index) {
                final coupon = favoriteCoupons[index];
                final store = storesMap[coupon.storeId.toLowerCase().trim()];
                return WebCouponCard(
                  coupon: coupon,
                  storeName: store?.name,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
