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
  List<Offer> allOffers = [];
  Map<String, Store> storesMap = {};
  bool isLoading = true;
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
        allOffers = loadedOffers;
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

  List<Offer> get filteredOffers {
    if (searchQuery.isEmpty) return offers;

    return offers.where((offer) {
      final store = storesMap[offer.storeId.toLowerCase().trim()];
      return offer.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          offer.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (store?.name.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const WebNavigationBar(),
      body: Column(
        children: [
          // ✅ Header ثابت في الأعلى
          _buildHeader(),
          // ✅ المحتوى القابل للتمرير
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOffersGrid(),
                  const WebFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsivePadding.page(context).horizontal,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Constants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_offer_rounded,
              color: Constants.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'العروض الخاصة',
            style: TextStyle(
              fontSize: ResponsiveLayout.isDesktop(context) ? 28 : 22,
              fontWeight: FontWeight.w800,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const Spacer(),
          // ✅ شريط البحث في اليمين (للديسكتوب)
          if (ResponsiveLayout.isDesktop(context))
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              height: 40,
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'ابحث عن عرض...',
                  hintStyle:
                      const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                  prefixIcon: Icon(Icons.search,
                      color: Constants.primaryColor, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Constants.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
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

    final displayOffers = filteredOffers;

    if (displayOffers.isEmpty) {
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
                searchQuery.isNotEmpty
                    ? 'لا توجد نتائج للبحث'
                    : 'لا توجد عروض متاحة حالياً',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عداد النتائج
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'تم العثور على ${displayOffers.length} عرض',
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
              childAspectRatio: 0.8,
            ),
            itemCount: displayOffers.length,
            itemBuilder: (context, index) {
              final offer = displayOffers[index];
              final store = storesMap[offer.storeId.toLowerCase().trim()];
              return WebOfferCard(
                offer: offer,
                storeName: store?.name ?? 'متجر',
                storeImage: store?.image,
              );
            },
          ),
        ],
      ),
    );
  }
}
