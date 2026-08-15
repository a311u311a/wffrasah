import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/store.dart';
import '../providers/locale_provider.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_footer.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_store_card.dart';

/// صفحة المتاجر للويب
class WebStoresScreen extends StatefulWidget {
  const WebStoresScreen({super.key});

  @override
  State<WebStoresScreen> createState() => _WebStoresScreenState();
}

class _WebStoresScreenState extends State<WebStoresScreen> {
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

  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();

  List<Store> allStores = [];
  List<Store> filteredStores = [];
  List<Category> categories = [];
  String? selectedCategoryId;

  bool isLoading = true;
  String searchQuery = '';

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
      final results = await Future.wait([
        supabase.from('stores').select().order('name_ar', ascending: true),
        supabase.from('categories').select().order('name_ar', ascending: true),
        supabase
            .from('coupons')
            .select('store_id,import_source,approval_status')
            .neq('import_source', 'manual'),
      ]);

      final storesData = results[0] as List;
      final categoriesData = results[1] as List;
      final importedCouponsData = results[2] as List;
      final importedStoreIds = importedCouponsData
          .map((coupon) => (coupon['store_id'] ?? '').toString())
          .where((storeId) => storeId.isNotEmpty)
          .toSet();
      final approvedImportedStoreIds = importedCouponsData
          .where((coupon) => coupon['approval_status'] == 'approved')
          .map((coupon) => (coupon['store_id'] ?? '').toString())
          .where((storeId) => storeId.isNotEmpty)
          .toSet();

      final loadedStores = storesData
          .where((store) {
            final storeImportSource =
                (store['import_source'] ?? 'manual').toString();
            final storeApprovalStatus =
                (store['approval_status'] ?? 'approved').toString();
            if (storeImportSource != 'manual' &&
                storeApprovalStatus != 'approved') {
              return false;
            }

            final slug = (store['slug'] ?? '').toString();
            return !importedStoreIds.contains(slug) ||
                approvedImportedStoreIds.contains(slug);
          })
          .map((store) => Store.fromSupabase(store, langCode))
          .toList();

      final loadedCategories = categoriesData
          .map((cat) => Category.fromSupabase(cat, langCode))
          .toList();

      setState(() {
        allStores = loadedStores;
        filteredStores = loadedStores;
        categories = loadedCategories;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  void _filterStores(String query) {
    setState(() {
      searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Store> result = allStores;

    if (selectedCategoryId != null) {
      result = result
          .where((store) => store.categoryId == selectedCategoryId)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      result = result.where((store) {
        return store.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            store.nameAr.toLowerCase().contains(searchQuery.toLowerCase()) ||
            store.nameEn.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    filteredStores = result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Directionality(
      textDirection: TextDirection.rtl,
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
                          if (isDesktop) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 4, child: _buildStoresSection()),
                                const SizedBox(width: 24),
                                SizedBox(
                                  width: 280,
                                  child: _buildCategoriesSidebar(),
                                ),
                              ],
                            ),
                          ] else ...[
                            _buildCategoriesSection(),
                            const SizedBox(height: 24),
                            _buildStoresSection(),
                          ],
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
                  'تصفح جميع المتاجر والفلترة حسب الفئة أو الاسم',
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
                  'جميع المتاجر في واجهة موحدة وسريعة',
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
                'ابحث عن المتجر المناسب، صف النتائج حسب الفئة، وانتقل مباشرة إلى صفحة كل متجر من نفس الشاشة.',
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
              onChanged: _filterStores,
              style: GoogleFonts.cairo(
                color: ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'ابحث عن متجر...',
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
                _filterStores('');
              },
              icon: const Icon(Icons.clear_rounded, color: secondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoresSection() {
    return _buildSection(
      title: 'المتاجر',
      subtitle: selectedCategoryId == null
          ? 'كل المتاجر المتاحة مرتبة في شبكة واحدة مع البحث المباشر.'
          : 'النتائج الحالية مفلترة حسب الفئة المحددة مع استمرار البحث النصي.',
      child: _buildStoresGrid(),
    );
  }

  Widget _buildCategoriesSection() {
    return _buildSection(
      title: 'الفئات',
      subtitle: 'اختر الفئة المناسبة لتصفية المتاجر بسرعة من نفس الصفحة.',
      child: _buildCategoriesHorizontal(),
    );
  }

  Widget _buildStoresGrid() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (filteredStores.isEmpty) {
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
            const Icon(Icons.store_outlined, size: 80, color: faded),
            const SizedBox(height: 20),
            Text(
              searchQuery.isEmpty
                  ? 'لا توجد متاجر متاحة'
                  : 'لا توجد نتائج للبحث عن "$searchQuery"',
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
            'تم العثور على ${filteredStores.length} متجر',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveLayout.isDesktop(context) ? 4 : 2,
            crossAxisSpacing: ResponsiveGrid.spacing(context),
            mainAxisSpacing: ResponsiveGrid.spacing(context),
            childAspectRatio: 0.75,
          ),
          itemCount: filteredStores.length,
          itemBuilder: (context, index) {
            return WebStoreCard(
              store: filteredStores[index],
              onTap: () {
                final store = filteredStores[index];
                Navigator.pushNamed(
                  context,
                  '/store/${store.slug}',
                  arguments: store,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoriesSidebar() {
    return _buildSection(
      title: 'الفئات',
      subtitle: 'اختيار الفئة يحدث النتائج فوراً من دون تغيير في المهام.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryItem(null, 'الكل', Icons.apps_rounded),
          ...categories.map(
            (category) => _buildCategoryItem(
              category.id,
              category.name,
              Icons.label_rounded,
              imageUrl: category.image,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    String? categoryId,
    String name,
    IconData icon, {
    String? imageUrl,
  }) {
    final isSelected = selectedCategoryId == categoryId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedCategoryId = categoryId;
              _applyFilters();
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0EEFF) : panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFFD8D4FF) : stroke,
              ),
            ),
            child: Row(
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        icon,
                        size: 20,
                        color: isSelected ? orange : secondary,
                      ),
                    ),
                  )
                else
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected ? orange : secondary,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? ink : secondary,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: yellow,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesHorizontal() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHorizontalCategoryChip(null, 'الكل');
          }
          final category = categories[index - 1];
          return _buildHorizontalCategoryChip(category.id, category.name);
        },
      ),
    );
  }

  Widget _buildHorizontalCategoryChip(String? categoryId, String name) {
    final isSelected = selectedCategoryId == categoryId;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          name,
          style: GoogleFonts.cairo(
            color: isSelected ? Colors.white : secondary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        selectedColor: orange,
        backgroundColor: panel,
        side: BorderSide(color: isSelected ? orange : stroke),
        checkmarkColor: Colors.white,
        onSelected: (_) {
          setState(() {
            selectedCategoryId = categoryId;
            _applyFilters();
          });
        },
      ),
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
}
