// صفحة المتاجر (تعرض كل المتاجر)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rbhan/screens/store_coupons_screen.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/store.dart';
import '../localization/app_localizations.dart';
import '../widgets/search_widget.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  String searchQuery = '';

  late final Stream<List<Map<String, dynamic>>> _storesStream;

  @override
  void initState() {
    super.initState();
    final sb = Supabase.instance.client;

    _storesStream = sb.from('stores').stream(primaryKey: ['id']).order(
        'created_at',
        ascending: false); // أو order('name_ar')
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final lang = localizations?.locale.languageCode ?? 'ar';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
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
                Colors.white,
              ],
            ),
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: SearchWidget(
          hintText:
              localizations?.translate('search_store_hint') ?? 'البحث عن متجر',
          onSearch: (value) => setState(() => searchQuery = value),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _storesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: Constants.primaryColor),
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

            return Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  if (showTitle)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          localizations?.translate('all_stores') ??
                              'كل المتاجر',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                            color: Constants.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 20,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 15,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: filteredStores.length,
                      itemBuilder: (context, index) =>
                          _StoreCard(store: filteredStores[index]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            localizations?.translate('no_search_results') ??
                'لا توجد نتائج مطابقة لبحثك',
            style: TextStyle(color: Colors.grey[500], fontFamily: 'Tajawal'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            localizations?.translate('no_stores') ?? 'لا توجد متاجر حالياً',
            style: TextStyle(color: Colors.grey[500], fontFamily: 'Tajawal'),
          ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatefulWidget {
  final Store store;
  const _StoreCard({required this.store});

  @override
  State<_StoreCard> createState() => _StoreCardState();
}

class _StoreCardState extends State<_StoreCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.store.image.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: CachedNetworkImage(
                            imageUrl: widget.store.image,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.storefront_rounded,
                              color: Colors.grey[300],
                            ),
                          ),
                        )
                      : Icon(Icons.storefront_rounded, color: Colors.grey[300]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.store.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Tajawal',
                color: Color(0xFF444444),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
