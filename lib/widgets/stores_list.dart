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
  final String? selectedCategoryId;
  final bool onlyStoresWithCoupons;
  final double? itemExtent;
  final bool useBottomSelectionIndicator;

  const StoresList({
    super.key,
    required this.onStoreSelected,
    this.selectedStoreId,
    this.selectedCategoryId,
    this.onlyStoresWithCoupons = false,
    this.itemExtent,
    this.useBottomSelectionIndicator = false,
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

  @override
  void didUpdateWidget(covariant StoresList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId ||
        oldWidget.onlyStoresWithCoupons != widget.onlyStoresWithCoupons) {
      final langCode = Localizations.localeOf(context).languageCode;
      _storesFuture = _fetchStores(langCode);
    }
  }

  Future<List<Store>> _fetchStores(String langCode) async {
    final supabase = Supabase.instance.client;

    final results = await Future.wait([
      supabase.from('stores').select(),
      supabase.from('coupons').select('store_id,import_source,approval_status'),
      supabase.from('offers').select('store_id'),
    ]);
    final storeRows = results[0];
    final couponRows = results[1] as List;
    final offerRows = results[2] as List;
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
    final storeIdsWithOffers = offerRows
        .map((offer) => (offer['store_id'] ?? '').toString().trim())
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
          final selectedCategoryId = widget.selectedCategoryId?.trim();
          if (selectedCategoryId != null && selectedCategoryId.isNotEmpty) {
            final categoryId = (data['category_id'] ?? '').toString().trim();
            if (categoryId != selectedCategoryId) return false;
          }

          if (widget.onlyStoresWithCoupons &&
              !approvedStoreIds.contains(slug) &&
              !approvedStoreIds.contains(id) &&
              !storeIdsWithOffers.contains(slug) &&
              !storeIdsWithOffers.contains(id)) {
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
    final isTablet = AppResponsive.isTablet(context);
    final itemSize = widget.itemExtent ?? (isTablet ? 88.0 : 75.0);
    final useSquareCards = widget.itemExtent != null;
    const verticalMargin = 16.0;

    return SizedBox(
      height: useSquareCards ? itemSize + verticalMargin : 75 * scale,
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
    final scale = AppResponsive.tabletScale(context);
    final useSquareCard = widget.itemExtent != null;
    final useBottomIndicator = widget.useBottomSelectionIndicator;
    final itemSize = widget.itemExtent ?? (isTablet ? 88.0 : 75.0);
    final iconSize = useSquareCard ? 44.0 * scale : 40.0 * scale;

    return GestureDetector(
      onTap: () => widget.onStoreSelected(storeKey),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: useSquareCard ? (isTablet ? 6 : 5) : (isTablet ? 6 : 4),
          vertical: useSquareCard ? 8 : 9,
        ),
        child: SizedBox(
          width: itemSize,
          height: useSquareCard ? itemSize : null,
          child: AnimatedContainer(
            duration: Duration(
                milliseconds: useBottomIndicator
                    ? 100
                    : useSquareCard
                        ? 180
                        : 100),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                  useBottomIndicator ? 12 : (useSquareCard ? 18 : 12)),
              border: useBottomIndicator
                  ? Border.all(
                      color: isSelected
                          ? Constants.primaryColor
                          : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    )
                  : useSquareCard
                      ? Border.all(
                          color: isSelected
                              ? Constants.primaryColor
                              : Constants.primaryColor.withValues(alpha: 0.22),
                          width: isSelected ? 2 : 1,
                        )
                      : isSelected
                          ? Border(
                              top: BorderSide(
                                  color: Constants.primaryColor, width: 2),
                              left: BorderSide(
                                  color: Constants.primaryColor, width: 2),
                              right: BorderSide(
                                  color: Constants.primaryColor, width: 2),
                              bottom: BorderSide(
                                  color: Constants.primaryColor, width: 15),
                            )
                          : Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: useBottomIndicator
                      ? (isSelected
                          ? Constants.primaryColor.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.05))
                      : useSquareCard
                          ? (isSelected
                              ? Constants.primaryColor.withValues(alpha: 0.16)
                              : Constants.primaryColor.withValues(alpha: 0.055))
                          : (isSelected
                              ? Constants.primaryColor.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.05)),
                  blurRadius: useBottomIndicator
                      ? (isSelected ? 6 : 2)
                      : useSquareCard
                          ? (isSelected ? 18 : 12)
                          : (isSelected ? 6 : 2),
                  offset: useBottomIndicator || !useSquareCard
                      ? const Offset(0, 3)
                      : const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                      useBottomIndicator ? 10 : (useSquareCard ? 16 : 10)),
                  child: Padding(
                    padding: EdgeInsets.all(useSquareCard ? 0 : 2),
                    child: Image.network(
                      store.image,
                      fit: useBottomIndicator && isSelected
                          ? BoxFit.contain
                          : BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.store, size: iconSize, color: Colors.grey),
                    ),
                  ),
                ),
                if (useBottomIndicator && isSelected)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 15,
                      color: Constants.primaryColor,
                    ),
                  ),
              ],
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
    final useSquareCard = widget.itemExtent != null;
    final useBottomIndicator = widget.useBottomSelectionIndicator;
    final itemSize = widget.itemExtent ?? (isTablet ? 88.0 : 75.0);

    return GestureDetector(
      onTap: () => widget.onStoreSelected(null),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: useSquareCard ? (isTablet ? 6 : 5) : (isTablet ? 6 : 4),
          vertical: useSquareCard ? 8 : 9,
        ),
        child: SizedBox(
          width: itemSize,
          height: useSquareCard ? itemSize : null,
          child: AnimatedContainer(
            duration: Duration(
                milliseconds: useBottomIndicator
                    ? 100
                    : useSquareCard
                        ? 180
                        : 100),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                  useBottomIndicator ? 12 : (useSquareCard ? 18 : 12)),
              border: useBottomIndicator
                  ? (isSelected
                      ? Border(
                          top: BorderSide(
                              color: Constants.primaryColor, width: 2),
                          left: BorderSide(
                              color: Constants.primaryColor, width: 2),
                          right: BorderSide(
                              color: Constants.primaryColor, width: 2),
                          bottom: BorderSide(
                              color: Constants.primaryColor, width: 15),
                        )
                      : Border.all(color: Colors.grey.shade200, width: 1))
                  : useSquareCard
                      ? Border.all(
                          color: isSelected
                              ? Constants.primaryColor
                              : Constants.primaryColor.withValues(alpha: 0.22),
                          width: isSelected ? 2 : 1,
                        )
                      : isSelected
                          ? Border(
                              top: BorderSide(
                                  color: Constants.primaryColor, width: 2),
                              left: BorderSide(
                                  color: Constants.primaryColor, width: 2),
                              right: BorderSide(
                                  color: Constants.primaryColor, width: 2),
                              bottom: BorderSide(
                                  color: Constants.primaryColor, width: 15),
                            )
                          : Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: useBottomIndicator
                      ? (isSelected
                          ? Constants.primaryColor.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.05))
                      : useSquareCard
                          ? (isSelected
                              ? Constants.primaryColor.withValues(alpha: 0.16)
                              : Constants.primaryColor.withValues(alpha: 0.055))
                          : (isSelected
                              ? Constants.primaryColor.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.05)),
                  blurRadius: useBottomIndicator
                      ? (isSelected ? 6 : 4)
                      : useSquareCard
                          ? (isSelected ? 18 : 12)
                          : (isSelected ? 6 : 4),
                  offset: useBottomIndicator || !useSquareCard
                      ? const Offset(0, 3)
                      : const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icon/grid.svg',
                  height: 34 * scale,
                  width: 34 * scale,
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? Constants.primaryColor
                        : (useSquareCard ? Colors.grey.shade500 : Colors.grey),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  localizations?.translate('show_all') ?? 'All',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Constants.primaryColor
                        : (useSquareCard ? Colors.grey[700] : Colors.black87),
                    fontWeight: isSelected
                        ? (useSquareCard ? FontWeight.w800 : FontWeight.bold)
                        : (useSquareCard ? FontWeight.w600 : FontWeight.normal),
                    fontSize: 12 * scale,
                    fontFamily: useSquareCard ? 'Tajawal' : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
