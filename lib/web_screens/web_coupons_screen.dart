import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../localization/app_localizations.dart';
import '../models/coupon.dart';
import '../models/store.dart';
import '../providers/locale_provider.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';
import '../web_widgets/web_coupon_card.dart';

/// صفحة الكوبونات للويب
class WebCouponsScreen extends StatefulWidget {
  const WebCouponsScreen({super.key});

  @override
  State<WebCouponsScreen> createState() => _WebCouponsScreenState();
}

class _WebCouponsScreenState extends State<WebCouponsScreen> {
  static const Color bg = Color(0xFFFAFAFF);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color panelDark = Color(0xFFF2F0FF);
  static const Color stroke = Color(0xFFE2DEFF);
  static const Color line = Color(0xFFEDEAFF);
  static const Color ink = Color(0xFF25213B);
  static const Color orange = Color(0xFF6C63FF);
  static const Color pink = Color(0xFF8B84FF);
  static const Color yellow = Color(0xFFFF6584);
  static const Color secondary = Color(0xFF68627F);
  static const Color faded = Color(0xFF9B96B6);

  final supabase = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();
  List<Coupon> coupons = [];
  List<Store> stores = [];
  Map<String, Store> storesMap = {};
  bool isLoading = true;
  String searchQuery = '';

  String _t(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final langCode = localeProvider.locale.languageCode;

    try {
      // تحميل المتاجر
      final storesData = await supabase
          .from('stores')
          .select()
          .order('name_ar', ascending: true);

      final loadedStores = (storesData as List)
          .where((store) {
            final importSource =
                (store['import_source'] ?? 'manual').toString();
            final approvalStatus =
                (store['approval_status'] ?? 'approved').toString();
            return importSource == 'manual' || approvalStatus == 'approved';
          })
          .map((store) => Store.fromSupabase(store, langCode))
          .toList();

      final tempMap = <String, Store>{};
      for (var store in loadedStores) {
        tempMap[store.id.toLowerCase().trim()] = store;
        if (store.slug.isNotEmpty) {
          tempMap[store.slug.toLowerCase().trim()] = store;
        }
      }
      storesMap = tempMap;

      // تحميل الكوبونات
      final couponsData = await supabase
          .from('coupons')
          .select()
          .eq('approval_status', 'approved')
          .order('created_at', ascending: false);

      final loadedCoupons = (couponsData as List)
          .map((coupon) => Coupon.fromSupabase(coupon, langCode))
          .toList();

      setState(() {
        stores = loadedStores;
        coupons = loadedCoupons;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_t('error_prefix')}: $e')),
        );
      }
    }
  }

  List<Coupon> get filteredCoupons {
    if (searchQuery.isEmpty) return coupons;

    return coupons.where((coupon) {
      final store = storesMap[coupon.storeId];
      return coupon.code.toLowerCase().contains(searchQuery.toLowerCase()) ||
          coupon.description
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          (store?.name.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic =
        Provider.of<LocaleProvider>(context).locale.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Theme(
        data: theme.copyWith(
          scaffoldBackgroundColor: bg,
          textTheme: GoogleFonts.cairoTextTheme(theme.textTheme),
        ),
        child: Scaffold(
          backgroundColor: bg,
          appBar: const WebNavigationBar(),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroHeader(),
                          const SizedBox(height: 28),
                          _buildCouponsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
                const WebFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: EdgeInsets.all(ResponsiveLayout.isDesktop(context) ? 28 : 20),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: stroke),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A6C63FF),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EEFF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFD8D4FF)),
                ),
                child: Text(
                  _t('coupons_hero_badge'),
                  style: GoogleFonts.cairo(
                    color: ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              ShaderMask(
                shaderCallback: (bounds) =>
                    const LinearGradient(colors: [orange, yellow, pink])
                        .createShader(bounds),
                child: Text(
                  _t('coupons_hero_title'),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: compact ? 28 : 38,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _t('coupons_hero_subtitle'),
                style: GoogleFonts.cairo(
                  color: secondary,
                  fontSize: compact ? 14 : 16,
                  height: 1.9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _buildSearchBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panelDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: searchQuery.isNotEmpty ? orange : stroke,
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: secondary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() => searchQuery = value),
              style: GoogleFonts.cairo(
                color: ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: _t('search_hint'),
                hintStyle: GoogleFonts.cairo(
                  color: faded,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                searchController.clear();
                setState(() => searchQuery = '');
              },
              icon: const Icon(Icons.clear_rounded, color: secondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCouponsSection() {
    return _buildSection(
      title: _t('coupons'),
      subtitle: _t('coupons_page_subtitle'),
      child: _buildCouponsGrid(),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panelDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              color: ink,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.cairo(
              color: secondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }

  Widget _buildCouponsGrid() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final displayCoupons = filteredCoupons;

    if (displayCoupons.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: stroke),
        ),
        child: Column(
          children: [
            const Icon(Icons.confirmation_number_outlined,
                size: 80, color: faded),
            const SizedBox(height: 20),
            Text(
              searchQuery.isNotEmpty
                  ? _t('no_coupon_search_results')
                      .replaceAll('{query}', searchQuery)
                  : _t('no_coupons'),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 18,
                color: secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            _t('coupons_found')
                .replaceAll('{count}', '${displayCoupons.length}'),
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1024
                ? 4
                : ResponsiveGrid.columnsForWidth(width, max: 4);
            final spacing = ResponsiveGrid.spacingForWidth(width);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: width >= 1024 ? 0.76 : 0.68,
              ),
              itemCount: displayCoupons.length,
              itemBuilder: (context, index) {
                final coupon = displayCoupons[index];
                final store = storesMap[coupon.storeId.toLowerCase().trim()];

                return WebCouponCard(
                  coupon: coupon,
                  storeName: store?.name ?? _t('store'),
                  compact: true,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
