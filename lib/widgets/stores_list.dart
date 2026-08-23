import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_svg/svg.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../models/store.dart';
import 'app_responsive.dart';
import 'error_message.dart';
import 'loading_indicator.dart';

class StoresList extends StatefulWidget {
  final Function(String?) onStoreSelected;
  final String? selectedStoreId; // slug غالباً
  final bool onlyStoresWithCoupons;

  const StoresList({
    super.key,
    required this.onStoreSelected,
    this.selectedStoreId,
    this.onlyStoresWithCoupons = false,
  });

  @override
  State<StoresList> createState() => _StoresListState();
}

class _StoresListState extends State<StoresList> {
  Future<List<Store>>? _storesFuture;
  bool _didStartLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didStartLoading) {
      _didStartLoading = true;
      final langCode = Localizations.localeOf(context).languageCode;
      _storesFuture = _fetchStores(langCode);
    }
  }

  Future<List<Store>> _fetchStores(String langCode) async {
    final supabase = Supabase.instance.client;

    final results = await Future.wait([
      supabase.from('stores').select(),
      supabase.from('coupons').select('store_id,import_source,approval_status'),
    ]);
    final storeRows = results[0];
    final couponRows = results[1] as List;
    final importedCoupons = couponRows.where((coupon) {
      return (coupon['import_source'] ?? '').toString() != 'manual';
    });
    final importedStoreIds = importedCoupons
        .map((coupon) => (coupon['store_id'] ?? '').toString())
        .where((storeId) => storeId.isNotEmpty)
        .toSet();
    final approvedStoreIds = couponRows
        .where((coupon) => coupon['approval_status'] == 'approved')
        .map((coupon) => (coupon['store_id'] ?? '').toString().trim())
        .where((storeId) => storeId.isNotEmpty)
        .toSet();
    final approvedImportedStoreIds = importedCoupons
        .where((coupon) => coupon['approval_status'] == 'approved')
        .map((coupon) => (coupon['store_id'] ?? '').toString())
        .where((storeId) => storeId.isNotEmpty)
        .toSet();

    final stores = (storeRows as List)
        .cast<Map<String, dynamic>>()
        .where((data) {
          final storeImportSource =
              (data['import_source'] ?? 'manual').toString();
          final storeApprovalStatus =
              (data['approval_status'] ?? 'approved').toString();
          if (storeImportSource != 'manual' &&
              storeApprovalStatus != 'approved') {
            return false;
          }

          final id = (data['id'] ?? '').toString().trim();
          final slug = (data['slug'] ?? '').toString().trim();
          if (widget.onlyStoresWithCoupons &&
              !approvedStoreIds.contains(slug) &&
              !approvedStoreIds.contains(id)) {
            return false;
          }

          return !importedStoreIds.contains(slug) ||
              approvedImportedStoreIds.contains(slug);
        })
        .map((data) => Store.fromSupabase(data, langCode))
        .toList();

    final seen = <String>{};
    final displayStores = <Store>[];
    for (final s in stores) {
      final key = s.key;
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      displayStores.add(s);
    }

    return displayStores;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final scale = AppResponsive.tabletScale(context);

    return SizedBox(
      height: 75 * scale,
      child: FutureBuilder<List<Store>>(
        future: _storesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('StoresList loading failed: ${snapshot.error}');
            return ErrorMessage(
              message: kDebugMode
                  ? 'خطأ تحميل المتاجر: ${snapshot.error}'
                  : (localizations?.translate('error_loading_stores') ??
                      'Error loading stores'),
            );
          }
          if (!snapshot.hasData) return const CustomLoadingIndicator();

          final displayStores = snapshot.data ?? [];

          if (widget.selectedStoreId != null &&
              widget.selectedStoreId!.isNotEmpty &&
              !displayStores.any((s) => s.key == widget.selectedStoreId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onStoreSelected(null);
            });
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            scrollDirection: Axis.horizontal,
            itemCount: displayStores.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildShowAllItem(
                    context, widget.selectedStoreId == null);
              }

              final store = displayStores[index - 1];
              final storeKey = store.key;

              return _buildStoreItem(
                context,
                store,
                widget.selectedStoreId == storeKey,
                storeKey,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStoreItem(
    BuildContext context,
    Store store,
    bool isSelected,
    String storeKey,
  ) {
    final isTablet = AppResponsive.isTablet(context);
    final itemSize = isTablet ? 88.0 : 75.0;
    final iconSize = 40.0 * AppResponsive.tabletScale(context);

    return GestureDetector(
      onTap: () => widget.onStoreSelected(storeKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.symmetric(horizontal: isTablet ? 6 : 4, vertical: 9),
        width: itemSize,
        height: itemSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border(
                  top: BorderSide(color: Constants.primaryColor, width: 2),
                  left: BorderSide(color: Constants.primaryColor, width: 2),
                  right: BorderSide(color: Constants.primaryColor, width: 2),
                  bottom: BorderSide(color: Constants.primaryColor, width: 20),
                )
              : Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Constants.primaryColor.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 6 : 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Image.network(
              store.image,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.store, size: iconSize, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShowAllItem(BuildContext context, bool isSelected) {
    final localizations = AppLocalizations.of(context);
    final isTablet = AppResponsive.isTablet(context);
    final scale = AppResponsive.tabletScale(context);
    final itemSize = isTablet ? 88.0 : 75.0;

    return GestureDetector(
      onTap: () => widget.onStoreSelected(null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.symmetric(horizontal: isTablet ? 6 : 4, vertical: 9),
        width: itemSize,
        height: itemSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border(
                  top: BorderSide(color: Constants.primaryColor, width: 2),
                  left: BorderSide(color: Constants.primaryColor, width: 2),
                  right: BorderSide(color: Constants.primaryColor, width: 2),
                  bottom: BorderSide(color: Constants.primaryColor, width: 20),
                )
              : Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Constants.primaryColor.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 6 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icon/grid.svg',
              height: 30 * scale,
              width: 30 * scale,
              colorFilter: ColorFilter.mode(
                isSelected ? Constants.primaryColor : Colors.grey,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              localizations?.translate('show_all') ?? 'All',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Constants.primaryColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
