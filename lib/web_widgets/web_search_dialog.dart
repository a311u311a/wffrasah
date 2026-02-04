import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../constants.dart';
import 'web_coupon_card.dart';
import 'web_offer_card.dart';
import '../models/store.dart';
import '../models/coupon.dart';
import '../models/offers.dart';
import '../providers/locale_provider.dart';

class WebSearchDialog extends StatefulWidget {
  const WebSearchDialog({super.key});

  @override
  State<WebSearchDialog> createState() => _WebSearchDialogState();
}

class _WebSearchDialogState extends State<WebSearchDialog> {
  static const String _font = 'Tajawal';

  final supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;
  bool isSearchingStores = false;
  bool isLoadingStoreContent = false;

  List<Store> storeResults = [];
  Store? selectedStore;

  List<Coupon> storeCoupons = [];
  List<Offer> storeOffers = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _storeKey(Store s) {
    final slug = s.slug.trim();
    return slug.isNotEmpty ? slug : s.id.trim();
  }

  void _onQueryChanged(String value) {
    final q = value.trim();

    // reset
    if (q.isEmpty) {
      _debounce?.cancel();
      setState(() {
        storeResults = [];
        selectedStore = null;
        storeCoupons = [];
        storeOffers = [];
        isSearchingStores = false;
        isLoadingStoreContent = false;
      });
      return;
    }

    if (q.length < 2) {
      _debounce?.cancel();
      setState(() {
        storeResults = [];
        selectedStore = null;
        storeCoupons = [];
        storeOffers = [];
        isSearchingStores = false;
        isLoadingStoreContent = false;
      });
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchStores(q);
    });
  }

  Future<void> _searchStores(String query) async {
    setState(() {
      isSearchingStores = true;
    });

    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final langCode = localeProvider.locale.languageCode;
    final term = query.toLowerCase();

    try {
      final storesData = await supabase
          .from('stores')
          .select()
          .or('name_ar.ilike.%$term%,name_en.ilike.%$term%,slug.ilike.%$term%')
          .order('name_ar', ascending: true)
          .limit(20);

      final results = (storesData as List)
          .map((s) => Store.fromSupabase(s, langCode))
          .toList();

      if (!mounted) return;

      setState(() {
        storeResults = results;
        isSearchingStores = false;
      });

      // ✅ اختيار أول متجر تلقائيًا (لو موجود)
      if (results.isNotEmpty) {
        _selectStore(results.first);
      } else {
        setState(() {
          selectedStore = null;
          storeCoupons = [];
          storeOffers = [];
        });
      }
    } catch (e) {
      debugPrint('Store search error: $e');
      if (!mounted) return;
      setState(() => isSearchingStores = false);
    }
  }

  Future<void> _selectStore(Store store) async {
    setState(() {
      selectedStore = store;
      isLoadingStoreContent = true;
      storeCoupons = [];
      storeOffers = [];
    });

    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final langCode = localeProvider.locale.languageCode;

    final key = _storeKey(store);

    try {
      final futures = await Future.wait([
        supabase
            .from('coupons')
            .select()
            .eq('store_id', key)
            .order('created_at', ascending: false)
            .limit(30),
        supabase
            .from('offers')
            .select()
            .eq('store_id', key)
            .order('created_at', ascending: false)
            .limit(30),
      ]);

      final couponsData = futures[0] as List;
      final offersData = futures[1] as List;

      if (!mounted) return;

      setState(() {
        storeCoupons =
            couponsData.map((c) => Coupon.fromSupabase(c, langCode)).toList();
        storeOffers =
            offersData.map((o) => Offer.fromSupabase(o, langCode)).toList();
        isLoadingStoreContent = false;
      });
    } catch (e) {
      debugPrint('Store content error: $e');
      if (!mounted) return;
      setState(() => isLoadingStoreContent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'البحث',
          style: TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _searchBox(),
          const SizedBox(height: 16),

          // نتائج المتاجر
          _storesResults(),

          const SizedBox(height: 18),

          // محتوى المتجر المختار
          _storeContent(),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        onChanged: _onQueryChanged,
        decoration: InputDecoration(
          hintText: 'اكتب اسم المتجر...',
          hintStyle: TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w700,
            color: Colors.grey[400],
          ),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        style: const TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _storesResults() {
    if (_controller.text.trim().isEmpty) {
      return _hintCard('اكتب حرفين أو أكثر للبحث عن متجر.');
    }

    if (isSearchingStores) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(18),
        child: CircularProgressIndicator(),
      ));
    }

    if (storeResults.isEmpty) {
      return _hintCard('لا توجد متاجر مطابقة.');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'المتاجر',
            style: TextStyle(
              fontFamily: _font,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          ...storeResults.take(8).map((s) {
            final isSelected = selectedStore?.id == s.id;
            return InkWell(
              onTap: () => _selectStore(s),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Constants.primaryColor.withValues(alpha: 0.06)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Constants.primaryColor.withValues(alpha: 0.35)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: s.image,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 44,
                          height: 44,
                          color: Colors.grey[200],
                          child: const Icon(Icons.store_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: isSelected
                          ? Constants.primaryColor
                          : Colors.grey[400],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _storeContent() {
    if (selectedStore == null) {
      return _hintCard('اختر متجرًا لعرض الكوبونات والعروض الخاصة به.');
    }

    if (isLoadingStoreContent) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان المتجر
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.store_rounded, color: Constants.primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'نتائج: ${selectedStore!.name}',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // كوبونات
        _contentSection(
          title: 'الكوبونات',
          icon: Icons.confirmation_number_rounded,
          count: storeCoupons.length,
          child: storeCoupons.isEmpty
              ? _hintCard('لا توجد كوبونات لهذا المتجر.')
              : Column(
                  children:
                      storeCoupons.take(12).map((c) => _couponRow(c)).toList(),
                ),
        ),

        const SizedBox(height: 12),

        // عروض
        _contentSection(
          title: 'العروض',
          icon: Icons.local_offer_rounded,
          count: storeOffers.length,
          child: storeOffers.isEmpty
              ? _hintCard('لا توجد عروض لهذا المتجر.')
              : Column(
                  children:
                      storeOffers.take(12).map((o) => _offerRow(o)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _contentSection({
    required String title,
    required IconData icon,
    required int count,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Constants.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: _font,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: _font,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: Constants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _couponRow(Coupon c) {
    return InkWell(
      onTap: () {
        _showCouponDetails(c);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Constants.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.confirmation_number_rounded,
                  color: Constants.primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: const TextStyle(
                      fontFamily: _font,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (c.code.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'كود: ${c.code}',
                      style: TextStyle(
                        fontFamily: _font,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Constants.primaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _offerRow(Offer o) {
    return InkWell(
      onTap: () {
        _showOfferDetails(o);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: o.image,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey[200],
                  child: const Icon(Icons.local_offer_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                o.name,
                style: const TextStyle(
                  fontFamily: _font,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _hintCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w800,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  void _showCouponDetails(Coupon coupon) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _buildDialogContent(
        WebCouponCard(coupon: coupon, storeName: coupon.name),
      ),
    );
  }

  void _showOfferDetails(Offer offer) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _buildDialogContent(
        WebOfferCard(offer: offer, storeName: offer.name),
      ),
    );
  }

  Widget _buildDialogContent(Widget child) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              top: -12,
              left: -12,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 20, color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
