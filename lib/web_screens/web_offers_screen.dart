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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

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

      storesMap = {for (var store in loadedStores) store.id: store};

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
          crossAxisCount: ResponsiveGrid.columns(context, max: 3),
          crossAxisSpacing: ResponsiveGrid.spacing(context),
          mainAxisSpacing: ResponsiveGrid.spacing(context),
          childAspectRatio: 0.85,
        ),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          return _WebOfferCard(
            offer: offers[index],
            storeName: storesMap[offers[index].storeId]?.name ?? 'متجر',
          );
        },
      ),
    );
  }
}

/// بطاقة عرض محسّنة للويب
class _WebOfferCard extends StatefulWidget {
  final Offer offer;
  final String storeName;

  const _WebOfferCard({
    required this.offer,
    required this.storeName,
  });

  @override
  State<_WebOfferCard> createState() => _WebOfferCardState();
}

class _WebOfferCardState extends State<_WebOfferCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..translate(0.0, isHovered ? -8.0 : 0.0),
        child: Card(
          elevation: isHovered ? 12 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: _openOffer,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImage(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.storeName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Constants.primaryColor,
                            fontFamily: 'Tajawal',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.offer.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            fontFamily: 'Tajawal',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.offer.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                            fontFamily: 'Tajawal',
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        const Divider(height: 16),
                        ElevatedButton(
                          onPressed: _openOffer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'احصل على العرض',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: widget.offer.image,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: Icon(
              Icons.local_offer_rounded,
              size: 48,
              color: Constants.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  void _openOffer() {
    if (widget.offer.web.isNotEmpty) {
      launchUrl(Uri.parse(widget.offer.web),
          mode: LaunchMode.externalApplication);
    }
  }
}
