import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/ali_product.dart';
import '../models/category.dart';
import '../providers/locale_provider.dart';
import '../services/ali_products_service.dart';
import '../services/home_data_service.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_ali_products_grid.dart';
import '../web_widgets/web_footer.dart';
import '../web_widgets/web_i18n.dart';
import '../web_widgets/web_navigation_bar.dart';

/// صفحة كل عروض علي إكسبرس في الموقع، مع فلترة حسب الفئة.
class WebAliProductsScreen extends StatefulWidget {
  const WebAliProductsScreen({super.key});

  @override
  State<WebAliProductsScreen> createState() => _WebAliProductsScreenState();
}

class _WebAliProductsScreenState extends State<WebAliProductsScreen> {
  static const Color bg = Color(0xFFFAFAFF);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color panelDark = Color(0xFFF2F0FF);
  static const Color stroke = Color(0xFFE2DEFF);
  static const Color line = Color(0xFFEDEAFF);
  static const Color ink = Color(0xFF25213B);
  static const Color accent = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF68627F);
  static const Color faded = Color(0xFF9B96B6);

  String? _categoryId;
  List<Category> _categories = [];
  late Future<List<AliProduct>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
    _loadCategories();
  }

  Future<List<AliProduct>> _fetch() =>
      AliProductsService.fetch(categoryId: _categoryId, limit: 60);

  Future<void> _loadCategories() async {
    final langCode =
        Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    try {
      final results = await Future.wait([
        HomeDataService.fetchCategories(),
        AliProductsService.fetchCategoryIds(),
      ]);
      final rows = results[0] as List<Map<String, dynamic>>;
      final activeIds = results[1] as Set<String>;
      final categories = rows
          .map((row) => Category.fromSupabase(row, langCode))
          .where((c) => activeIds.contains(c.id))
          .toList();
      if (mounted) setState(() => _categories = categories);
    } catch (e) {
      debugPrint('WebAliProductsScreen categories error: $e');
    }
  }

  void _selectCategory(String? id) {
    if (id == _categoryId) return;
    setState(() {
      _categoryId = id;
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
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
                        _buildHeader(),
                        const SizedBox(height: 28),
                        _buildProducts(),
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
    );
  }

  Widget _buildHeader() {
    final compact = !ResponsiveLayout.isDesktop(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 28),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            webText(context, 'عروض علي إكسبرس', 'AliExpress deals'),
            style: GoogleFonts.cairo(
              color: accent,
              fontSize: compact ? 28 : 38,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            webText(
              context,
              'منتجات مختارة من علي إكسبرس بأسعار مخفّضة، تتحدث باستمرار. اضغط على المنتج لتشتريه مباشرة من علي إكسبرس.',
              'Hand-picked discounted AliExpress products, refreshed regularly. Tap a product to buy it on AliExpress.',
            ),
            style: GoogleFonts.cairo(
              color: secondary,
              fontSize: compact ? 14 : 16,
              height: 1.9,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_categories.isNotEmpty) ...[
            const SizedBox(height: 20),
            // Wrap بدل التمرير الأفقي حتى تظهر كل الفئات بدون قص.
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chip(null, webText(context, 'الكل', 'All')),
                for (final c in _categories) _chip(c.id, c.name),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String? id, String label) {
    final selected = _categoryId == id;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Text(
        label,
        style: GoogleFonts.cairo(
          color: selected ? Colors.white : secondary,
          fontSize: 14,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
      selectedColor: accent,
      backgroundColor: panel,
      side: BorderSide(color: selected ? accent : stroke),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onSelected: (_) => _selectCategory(id),
    );
  }

  Widget _buildProducts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: panelDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: line),
      ),
      child: FutureBuilder<List<AliProduct>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final items = snapshot.data ?? const <AliProduct>[];
          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 48, color: faded),
                  const SizedBox(height: 12),
                  Text(
                    webText(
                      context,
                      'لا توجد عروض من علي إكسبرس في هذه الفئة حالياً',
                      'No AliExpress deals in this category right now',
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      color: secondary,
                      fontSize: 15,
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
              Text(
                webText(
                  context,
                  'تم العثور على ${items.length} منتج',
                  '${items.length} products found',
                ),
                style: GoogleFonts.cairo(
                  color: ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              WebAliProductsGrid(items: items),
            ],
          );
        },
      ),
    );
  }
}
