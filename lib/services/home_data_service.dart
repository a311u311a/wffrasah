import 'package:supabase_flutter/supabase_flutter.dart';

class HomeDataRows {
  final List<Map<String, dynamic>> carousel;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> stores;
  final List<Map<String, dynamic>> coupons;
  final List<Map<String, dynamic>> offers;

  const HomeDataRows({
    this.carousel = const [],
    this.categories = const [],
    this.stores = const [],
    this.coupons = const [],
    this.offers = const [],
  });
}

class HomeDealsRows {
  final List<Map<String, dynamic>> coupons;
  final List<Map<String, dynamic>> offers;
  final List<Map<String, dynamic>> stores;

  const HomeDealsRows({
    this.coupons = const [],
    this.offers = const [],
    this.stores = const [],
  });
}

class StoreDetailRows {
  final List<Map<String, dynamic>> coupons;
  final List<Map<String, dynamic>> offers;

  const StoreDetailRows({
    this.coupons = const [],
    this.offers = const [],
  });
}

class HomeDataService {
  HomeDataService._();

  static final SupabaseClient _supabase = Supabase.instance.client;
  static const Duration _cacheTtl = Duration(minutes: 2);

  static HomeDataRows? _webHomeCache;
  static DateTime? _webHomeCacheTime;
  static List<Map<String, dynamic>>? _storesCache;
  static DateTime? _storesCacheTime;
  static List<Map<String, dynamic>>? _categoriesCache;
  static DateTime? _categoriesCacheTime;
  static List<Map<String, dynamic>>? _publicCouponsCache;
  static DateTime? _publicCouponsCacheTime;
  static List<Map<String, dynamic>>? _mostUsedCouponsCache;
  static DateTime? _mostUsedCouponsCacheTime;
  static List<Map<String, dynamic>>? _publicOffersCache;
  static DateTime? _publicOffersCacheTime;
  static List<Map<String, dynamic>>? _importedCouponStoresCache;
  static DateTime? _importedCouponStoresCacheTime;
  static final Map<String, StoreDetailRows> _storeDetailCache = {};
  static final Map<String, DateTime> _storeDetailCacheTime = {};
  static final Map<String, HomeDealsRows> _mobileDealsCache = {};
  static final Map<String, DateTime> _mobileDealsCacheTime = {};

  static bool _isFresh(DateTime? time) {
    if (time == null) return false;
    return DateTime.now().difference(time) < _cacheTtl;
  }

  static Future<HomeDataRows> fetchWebHomeData({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _webHomeCache != null && _isFresh(_webHomeCacheTime)) {
      return _webHomeCache!;
    }

    final results = await Future.wait([
      _loadRows(_supabase.from('carousel').select()),
      fetchCategories(forceRefresh: forceRefresh),
      fetchStores(forceRefresh: forceRefresh),
      fetchPublicCoupons(limit: 24, forceRefresh: forceRefresh),
      fetchPublicOffers(limit: 12, forceRefresh: forceRefresh),
    ]).timeout(const Duration(seconds: 12));

    final data = HomeDataRows(
      carousel: results[0],
      categories: results[1],
      stores: results[2],
      coupons: results[3],
      offers: results[4],
    );
    _webHomeCache = data;
    _webHomeCacheTime = DateTime.now();
    return data;
  }

  static Future<List<Map<String, dynamic>>> fetchStores({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _storesCache != null && _isFresh(_storesCacheTime)) {
      return _storesCache!;
    }

    final rows =
        await _loadRows(_supabase.from('stores').select().order('name_ar'));
    _storesCache = rows;
    _storesCacheTime = DateTime.now();
    return rows;
  }

  static Future<List<Map<String, dynamic>>> fetchCategories({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _categoriesCache != null &&
        _isFresh(_categoriesCacheTime)) {
      return _categoriesCache!;
    }

    final rows =
        await _loadRows(_supabase.from('categories').select().order('name_ar'));
    _categoriesCache = rows;
    _categoriesCacheTime = DateTime.now();
    return rows;
  }

  static Future<List<Map<String, dynamic>>> fetchPublicCoupons({
    int? limit,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        limit == null &&
        _publicCouponsCache != null &&
        _isFresh(_publicCouponsCacheTime)) {
      return _publicCouponsCache!;
    }

    var query = _supabase
        .from('coupons')
        .select()
        .eq('approval_status', 'approved')
        .order('created_at', ascending: false);
    final rows = await _loadRows(limit == null ? query : query.limit(limit));

    if (limit == null) {
      _publicCouponsCache = rows;
      _publicCouponsCacheTime = DateTime.now();
    }
    return rows;
  }

  static Future<List<Map<String, dynamic>>> fetchMostUsedCoupons({
    int limit = 6,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _mostUsedCouponsCache != null &&
        _mostUsedCouponsCache!.isNotEmpty &&
        _isFresh(_mostUsedCouponsCacheTime)) {
      return _mostUsedCouponsCache!.take(limit).toList();
    }

    final copiedRows = await _fetchMostCopiedCouponsByRpc(limit);
    if (copiedRows.isNotEmpty) {
      _mostUsedCouponsCache = copiedRows;
      _mostUsedCouponsCacheTime = DateTime.now();
      return copiedRows;
    }

    List<Map<String, dynamic>> usedRows = const [];
    try {
      usedRows = await _loadRows(_supabase
          .from('coupons')
          .select()
          .eq('approval_status', 'approved')
          .not('last_used_at', 'is', null)
          .order('last_used_at', ascending: false)
          .limit(limit));
    } catch (_) {
      usedRows = const [];
    }

    if (usedRows.length >= limit) {
      _mostUsedCouponsCache = usedRows;
      _mostUsedCouponsCacheTime = DateTime.now();
      return usedRows;
    }

    var latestRows = const <Map<String, dynamic>>[];
    try {
      latestRows = await _fetchCouponsRows(allForStore: false);
    } catch (_) {
      latestRows = const [];
    }

    if (latestRows.isEmpty) {
      try {
        latestRows = await _loadRows(
          _supabase
              .from('coupons')
              .select('*')
              .eq('approval_status', 'approved'),
        );
      } catch (_) {
        latestRows = const [];
      }
    }

    if (latestRows.isEmpty) {
      try {
        latestRows = await _loadRows(_supabase.from('coupons').select('*'));
      } catch (_) {
        latestRows = const [];
      }
    }

    final seenIds = usedRows
        .map((row) => (row['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    final fallbackRows = latestRows
        .where((row) => !seenIds.contains((row['id'] ?? '').toString()))
        .take(limit - usedRows.length);
    final rows = [...usedRows, ...fallbackRows].take(limit).toList();

    if (rows.isNotEmpty) {
      _mostUsedCouponsCache = rows;
      _mostUsedCouponsCacheTime = DateTime.now();
    }
    return rows;
  }

  static Future<List<Map<String, dynamic>>> _fetchMostCopiedCouponsByRpc(
    int limit,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_most_copied_coupons',
        params: {'limit_count': limit},
      );
      return _normalizeRows(response);
    } catch (_) {
      return const [];
    }
  }

  static List<Map<String, dynamic>> _normalizeRows(dynamic rows) {
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> fetchPublicOffers({
    int? limit,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        limit == null &&
        _publicOffersCache != null &&
        _isFresh(_publicOffersCacheTime)) {
      return _publicOffersCache!;
    }

    var query =
        _supabase.from('offers').select().order('created_at', ascending: false);
    final rows = await _loadRows(limit == null ? query : query.limit(limit));

    if (limit == null) {
      _publicOffersCache = rows;
      _publicOffersCacheTime = DateTime.now();
    }
    return rows;
  }

  static Future<List<Map<String, dynamic>>> fetchImportedCouponStores({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _importedCouponStoresCache != null &&
        _isFresh(_importedCouponStoresCacheTime)) {
      return _importedCouponStoresCache!;
    }

    final rows = await _loadRows(_supabase
        .from('coupons')
        .select('store_id,import_source,approval_status')
        .neq('import_source', 'manual'));
    _importedCouponStoresCache = rows;
    _importedCouponStoresCacheTime = DateTime.now();
    return rows;
  }

  static Future<StoreDetailRows> fetchStoreDetailData({
    required Iterable<String> searchKeys,
    bool forceRefresh = false,
  }) async {
    final keys = searchKeys
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toSet()
        .toList();
    final cacheKey = keys.map((key) => key.toLowerCase()).join('|');
    final cached = _storeDetailCache[cacheKey];
    if (!forceRefresh &&
        cached != null &&
        _isFresh(_storeDetailCacheTime[cacheKey])) {
      return cached;
    }

    final results = await Future.wait([
      _loadRows(_supabase
          .from('coupons')
          .select()
          .inFilter('store_id', keys)
          .eq('approval_status', 'approved')
          .order('created_at', ascending: false)),
      _loadRows(_supabase
          .from('offers')
          .select()
          .inFilter('store_id', keys)
          .order('created_at', ascending: false)),
    ]);

    final data = StoreDetailRows(
      coupons: results[0],
      offers: results[1],
    );
    _storeDetailCache[cacheKey] = data;
    _storeDetailCacheTime[cacheKey] = DateTime.now();
    return data;
  }

  static Future<HomeDealsRows> fetchMobileDealsData({
    required bool allForStore,
    bool forceRefresh = false,
  }) async {
    final cacheKey = allForStore ? 'store' : 'home';
    final cached = _mobileDealsCache[cacheKey];
    if (!forceRefresh &&
        cached != null &&
        _isFresh(_mobileDealsCacheTime[cacheKey])) {
      return cached;
    }

    final results = await Future.wait([
      _fetchCouponsRows(allForStore: allForStore),
      fetchPublicOffers(limit: allForStore ? 1000 : 20),
      fetchStores(),
    ]);

    final data = HomeDealsRows(
      coupons: results[0],
      offers: results[1],
      stores: results[2],
    );
    _mobileDealsCache[cacheKey] = data;
    _mobileDealsCacheTime[cacheKey] = DateTime.now();
    return data;
  }

  static Future<List<Map<String, dynamic>>> _fetchCouponsRows({
    required bool allForStore,
  }) async {
    final approved = await _loadRows(
      _supabase
          .from('coupons')
          .select('*')
          .eq('approval_status', 'approved')
          .order('created_at', ascending: false)
          .limit(allForStore ? 1000 : 20),
    );
    if (approved.isNotEmpty) return approved;

    final all = await _loadRows(
      _supabase
          .from('coupons')
          .select('*')
          .order('created_at', ascending: false)
          .limit(allForStore ? 1000 : 20),
    );
    return all
        .where((row) =>
            (row['approval_status'] ?? 'approved').toString() == 'approved')
        .toList();
  }

  static Future<List<Map<String, dynamic>>> _loadRows(
    Future<dynamic> query,
  ) async {
    final rows = await query.timeout(const Duration(seconds: 8));
    return (rows as List).cast<Map<String, dynamic>>();
  }
}
