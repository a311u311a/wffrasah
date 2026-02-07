import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../models/store.dart';
import '../models/category.dart';
import '../providers/locale_provider.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';
import '../web_widgets/web_store_card.dart';

/// صفحة المتاجر للويب
class WebStoresScreen extends StatefulWidget {
  const WebStoresScreen({super.key});

  @override
  State<WebStoresScreen> createState() => _WebStoresScreenState();
}

class _WebStoresScreenState extends State<WebStoresScreen> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

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
      // تحميل المتاجر والفئات بالتوازي
      final results = await Future.wait([
        supabase.from('stores').select().order('name_ar', ascending: true),
        supabase.from('categories').select().order('name_ar', ascending: true),
      ]);

      final storesData = results[0] as List;
      final categoriesData = results[1] as List;

      final loadedStores = storesData
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

    // تصفية حسب الفئة
    if (selectedCategoryId != null) {
      result = result
          .where((store) => store.categoryId == selectedCategoryId)
          .toList();
    }

    // تصفية حسب البحث
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
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const WebNavigationBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            _buildHeader(),

            // Search Section
            _buildSearchSection(),

            // المحتوى الرئيسي: القائمة الجانبية + شبكة المتاجر
            Padding(
              padding: ResponsivePadding.page(context),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // شبكة المتاجر (الجزء الأكبر)
                        Expanded(
                          flex: 4,
                          child: _buildStoresGrid(),
                        ),
                        const SizedBox(width: 24),
                        // قائمة الفئات على اليمين
                        SizedBox(
                          width: 220,
                          child: _buildCategoriesSidebar(),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        // قائمة الفئات أفقية للموبايل
                        _buildCategoriesHorizontal(),
                        const SizedBox(height: 20),
                        _buildStoresGrid(),
                      ],
                    ),
            ),

            // Footer
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: ResponsivePadding.page(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Constants.primaryColor.withValues(alpha: 0.1),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: Constants.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'جميع المتاجر',
                style: TextStyle(
                  fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
                  fontWeight: FontWeight.w900,
                  color: Constants.primaryColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '🛍️ تصفح متاجرك المفضلة واحصل على أفضل العروض والكوبونات',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsivePadding.page(context).horizontal,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط البحث
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: TextField(
              controller: searchController,
              onChanged: _filterStores,
              decoration: InputDecoration(
                hintText: 'ابحث عن متجر...',
                hintStyle: const TextStyle(fontFamily: 'Tajawal'),
                prefixIcon: Icon(Icons.search, color: Constants.primaryColor),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _filterStores('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Constants.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
        ],
      ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Column(
            children: [
              Icon(
                Icons.store_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 20),
              Text(
                searchQuery.isEmpty
                    ? 'لا توجد متاجر متاحة'
                    : 'لا توجد نتائج للبحث عن "$searchQuery"',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عدد المتاجر
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            'تم العثور على ${filteredStores.length} متجر',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // الشبكة
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

  /// قائمة الفئات الجانبية (للديسكتوب)
  Widget _buildCategoriesSidebar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              Icon(Icons.category_rounded,
                  color: Constants.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'الفئات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Constants.primaryColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // زر "الكل"
          _buildCategoryItem(null, 'الكل', Icons.apps_rounded),

          // قائمة الفئات
          ...categories.map((category) => _buildCategoryItem(
                category.id,
                category.name,
                Icons.label_rounded,
                imageUrl: category.image,
              )),
        ],
      ),
    );
  }

  /// عنصر فئة واحد
  Widget _buildCategoryItem(String? categoryId, String name, IconData icon,
      {String? imageUrl}) {
    final isSelected = selectedCategoryId == categoryId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedCategoryId = categoryId;
              _applyFilters();
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Constants.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: Constants.primaryColor.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      imageUrl,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        icon,
                        size: 20,
                        color: isSelected
                            ? Constants.primaryColor
                            : Colors.grey[600],
                      ),
                    ),
                  )
                else
                  Icon(
                    icon,
                    size: 20,
                    color:
                        isSelected ? Constants.primaryColor : Colors.grey[600],
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Constants.primaryColor
                          : Colors.grey[800],
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Constants.primaryColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// قائمة الفئات الأفقية (للموبايل/تابلت)
  Widget _buildCategoriesHorizontal() {
    return SizedBox(
      height: 50,
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
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[800],
            fontFamily: 'Tajawal',
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        selectedColor: Constants.primaryColor,
        backgroundColor: Colors.grey[100],
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
}
