import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../models/offers.dart';
import '../models/store.dart';
import '../providers/locale_provider.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';
import '../web_widgets/web_offer_card.dart'; // ✅ استيراد المكون العالمي

/// صفحة العروض للويب
class WebOffersScreen extends StatefulWidget {
  const WebOffersScreen({super.key});

  @override
  State<WebOffersScreen> createState() => _WebOffersScreenState();
}

class _WebOffersScreenState extends State<WebOffersScreen> {
  final supabase = Supabase.instance.client;
  List<Offer> offers = [];
  Map<String, Store> storesMap = {};
  bool isLoading = true;

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
      // Load stores first
      final storesData = await supabase.from('stores').select();

      final loadedStores = (storesData as List)
          .map((store) => Store.fromSupabase(store, langCode))
          .toList();

      final tempMap = <String, Store>{};
      for (var store in loadedStores) {
        // الربط بالـ ID والـ Slug مع توحيد حالة الأحرف والمسافات
        tempMap[store.id.toLowerCase().trim()] = store;
        if (store.slug.isNotEmpty) {
          tempMap[store.slug.toLowerCase().trim()] = store;
        }
      }
      storesMap = tempMap;

      // Load offers
      final offersData =
          await supabase.from('offers').select().order('id', ascending: false);

      final loadedOffers = (offersData as List)
          .map((offer) => Offer.fromSupabase(offer, langCode))
          .toList();

      setState(() {
        offers = loadedOffers;
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
            _buildOffersGrid(),
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
            Constants.primaryColor.withValues(alpha: 0.1),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'العروض الخاصة',
            style: TextStyle(
              fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'اكتشف أفضل العروض والخصومات الحصرية',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOffersGrid() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (offers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Column(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 20),
              Text(
                'لا توجد عروض متاحة حالياً',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: ResponsivePadding.page(context),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              ResponsiveGrid.columns(context, max: 4), // ✅ تغيير من 3 إلى 4
          crossAxisSpacing: ResponsiveGrid.spacing(context),
          mainAxisSpacing: ResponsiveGrid.spacing(context),
          childAspectRatio: 0.8, // ✅ تحسين النسبة لتناسب 4 أعمدة
        ),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          final store = storesMap[offer.storeId.toLowerCase().trim()];
          return WebOfferCard(
            offer: offer,
            storeName: store?.name ?? 'متجر',
            storeImage: store?.image,
          );
        },
      ),
    );
  }
}
