import 'dart:convert';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../localization/app_localizations.dart';
import '../models/coupon.dart';
import '../models/store.dart';
import 'app_responsive.dart';
import 'coupon_card.dart';
import 'error_message.dart';
import 'loading_indicator.dart';

class CouponsList extends StatefulWidget {
  final String? selectedStoreId;
  final String searchQuery;

  const CouponsList({
    super.key,
    this.selectedStoreId,
    required this.searchQuery,
  });

  @override
  State<CouponsList> createState() => _CouponsListState();
}

class _CouponsListState extends State<CouponsList> {
  late Future<List<Map<String, dynamic>>> _future;

  bool get _useMacGrid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    _future = _fetchCoupons();
  }

  @override
  void didUpdateWidget(covariant CouponsList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // إذا تغيّر المتجر المختار نعيد جلب البيانات
    if (oldWidget.selectedStoreId != widget.selectedStoreId) {
      _future = _fetchCoupons();
    }
    // ملاحظة: تغيير searchQuery ما يحتاج refetch لأنه فلترة محلية
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomLoadingIndicator(
            message: 'جاري تحميل الكوبونات',
          );
        }

        if (snapshot.hasError) {
          return ErrorMessage(message: snapshot.error.toString());
        }

        final rows = snapshot.data ?? [];

        // ✅ نطبّع rows قبل تمريرها للموديل (خصوصًا tags)
        final normalizedRows = rows.map(_normalizeCouponRow).toList();

        final coupons = normalizedRows
            .map((row) => Coupon.fromSupabase(row, langCode))
            .toList();
        final storeNames = _storeNamesByCouponId(normalizedRows, langCode);

        final filtered = coupons.where((c) {
          final qRaw = widget.searchQuery.trim();
          if (qRaw.isEmpty) return true;

          final q = qRaw.toLowerCase();

          final name = (c.name).toLowerCase();
          final code = (c.code).toLowerCase();
          final tags = (c.tags).map((t) => t.toLowerCase());

          final inName = name.contains(q);
          final inCode = code.contains(q);
          final inTags = tags.any((t) => t.contains(q));

          return inName || inCode || inTags;
        }).toList();

        if (filtered.isEmpty) {
          return ErrorMessage(
            message: AppLocalizations.of(context)
                    ?.translate('no_coupons_available') ??
                'لا توجد كوبونات',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _future = _fetchCoupons();
            });
            await _future;
          },
          child: _buildCouponsView(filtered, storeNames),
        );
      },
    );
  }

  Widget _buildCouponsView(
    List<Coupon> coupons,
    Map<String, String> storeNames,
  ) {
    final isIPad = !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        AppResponsive.isTablet(context);

    if (!_useMacGrid && !AppResponsive.isTablet(context)) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: coupons.length,
        itemBuilder: (context, index) {
          final coupon = coupons[index];
          return CouponCard(
            coupon: coupon,
            storeName: storeNames[coupon.id],
          );
        },
      );
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        AppResponsive.isTablet(context) ? 28 : 24,
        14,
        AppResponsive.isTablet(context) ? 28 : 24,
        24,
      ),
      gridDelegate: isIPad
          ? const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 165,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
            )
          : SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: AppResponsive.isTablet(context) ? 380 : 420,
              mainAxisExtent: AppResponsive.isTablet(context) ? 245 : 255,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
            ),
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        final coupon = coupons[index];
        return CouponCard(
          coupon: coupon,
          storeName: storeNames[coupon.id],
          margin: EdgeInsets.zero,
        );
      },
    );
  }

  // ---------------------------
  // Fetch
  // ---------------------------
  Future<List<Map<String, dynamic>>> _fetchCoupons() async {
    final supabase = Supabase.instance.client;

    final results = await Future.wait([
      supabase.from('coupons').select('*').eq('approval_status', 'approved'),
      supabase.from('offers').select('*'),
      supabase.from('stores').select(),
    ]);
    final rows = (results[0] as List).cast<Map<String, dynamic>>();
    final offerRows = (results[1] as List).cast<Map<String, dynamic>>();
    final stores = (results[2] as List).cast<Map<String, dynamic>>();
    final storesByKey = <String, Map<String, dynamic>>{};

    for (final store in stores) {
      final model = Store.fromSupabase(store, 'ar');
      for (final key in [
        model.id,
        model.slug,
        model.nameAr,
        model.nameEn,
      ]) {
        final normalizedKey = key.trim();
        if (normalizedKey.isNotEmpty) {
          storesByKey[normalizedKey] = store;
        }
      }
    }

    final allRows = [
      ...rows,
      ...offerRows.map(_offerRowAsCouponRow),
    ]..sort((a, b) {
        final aDate = DateTime.tryParse((a['created_at'] ?? '').toString());
        final bDate = DateTime.tryParse((b['created_at'] ?? '').toString());
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

    final storeId = widget.selectedStoreId?.trim();
    if (storeId == null || storeId.isEmpty) {
      return allRows.map((row) => _withStoreNames(row, storesByKey)).toList();
    }

    return allRows
        .where((row) {
          final rowStoreId =
              (row['store_id'] ?? row['storeId'])?.toString().trim();
          return rowStoreId == storeId;
        })
        .map((row) => _withStoreNames(row, storesByKey))
        .toList();
  }

  Map<String, dynamic> _offerRowAsCouponRow(Map<String, dynamic> row) {
    final tags = _parseTags(row['tags']);
    return {
      ...row,
      'code': tags.isNotEmpty ? tags.first : '',
      'coupon_type': 'offer',
      'discount_percent': null,
      'terms': '',
      'terms_ar': '',
      'terms_en': '',
      'is_active': true,
      'last_used_at': null,
      'tags': tags,
    };
  }

  Map<String, dynamic> _withStoreNames(
    Map<String, dynamic> row,
    Map<String, Map<String, dynamic>> storesByKey,
  ) {
    final storeId = (row['store_id'] ?? row['storeId'] ?? '').toString().trim();
    final store = storesByKey[storeId];
    if (store == null) return row;

    return {
      ...row,
      'store_name_ar': (store['name_ar'] ?? store['name'] ?? '').toString(),
      'store_name_en': (store['name_en'] ?? '').toString(),
      'store_image': (store['image'] ?? '').toString(),
    };
  }

  Map<String, String> _storeNamesByCouponId(
    List<Map<String, dynamic>> rows,
    String langCode,
  ) {
    return {
      for (final row in rows)
        (row['id'] ?? '').toString(): (langCode == 'en'
                ? (row['store_name_en'] ?? '').toString().trim()
                : (row['store_name_ar'] ?? '').toString().trim())
            .trim(),
    };
  }

  // ---------------------------
  // Normalize: fixes tags type mismatch
  // ---------------------------
  Map<String, dynamic> _normalizeCouponRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);

    // ✅ tags ممكن تجي List أو String أو null
    map['tags'] = _parseTags(map['tags']);

    // احتياط: بعض الحقول قد تكون null
    map['name'] = (map['name'] ?? '').toString();
    map['code'] = (map['code'] ?? '').toString();

    return map;
  }

  List<String> _parseTags(dynamic value) {
    if (value == null) return [];

    // إذا Supabase رجعها List<dynamic>
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    // إذا كانت String (JSON نصي أو CSV)
    if (value is String) {
      final v = value.trim();
      if (v.isEmpty) return [];

      // JSON array كنص: ["a","b"]
      if (v.startsWith('[')) {
        try {
          final decoded = jsonDecode(v);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          return [];
        }
      }

      // CSV: "a,b,c"
      return v
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // أي نوع ثاني (Map...) نرجّع فاضي
    return [];
  }
}
