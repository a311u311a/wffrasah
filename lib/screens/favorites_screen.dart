import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../Login Signup/Widget/snackbar.dart';
import '../models/coupon.dart';
import '../models/offers.dart';
import '../providers/favorites_provider.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/coupon_card.dart';
import '../widgets/offers_card.dart';
import '../constants.dart';
import 'package:lottie/lottie.dart';
import '../widgets/search_widget.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String searchQuery = ''; // نص البحث

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final favoriteProvider = Provider.of<FavoriteProvider>(context);

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

    return Scaffold(
      extendBodyBehindAppBar: true, // تمديد الخلفية خلف شريط العنوان
      backgroundColor: Colors.white, // خلفية بيضاء أساسية
      resizeToAvoidBottomInset:
          false, // لمنع اهتزاز المحتوى عند ظهور لوحة المفاتيح
      appBar: appBarItem(localizations),
      body: Padding(
        padding: const EdgeInsets.only(
            bottom: 60, top: 10), // هامش سفلي لكامل الصفحة
        child: Container(
          color: Colors.white,
          child: favoriteProvider.favoriteItems.isEmpty
              ? _buildEmptyState(context, localizations)
              : (filteredItems.isEmpty && searchQuery.isNotEmpty)
                  ? _buildNoSearchResults(context, localizations)
                  : ListView.builder(
                      // تعديل البادينج لتعويض AppBar الشفاف
                      padding: const EdgeInsets.only(top: 100, bottom: 20),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.delete_sweep_rounded,
                                      color: Colors.white, size: 28),
                                  const SizedBox(height: 4),
                                  Text(
                                    localizations?.translate('delete') ??
                                        'Delete',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11),
                                  )
                                ],
                              ),
                            ),
                            onDismissed: (direction) {
                              favoriteProvider.toggleFavorite(item);
                              showSnackBar(
                                context,
                                localizations
                                        ?.translate('removed_from_favorites') ??
                                    'Removed from favorites',
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: item is Coupon
                                  ? CouponCard(coupon: item)
                                  : OffersCard(offer: item),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
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
              Constants.primaryColor.withOpacity(0.1),
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
              color: Colors.black87,
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
