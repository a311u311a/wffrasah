import 'dart:convert';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../localization/app_localizations.dart';
import '../models/coupon.dart';
import 'app_responsive.dart';
import 'coupon_card.dart';
import 'error_message.dart';

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
          return const Center(child: CircularProgressIndicator());
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
          child: _buildCouponsView(filtered),
        );
      },
    );
  }

  Widget _buildCouponsView(List<Coupon> coupons) {
    if (!_useMacGrid && !AppResponsive.isTablet(context)) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: coupons.length,
        itemBuilder: (context, index) {
          return CouponCard(coupon: coupons[index]);
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
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: AppResponsive.isTablet(context) ? 380 : 420,
        mainAxisExtent: AppResponsive.isTablet(context) ? 285 : 255,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
      ),
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        return CouponCard(
          coupon: coupons[index],
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

    final res = await supabase
        .from('coupons')
        .select('*')
        .eq('approval_status', 'approved');
    final rows = (res as List).cast<Map<String, dynamic>>();

    final storeId = widget.selectedStoreId?.trim();
    if (storeId == null || storeId.isEmpty) {
      return rows;
    }

    return rows.where((row) {
      final rowStoreId = (row['store_id'] ?? row['storeId'])?.toString().trim();
      return rowStoreId == storeId;
    }).toList();
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
