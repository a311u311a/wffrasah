// صفحة المتاجر (تعرض كل المتاجر)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:wffrhasah/screens/store_coupons_screen.dart';

import '../constants.dart';
import '../models/store.dart';
import '../localization/app_localizations.dart';
import '../widgets/app_responsive.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/search_widget.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  String searchQuery = '';

  late Future<List<Map<String, dynamic>>> _storesFuture;

  @override
  void initState() {
    super.initState();
    _storesFuture = _fetchStores();
  }

  Future<List<Map<String, dynamic>>> _fetchStores() async {
    final supabase = Supabase.instance.client;
    final results = await Future.wait([
      supabase.from('stores').select().order('created_at', ascending: false),
      supabase
          .from('coupons')
          .select('store_id,import_source,approval_status')
          .neq('import_source', 'manual'),
    ]);
    final rows = (results[0] as List).cast<Map<String, dynamic>>();
    final importedCoupons = results[1] as List;
    final importedStoreIds = importedCoupons
        .map((coupon) => (coupon['store_id'] ?? '').toString())
        .where((storeId) => storeId.isNotEmpty)
        .toSet();
    final approvedImportedStoreIds = importedCoupons
        .where((coupon) => coupon['approval_status'] == 'approved')
        .map((coupon) => (coupon['store_id'] ?? '').toString())
        .where((storeId) => storeId.isNotEmpty)
        .toSet();

    return rows.where((store) {
      final storeImportSource = (store['import_source'] ?? 'manual').toString();
      final storeApprovalStatus =
          (store['approval_status'] ?? 'approved').toString();
      if (storeImportSource != 'manual' && storeApprovalStatus != 'approved') {
        return false;
      }

      final slug = (store['slug'] ?? '').toString();
      return !importedStoreIds.contains(slug) ||
          approvedImportedStoreIds.contains(slug);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final lang = localizations?.locale.languageCode ?? 'ar';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFFBFAFF),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 80,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Constants.primaryColor.withValues(alpha: 0.1),
                const Color(0xFFFBFAFF),
              ],
            ),
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: SearchWidget(
          hintText: 'ابحث عن متجر',
          onSearch: (value) => setState(() => searchQuery = value),
        ),
      ),
      body: Container(
        color: const Color(0xFFFBFAFF),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _storesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const CustomLoadingIndicator(
                message: 'جاري تحميل المتاجر',
              );
            }

            if (snapshot.hasError) {
              return _buildEmptyState(localizations);
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(localizations);
            }

            final storeRows = snapshot.data ?? [];

            // ✅ تحويل البيانات باستخدام Store.fromSupabase
            final allStores =
                storeRows.map((row) => Store.fromSupabase(row, lang)).toList();

            // ✅ Deduplicate حسب key (slug إن وجد وإلا id)
            final seen = <String>{};
            final uniqueStores = <Store>[];
            for (final s in allStores) {
              final key = s.key.trim(); // من الكلاس اللي عدلناه
              if (key.isEmpty) continue;
              if (seen.contains(key)) continue;
              seen.add(key);
              uniqueStores.add(s);
            }

            // ✅ بحث عربي/إنجليزي
            final q = searchQuery.trim().toLowerCase();
            final filteredStores = uniqueStores.where((store) {
              if (q.isEmpty) return true;
              return store.name.toLowerCase().contains(q) ||
                  store.nameAr.toLowerCase().contains(q) ||
                  store.nameEn.toLowerCase().contains(q);
            }).toList();

            if (filteredStores.isEmpty && searchQuery.isNotEmpty) {
              return _buildNoSearchResults(localizations);
            }

            final bool showTitle = searchQuery.isEmpty;

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _storesFuture = _fetchStores();
                });
                await _storesFuture;
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Column(
                  children: [
                    const SizedBox(height: 90),
                    if (showTitle)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 32, 14, 12),
                        child: _StoresHeaderCard(
                          title: localizations?.translate('all_stores') ??
                              'كل المتاجر',
                        ),
                      ),
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.only(
                          left: AppResponsive.isTablet(context) ? 28 : 14,
                          right: AppResponsive.isTablet(context) ? 28 : 14,
                          top: showTitle ? 0 : 32,
                          bottom: 24,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: AppResponsive.gridColumns(
                            context,
                            phone: 3,
                            tablet: 5,
                          ),
                          crossAxisSpacing:
                              AppResponsive.isTablet(context) ? 18 : 12,
                          mainAxisSpacing:
                              AppResponsive.isTablet(context) ? 22 : 16,
                          childAspectRatio:
                              AppResponsive.isTablet(context) ? 0.96 : 0.82,
                        ),
                        itemCount: filteredStores.length,
                        itemBuilder: (context, index) =>
                            StoreGridCard(store: filteredStores[index]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(localizations) {
    return Center(
      child: _StoresStateCard(
        icon: Icons.search_off_rounded,
        text: localizations?.translate('no_search_results') ??
            'لا توجد نتائج مطابقة لبحثك',
      ),
    );
  }

  Widget _buildEmptyState(localizations) {
    return Center(
      child: _StoresStateCard(
        icon: Icons.storefront_outlined,
        text: localizations?.translate('no_stores') ?? 'لا توجد متاجر حالياً',
      ),
    );
  }
}

class _StoresHeaderCard extends StatelessWidget {
  final String title;

  const _StoresHeaderCard({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Constants.primaryColor.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Constants.primaryColor.withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Constants.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.storefront_rounded,
                color: Constants.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Tajawal',
                  color: Constants.textColor,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoresStateCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StoresStateCard({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.09),
        ),
        boxShadow: [
          BoxShadow(
            color: Constants.primaryColor.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Constants.primaryColor.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              size: 34,
              color: Constants.primaryColor.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class StoreGridCard extends StatefulWidget {
  final Store store;
  const StoreGridCard({super.key, required this.store});

  @override
  State<StoreGridCard> createState() => _StoreGridCardState();
}

class _StoreGridCardState extends State<StoreGridCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = AppResponsive.isTablet(context);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreCouponsScreen(store: widget.store),
          ),
        );
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Constants.primaryColor.withValues(alpha: 0.22),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: Constants.primaryColor.withValues(alpha: 0.07),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: widget.store.image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.store.image,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.storefront_rounded,
                                  color: Constants.primaryColor
                                      .withValues(alpha: 0.35),
                                ),
                              )
                            : Icon(
                                Icons.storefront_rounded,
                                color: Constants.primaryColor
                                    .withValues(alpha: 0.35),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: const Color(0xFFE8E6EE),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: isTablet ? 24 : 20,
                width: double.infinity,
                child: Text(
                  widget.store.name,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 10,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Tajawal',
                    color: Constants.storeNameColor,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
