import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
import '../web_widgets/web_store_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../localization/app_localizations.dart';

/// صفحة المفضلة للويب
class WebFavoritesScreen extends StatefulWidget {
  const WebFavoritesScreen({super.key});

  @override
  State<WebFavoritesScreen> createState() => _WebFavoritesScreenState();
}

class _WebFavoritesScreenState extends State<WebFavoritesScreen> {
  static const Color bg = Color(0xFFFAFAFF);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color panelDark = Color(0xFFF2F0FF);
  static const Color stroke = Color(0xFFE2DEFF);
  static const Color line = Color(0xFFEDEAFF);
  static const Color ink = Color(0xFF25213B);
  static const Color orange = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF68627F);
  static const Color faded = Color(0xFF9B96B6);

  final supabase = Supabase.instance.client;
  List<Coupon> favoriteCoupons = [];
  List<Offer> favoriteOffers = [];
  List<Store> favoriteStores = [];
  Map<String, Store> storesMap = {};
  bool isLoading = true;
  int selectedFavoriteTab = 0;

  String _t(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

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
          .where((store) {
            final importSource =
                (store['import_source'] ?? 'manual').toString();
            final approvalStatus =
                (store['approval_status'] ?? 'approved').toString();
            return importSource == 'manual' || approvalStatus == 'approved';
          })
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
      final user = supabase.auth.currentUser;
      final followedStoreIds = <String>{};
      if (user != null) {
        final followRows = await supabase
            .from('store_follows')
            .select('store_id')
            .eq('user_id', user.id);
        followedStoreIds.addAll((followRows as List)
            .map((row) => (row['store_id'] ?? '').toString().trim())
            .where((id) => id.isNotEmpty));
      }

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
      final stores = loadedStores.where((store) {
        return followedStoreIds.contains(store.id) ||
            followedStoreIds.contains(store.slug);
      }).toList();

      setState(() {
        favoriteStores = stores;
        favoriteCoupons = coupons;
        favoriteOffers = offers;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_t('error_prefix')}: $e')),
        );
      }
    }
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
          body: SingleChildScrollView(
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
                          _buildHeroHeader(),
                          const SizedBox(height: 28),
                          _buildFavoritesSection(),
                        ],
                      ),
                    ),
                  ),
                ),
                const WebFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveLayout.isDesktop(context) ? 28 : 20),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: stroke),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A6C63FF),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('favorites_hero_title'),
                style: GoogleFonts.cairo(
                  color: orange,
                  fontSize: compact ? 28 : 38,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _t('favorites_hero_subtitle'),
                style: GoogleFonts.cairo(
                  color: secondary,
                  fontSize: compact ? 14 : 16,
                  height: 1.9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFavoritesSection() {
    return _buildSection(
      title: _t('favorites'),
      subtitle: _t('favorites_page_subtitle'),
      child: _buildFavoritesGrid(),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panelDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              color: ink,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.cairo(
              color: secondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          child,
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

    final isEmpty = favoriteStores.isEmpty &&
        favoriteCoupons.isEmpty &&
        favoriteOffers.isEmpty;

    if (isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: stroke),
        ),
        child: Column(
          children: [
            const Icon(Icons.favorite_border, size: 90, color: faded),
            const SizedBox(height: 20),
            Text(
              _t('favorites_empty_title'),
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: secondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _t('favorites_empty_subtitle'),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/'),
              icon: const Icon(Icons.explore_rounded),
              label: Text(
                _t('explore_coupons_offers'),
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFavoriteTabs(),
        const SizedBox(height: 24),
        if (selectedFavoriteTab == 0) ...[
          if (favoriteStores.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = ResponsiveGrid.columnsForWidth(width, max: 4);
                final spacing = ResponsiveGrid.spacingForWidth(width);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: width >= 1024 ? 0.86 : 0.78,
                  ),
                  itemCount: favoriteStores.length,
                  itemBuilder: (context, index) {
                    final store = favoriteStores[index];
                    return WebStoreCard(
                      store: store,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/store/${store.key}',
                        arguments: store,
                      ),
                    );
                  },
                );
              },
            )
          else
            _buildSectionEmptyState(
              icon: Icons.storefront_rounded,
              text: 'لا توجد متاجر مفضلة',
            ),
        ] else ...[
          if (favoriteCoupons.isNotEmpty || favoriteOffers.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = ResponsiveGrid.columnsForWidth(width, max: 4);
                final spacing = ResponsiveGrid.spacingForWidth(width);
                final items = <dynamic>[
                  ...favoriteCoupons,
                  ...favoriteOffers,
                ];

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: width >= 1024 ? 2.5 : 1.9,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is Coupon) {
                      final store =
                          storesMap[item.storeId.toLowerCase().trim()];
                      return WebCouponCard(
                        coupon: item,
                        storeName: store?.name,
                        compact: true,
                      );
                    }
                    final offer = item as Offer;
                    final store = storesMap[offer.storeId.toLowerCase().trim()];
                    return WebOfferCard(
                      offer: offer,
                      storeName: store?.name,
                      storeImage: store?.image,
                    );
                  },
                );
              },
            )
          else
            _buildSectionEmptyState(
              icon: Icons.confirmation_number_rounded,
              text: 'لا توجد كوبونات أو عروض مفضلة',
            ),
        ],
      ],
    );
  }

  Widget _buildFavoriteTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFavoriteTabButton(
              index: 0,
              icon: Icons.storefront_rounded,
              label: 'المتاجر المفضلة',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFavoriteTabButton(
              index: 1,
              icon: Icons.confirmation_number_rounded,
              label: 'الكوبونات والعروض',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = selectedFavoriteTab == index;
    final color = selected ? orange : secondary;

    return Material(
      color: selected ? const Color(0xFFF0EEFF) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => selectedFavoriteTab = index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionEmptyState({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 70),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stroke),
      ),
      child: Column(
        children: [
          Icon(icon, size: 70, color: faded),
          const SizedBox(height: 14),
          Text(
            text,
            style: GoogleFonts.cairo(
              color: secondary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
