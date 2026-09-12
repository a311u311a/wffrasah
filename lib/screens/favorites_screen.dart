import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/app_localizations.dart';
import '../screens/login_signup/widgets/snackbar.dart';
import '../models/coupon.dart';
import '../models/offers.dart';
import '../models/store.dart';
import '../providers/favorites_provider.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/app_responsive.dart';
import '../widgets/coupon_card.dart';
import '../widgets/offers_card.dart';
import '../widgets/loading_indicator.dart';
import '../constants.dart';
import 'package:lottie/lottie.dart';
import '../widgets/search_widget.dart';
import 'store_coupons_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String searchQuery = ''; // نص البحث
  int _selectedFavoriteTab = 0;
  List<Store> followedStores = [];
  bool _storesLoading = true;
  bool _didLoadStores = false;
  bool _favoriteStoreAlertsEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadStores) {
      _didLoadStores = true;
      _loadFollowedStores();
      _loadFavoriteStoreAlertsPreference();
    }
  }

  Future<void> _loadFavoriteStoreAlertsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favoriteStoreAlertsEnabled =
          prefs.getBool('favorite_store_notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleFavoriteStoreAlerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('favorite_store_notifications_enabled', value);
    if (!mounted) return;
    setState(() => _favoriteStoreAlertsEnabled = value);
    showSnackBar(
      context,
      value
          ? 'تم تفعيل تنبيهات المتاجر المفضلة'
          : 'تم إيقاف تنبيهات المتاجر المفضلة',
    );
  }

  Future<void> _loadFollowedStores() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          followedStores = [];
          _storesLoading = false;
        });
      }
      return;
    }

    try {
      final langCode =
          AppLocalizations.of(context)?.locale.languageCode ?? 'ar';
      final followRows = await Supabase.instance.client
          .from('store_follows')
          .select('store_id')
          .eq('user_id', user.id);
      final followedKeys = (followRows as List)
          .map((row) => (row['store_id'] ?? '').toString().trim())
          .where((key) => key.isNotEmpty)
          .toSet();

      if (followedKeys.isEmpty) {
        if (mounted) {
          setState(() {
            followedStores = [];
            _storesLoading = false;
          });
        }
        return;
      }

      final storeRows = await Supabase.instance.client.from('stores').select();
      final stores = (storeRows as List)
          .cast<Map<String, dynamic>>()
          .map((row) => Store.fromSupabase(row, langCode))
          .where((store) =>
              followedKeys.contains(store.id) ||
              followedKeys.contains(store.slug))
          .toList();

      if (mounted) {
        setState(() {
          followedStores = stores;
          _storesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _storesLoading = false);
    }
  }

  Future<void> _unfollowStore(Store store) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final keys = {store.id, store.slug}.where((key) => key.trim().isNotEmpty);
    for (final key in keys) {
      await Supabase.instance.client
          .from('store_follows')
          .delete()
          .eq('user_id', user.id)
          .eq('store_id', key);
    }

    if (!mounted) return;
    setState(() => followedStores.removeWhere((item) => item.key == store.key));
    showSnackBar(context, 'تمت إزالة المتجر من المفضلة');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;

    // تصفية العناصر بناءً على البحث
    final filteredItems = favoriteProvider.favoriteItems.where((item) {
      if (searchQuery.isEmpty) return true;
      final query = searchQuery.toLowerCase();
      if (item is Coupon) {
        return item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query);
      } else if (item is Offer) {
        return item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query);
      }
      return false;
    }).toList();
    final filteredStores = followedStores.where((store) {
      if (searchQuery.isEmpty) return true;
      final query = searchQuery.toLowerCase();
      return store.name.toLowerCase().contains(query) ||
          store.description.toLowerCase().contains(query);
    }).toList();
    final hasAnyFavorites =
        favoriteProvider.favoriteItems.isNotEmpty ||
        followedStores.isNotEmpty ||
        isLoggedIn;
    final hasSearchResults = _selectedFavoriteTab == 0
        ? filteredItems.isNotEmpty
        : filteredStores.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true, // تمديد الخلفية خلف شريط العنوان
      backgroundColor: Colors.white, // خلفية بيضاء أساسية
      resizeToAvoidBottomInset:
          false, // لمنع اهتزاز المحتوى عند ظهور لوحة المفاتيح
      appBar: appBarItem(localizations),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppResponsive.contentMaxWidth(context),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
                bottom: 60, top: 10), // هامش سفلي لكامل الصفحة
            child: SizedBox.expand(
              child: Container(
                color: Colors.white,
                child: !hasAnyFavorites && !_storesLoading
                    ? _buildEmptyState(context, localizations)
                    : (!hasSearchResults && searchQuery.isNotEmpty)
                        ? _buildNoSearchResults(context, localizations)
                        : _buildFavoritesSections(
                            context,
                            localizations,
                            filteredStores,
                            filteredItems,
                            favoriteProvider,
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesSections(
    BuildContext context,
    AppLocalizations? localizations,
    List<Store> stores,
    List<dynamic> items,
    FavoriteProvider favoriteProvider,
  ) {
    return Column(
      children: [
        const SizedBox(height: 104),
        if (Supabase.instance.client.auth.currentUser != null) ...[
          const SizedBox(height: 16),
          _FavoriteStoreAlertsCard(
            enabled: _favoriteStoreAlertsEnabled,
            followedCount: followedStores.length,
            onChanged: _toggleFavoriteStoreAlerts,
          ),
          const SizedBox(height: 6),
        ],
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 0, bottom: 24),
            children: [
              _FavoriteTabs(
                selectedIndex: _selectedFavoriteTab,
                onChanged: (index) =>
                    setState(() => _selectedFavoriteTab = index),
              ),
              SizedBox(height: _selectedFavoriteTab == 1 ? 0 : 18),
              if (_selectedFavoriteTab == 0) ...[
                if (items.isNotEmpty)
                  ...items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Dismissible(
                        key: Key((item as dynamic).id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.delete_sweep_rounded,
                                  color: Colors.white, size: 28),
                              const SizedBox(height: 4),
                              Text(
                                localizations?.translate('delete') ?? 'Delete',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              )
                            ],
                          ),
                        ),
                        onDismissed: (direction) {
                          favoriteProvider.toggleFavorite(item, context);
                          showSnackBar(
                            context,
                            localizations
                                    ?.translate('removed_from_favorites') ??
                                'Removed from favorites',
                          );
                        },
                        child: item is Coupon
                            ? CouponCard(coupon: item)
                            : OffersCard(offer: item as Offer),
                      ),
                    );
                  })
                else
                  const _SectionEmptyState(
                    icon: Icons.confirmation_number_rounded,
                    text: 'لا توجد كوبونات أو عروض مفضلة',
                  ),
              ] else ...[
                if (_storesLoading)
                  const CustomLoadingIndicator(
                    message: 'جاري تحميل المتاجر المتابعة',
                    padding: EdgeInsets.symmetric(vertical: 24),
                  )
                else if (stores.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: GridView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                        top: 14,
                        bottom: 14,
                      ),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stores.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: AppResponsive.gridColumns(
                          context,
                          phone: 3,
                          tablet: 5,
                        ),
                        crossAxisSpacing:
                            AppResponsive.isTablet(context) ? 18 : 12,
                        mainAxisSpacing:
                            AppResponsive.isTablet(context) ? 22 : 16,
                        childAspectRatio:
                            AppResponsive.isTablet(context) ? 0.96 : 0.82,
                      ),
                      itemBuilder: (context, index) {
                        final store = stores[index];
                        return _FavoriteStoreCard(
                          store: store,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StoreCouponsScreen(store: store),
                            ),
                          ),
                          onRemove: () => _unfollowStore(store),
                        );
                      },
                    ),
                  )
                else
                  const _SectionEmptyState(
                    icon: Icons.storefront_rounded,
                    text: 'لا توجد متاجر مفضلة',
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget appBarItem(AppLocalizations? localizations) {
    return AppBar(
      toolbarHeight: 80, // Same as CouponScreen after user's change
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
      automaticallyImplyLeading: false,
      title: SearchWidget(
        hintText: localizations?.translate('search_favorites_hint') ??
            'ابحث في المفضلة',
        onSearch: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
      centerTitle: true,
    );
  }

  Widget _buildEmptyState(
      BuildContext context, AppLocalizations? localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/coupon_animation.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.favorite_border_rounded,
                  size: 80, color: Colors.grey[300]);
            },
          ),
          const SizedBox(height: 16),
          Text(
            localizations?.translate('favorites_list_empty') ??
                'Favorites list is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Constants.textColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations?.translate('favorites_empty_subtitle') ??
                'Start adding coupons you like\nto find them here later',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Tajawal',
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const BottomNavBar()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              textStyle: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(
              localizations?.translate('discover_coupons') ??
                  'Discover Coupons',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults(
      BuildContext context, AppLocalizations? localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "لا توجد نتائج مطابقة",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _FavoriteTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Constants.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: _FavoriteTabButton(
                label: 'الكوبونات والعروض',
                icon: Icons.confirmation_number_rounded,
                selected: selectedIndex == 0,
                onTap: () => onChanged(0),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _FavoriteTabButton(
                label: 'المتاجر المفضلة',
                icon: Icons.storefront_rounded,
                selected: selectedIndex == 1,
                onTap: () => onChanged(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteStoreAlertsCard extends StatelessWidget {
  final bool enabled;
  final int followedCount;
  final ValueChanged<bool> onChanged;

  const _FavoriteStoreAlertsCard({
    required this.enabled,
    required this.followedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Constants.primaryColor.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Constants.primaryColor.withValues(alpha: 0.07),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Constants.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: Constants.primaryColor,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تنبيهات المتاجر المفضلة',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Constants.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'يصلك تنبيه عند إضافة كوبون جديد لمتاجرك المفضلة',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$followedCount متجر متابع',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Constants.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              activeThumbColor: Constants.primaryColor,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FavoriteTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Constants.primaryColor : Constants.textColor;

    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionEmptyState({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[500],
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteStoreCard extends StatefulWidget {
  final Store store;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteStoreCard({
    required this.store,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<_FavoriteStoreCard> createState() => _FavoriteStoreCardState();
}

class _FavoriteStoreCardState extends State<_FavoriteStoreCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Constants.primaryColor.withValues(alpha: 0.22),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: Constants.primaryColor.withValues(alpha: 0.07),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: widget.store.image.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: CachedNetworkImage(
                                    imageUrl: widget.store.image,
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
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.storefront_rounded,
                                      color: Constants.primaryColor
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.storefront_rounded,
                                  color: Constants.primaryColor
                                      .withValues(alpha: 0.35),
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0.4,
                      top: 0.4,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: widget.onRemove,
                          borderRadius: BorderRadius.circular(999),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: SvgPicture.asset(
                              'assets/icon/star_active.svg',
                              width: 15,
                              height: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: const Color(0xFFE8E6EE),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 20,
                width: double.infinity,
                child: Text(
                  widget.store.name,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Tajawal',
                    color: Constants.textColor,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
