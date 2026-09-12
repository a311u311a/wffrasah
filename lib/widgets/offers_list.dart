import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../localization/app_localizations.dart';
import '../models/offers.dart';
import '../models/store.dart';
import 'offers_card.dart';
import 'error_message.dart';
import 'loading_indicator.dart';

class OffersList extends StatelessWidget {
  final String? selectedCategoryId; // قد تكون id أو slug حسب CategoriesList
  final String? selectedStoreId;
  final String searchQuery;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OffersList({
    super.key,
    this.selectedCategoryId,
    this.selectedStoreId,
    required this.searchQuery,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final langCode = Localizations.localeOf(context).languageCode;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchOffersWithStoreNames(supabase, langCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomLoadingIndicator(
            message: 'جاري تحميل العروض',
          );
        }

        if (snapshot.hasError) {
          return ErrorMessage(message: snapshot.error.toString());
        }

        final rows = snapshot.data ?? [];
        final offers =
            rows.map((row) => Offer.fromSupabase(row, langCode)).toList();

        final filtered = offers.where((o) {
          final selectedStore = selectedStoreId?.trim();
          if (selectedStore != null &&
              selectedStore.isNotEmpty &&
              o.storeId.trim() != selectedStore) {
            return false;
          }

          if (searchQuery.trim().isEmpty) return true;
          final q = searchQuery.toLowerCase();

          final inName = o.name.toLowerCase().contains(q);
          final inDescription = o.description.toLowerCase().contains(q);
          final inTags = o.tags.any((t) => t.toLowerCase().contains(q));

          return inName || inDescription || inTags;
        }).toList();

        if (filtered.isEmpty) {
          return ErrorMessage(
            message: AppLocalizations.of(context)
                    ?.translate('no_offers_available_category') ??
                'لا توجد عروض',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            (context as Element).markNeedsBuild();
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            shrinkWrap: shrinkWrap,
            physics: physics,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return OffersCard(offer: filtered[index]);
            },
          ),
        );
      },
    );
  }

  /// ✅ يجلب العروض، وإذا كان فيه category محدد:
  /// - يجرب filter عادي
  /// - إذا رجع فاضي، يجرب fallback (لأن category_id ممكن يكون slug قديم)
  Future<List<Map<String, dynamic>>> _fetchOffersSmart(
      SupabaseClient supabase) async {
    // لو ما فيه تصنيف محدد
    if (selectedCategoryId == null || selectedCategoryId!.isEmpty) {
      final res = await supabase
          .from('offers')
          .select('*')
          .timeout(const Duration(seconds: 12));
      return (res as List).cast<Map<String, dynamic>>();
    }

    final selected = selectedCategoryId!.trim();

    // 1) محاولة الفلترة الطبيعية: offers.category_id == selected
    final res1 = await supabase
        .from('offers')
        .select('*')
        .eq('category_id', selected)
        .timeout(const Duration(seconds: 12));

    final list1 = (res1 as List).cast<Map<String, dynamic>>();
    if (list1.isNotEmpty) return list1;

    // 2) fallback: لو عندك slug في عمود آخر (مثل categoryId أو category)
    // (نجرّب بدون ما نكسر)
    try {
      final res2 = await supabase
          .from('offers')
          .select('*')
          .eq('categoryId', selected)
          .timeout(const Duration(seconds: 12));

      final list2 = (res2 as List).cast<Map<String, dynamic>>();
      if (list2.isNotEmpty) return list2;
    } catch (_) {}

    try {
      final res3 = await supabase
          .from('offers')
          .select('*')
          .eq('category', selected)
          .timeout(const Duration(seconds: 12));

      final list3 = (res3 as List).cast<Map<String, dynamic>>();
      if (list3.isNotEmpty) return list3;
    } catch (_) {}

    // ما فيه نتائج
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchOffersWithStoreNames(
    SupabaseClient supabase,
    String langCode,
  ) async {
    final results = await Future.wait([
      _fetchOffersSmart(supabase),
      supabase
          .from('stores')
          .select('id, slug, name, name_ar, name_en, image')
          .timeout(const Duration(seconds: 12)),
    ]);

    final offers = results[0];
    final stores = (results[1] as List)
        .cast<Map<String, dynamic>>()
        .map((row) => Store.fromSupabase(row, langCode))
        .toList();
    final storeNamesByKey = <String, String>{};
    final storeArabicNamesByKey = <String, String>{};
    final storeEnglishNamesByKey = <String, String>{};
    final storeImagesByKey = <String, String>{};

    for (final store in stores) {
      final displayName =
          langCode == 'en' ? store.nameEn.trim() : store.nameAr.trim();
      if (displayName.isEmpty) continue;

      for (final key in [
        store.id,
        store.slug,
        store.name,
        store.nameAr,
        store.nameEn,
      ]) {
        final normalizedKey = key.trim();
        if (normalizedKey.isNotEmpty) {
          storeNamesByKey[normalizedKey] = displayName;
          storeArabicNamesByKey[normalizedKey] = store.nameAr.trim();
          storeEnglishNamesByKey[normalizedKey] = store.nameEn.trim();
          storeImagesByKey[normalizedKey] = store.image.trim();
        }
      }
    }

    return offers.map((offer) {
      final storeId = (offer['store_id'] ?? '').toString().trim();
      return {
        ...offer,
        'store_display_name': storeNamesByKey[storeId] ?? '',
        'store_name_ar': storeArabicNamesByKey[storeId] ?? '',
        'store_name_en': storeEnglishNamesByKey[storeId] ?? '',
        'store_image': storeImagesByKey[storeId] ?? '',
      };
    }).toList();
  }
}
