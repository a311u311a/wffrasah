import '../models/coupon.dart';
import '../models/offers.dart';
import '../models/store.dart';

class UnifiedSearchResults {
  final List<Store> stores;
  final List<Coupon> coupons;
  final List<Offer> offers;

  const UnifiedSearchResults({
    this.stores = const [],
    this.coupons = const [],
    this.offers = const [],
  });

  bool get isEmpty => stores.isEmpty && coupons.isEmpty && offers.isEmpty;
}

class UnifiedSearchService {
  UnifiedSearchService._();

  static UnifiedSearchResults search({
    required String query,
    required List<Store> stores,
    required List<Coupon> coupons,
    required List<Offer> offers,
    String? selectedCategoryId,
  }) {
    final normalizedQuery = _normalize(query);
    final normalizedCategory = selectedCategoryId?.trim();
    if (normalizedQuery.isEmpty) {
      return UnifiedSearchResults(
        stores: _filterStoresByCategory(stores, normalizedCategory),
        coupons: _filterCouponsByCategory(
          coupons,
          stores,
          normalizedCategory,
        ),
        offers: _filterOffersByCategory(offers, stores, normalizedCategory),
      );
    }

    final storesByKey = _storesByKey(stores);
    final matchingStores = stores.where((store) {
      if (!_matchesStoreCategory(store, normalizedCategory)) return false;
      return _matchesAny(normalizedQuery, [
        store.name,
        store.nameAr,
        store.nameEn,
        store.description,
        store.descriptionAr,
        store.descriptionEn,
        store.slug,
        store.id,
      ]);
    }).toList();

    final matchingStoreKeys = <String>{
      for (final store in matchingStores) ..._storeKeys(store),
    };

    final matchingCoupons = coupons.where((coupon) {
      final store = storesByKey[_normalize(coupon.storeId)];
      if (!_matchesCouponCategory(coupon, store, normalizedCategory)) {
        return false;
      }
      return matchingStoreKeys.contains(_normalize(coupon.storeId)) ||
          _matchesAny(normalizedQuery, [
            coupon.name,
            coupon.nameAr,
            coupon.nameEn,
            coupon.description,
            coupon.descriptionAr,
            coupon.descriptionEn,
            coupon.code,
            coupon.storeName,
            coupon.storeNameAr,
            coupon.storeNameEn,
            coupon.couponType,
            ...coupon.tags,
          ]);
    }).toList();

    final matchingOffers = offers.where((offer) {
      final store = storesByKey[_normalize(offer.storeId)];
      if (!_matchesOfferCategory(offer, store, normalizedCategory)) {
        return false;
      }
      return matchingStoreKeys.contains(_normalize(offer.storeId)) ||
          _matchesAny(normalizedQuery, [
            offer.name,
            offer.nameAr,
            offer.nameEn,
            offer.description,
            offer.descriptionAr,
            offer.descriptionEn,
            offer.code,
            offer.storeName,
            offer.storeNameAr,
            offer.storeNameEn,
            ...offer.tags,
          ]);
    }).toList();

    return UnifiedSearchResults(
      stores: matchingStores,
      coupons: matchingCoupons,
      offers: matchingOffers,
    );
  }

  static List<Store> _filterStoresByCategory(
    List<Store> stores,
    String? categoryId,
  ) {
    return stores
        .where((store) => _matchesStoreCategory(store, categoryId))
        .toList();
  }

  static List<Coupon> _filterCouponsByCategory(
    List<Coupon> coupons,
    List<Store> stores,
    String? categoryId,
  ) {
    final storesByKey = _storesByKey(stores);
    return coupons.where((coupon) {
      return _matchesCouponCategory(
        coupon,
        storesByKey[_normalize(coupon.storeId)],
        categoryId,
      );
    }).toList();
  }

  static List<Offer> _filterOffersByCategory(
    List<Offer> offers,
    List<Store> stores,
    String? categoryId,
  ) {
    final storesByKey = _storesByKey(stores);
    return offers.where((offer) {
      return _matchesOfferCategory(
        offer,
        storesByKey[_normalize(offer.storeId)],
        categoryId,
      );
    }).toList();
  }

  static bool _matchesStoreCategory(Store store, String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return true;
    return store.categoryId?.trim() == categoryId;
  }

  static bool _matchesCouponCategory(
    Coupon coupon,
    Store? store,
    String? categoryId,
  ) {
    if (categoryId == null || categoryId.isEmpty) return true;
    return store?.categoryId?.trim() == categoryId;
  }

  static bool _matchesOfferCategory(
    Offer offer,
    Store? store,
    String? categoryId,
  ) {
    if (categoryId == null || categoryId.isEmpty) return true;
    return offer.categoryId.trim() == categoryId ||
        store?.categoryId?.trim() == categoryId;
  }

  static Map<String, Store> _storesByKey(List<Store> stores) {
    final map = <String, Store>{};
    for (final store in stores) {
      for (final key in _storeKeys(store)) {
        if (key.isNotEmpty) map[key] = store;
      }
    }
    return map;
  }

  static Iterable<String> _storeKeys(Store store) sync* {
    yield _normalize(store.id);
    yield _normalize(store.slug);
    yield _normalize(store.key);
    yield _normalize(store.name);
    yield _normalize(store.nameAr);
    yield _normalize(store.nameEn);
  }

  static bool _matchesAny(String normalizedQuery, Iterable<String> values) {
    return values.any((value) => _normalize(value).contains(normalizedQuery));
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
