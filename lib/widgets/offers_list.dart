import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../localization/app_localizations.dart';
import '../models/offers.dart';
import 'offers_card.dart';
import 'error_message.dart';

class OffersList extends StatelessWidget {
  final String? selectedCategoryId; // قد تكون id أو slug حسب CategoriesList
  final String searchQuery;

  const OffersList({
    super.key,
    this.selectedCategoryId,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final langCode = Localizations.localeOf(context).languageCode;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchOffersSmart(supabase),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return ErrorMessage(message: snapshot.error.toString());
        }

        final rows = snapshot.data ?? [];
        final offers =
        rows.map((row) => Offer.fromSupabase(row, langCode)).toList();

        final filtered = offers.where((o) {
          if (searchQuery.trim().isEmpty) return true;
          final q = searchQuery.toLowerCase();

          final inName = o.name.toLowerCase().contains(q);
          final inTags = o.tags.any((t) => t.toLowerCase().contains(q));

          return inName || inTags;
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
      final res = await supabase.from('offers').select('*');
      return (res as List).cast<Map<String, dynamic>>();
    }

    final selected = selectedCategoryId!.trim();

    // 1) محاولة الفلترة الطبيعية: offers.category_id == selected
    final res1 = await supabase
        .from('offers')
        .select('*')
        .eq('category_id', selected);

    final list1 = (res1 as List).cast<Map<String, dynamic>>();
    if (list1.isNotEmpty) return list1;

    // 2) fallback: لو عندك slug في عمود آخر (مثل categoryId أو category)
    // (نجرّب بدون ما نكسر)
    try {
      final res2 = await supabase
          .from('offers')
          .select('*')
          .eq('categoryId', selected);

      final list2 = (res2 as List).cast<Map<String, dynamic>>();
      if (list2.isNotEmpty) return list2;
    } catch (_) {}

    try {
      final res3 = await supabase
          .from('offers')
          .select('*')
          .eq('category', selected);

      final list3 = (res3 as List).cast<Map<String, dynamic>>();
      if (list3.isNotEmpty) return list3;
    } catch (_) {}

    // ما فيه نتائج
    return [];
  }
}
