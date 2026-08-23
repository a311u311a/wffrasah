import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../models/category.dart';
import 'app_responsive.dart';
import 'error_message.dart';
import 'loading_indicator.dart';

class CategoryList extends StatefulWidget {
  final Function(String?) onCategorySelected;
  final String? selectedCategoryId;

  const CategoryList({
    super.key,
    required this.onCategorySelected,
    this.selectedCategoryId,
  });

  static double preferredHeight(BuildContext context) {
    return AppResponsive.isTablet(context) ? 128 : 100;
  }

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _categoriesFuture = _fetchCategories();
  }

  Future<List<Category>> _fetchCategories() async {
    final supabase = Supabase.instance.client;
    final langCode = AppLocalizations.of(context)?.locale.languageCode ?? 'ar';
    final results = await Future.wait([
      supabase.from('offers').select(),
      supabase.from('categories').select(),
    ]).timeout(const Duration(seconds: 12));

    final offerRows = (results[0] as List).cast<Map<String, dynamic>>();
    final activeCategoryIds = offerRows
        .map((data) => (data['category_id'] ?? data['categoryId'])?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    final categoryRows = (results[1] as List).cast<Map<String, dynamic>>();

    return categoryRows
        .map((data) => Category.fromSupabase(data, langCode))
        .where((category) => activeCategoryIds.contains(category.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SizedBox(
      height: CategoryList.preferredHeight(context),
      child: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('CategoryList loading failed: ${snapshot.error}');
            return ErrorMessage(
              message: localizations?.translate('error_loading_categories') ??
                  'خطأ في تحميل الفئات',
            );
          }
          if (!snapshot.hasData) return const CustomLoadingIndicator();
          final categories = snapshot.data!;
          if (categories.isEmpty) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8, right: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildShowAllItem(
                      context, widget.selectedCategoryId == null);
                }
                final category = categories[index - 1];
                return _buildCategoryItem(
                    category, widget.selectedCategoryId == category.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(Category category, bool isSelected) {
    final isTablet = AppResponsive.isTablet(context);
    final iconSize = isTablet ? 48.0 : 35.0;
    final itemWidth = isTablet ? 88.0 : 68.0;
    final itemPadding = isTablet ? 13.0 : 12.0;
    final textScale = AppResponsive.tabletScale(context);
    return GestureDetector(
      onTap: () => widget.onCategorySelected(category.id),
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(itemPadding),
              decoration: BoxDecoration(
                color: isSelected ? Constants.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Constants.primaryColor
                      : Colors.grey.shade300,
                ),
              ),
              child: category.image.isNotEmpty
                  ? ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        isSelected ? Colors.white : Constants.primaryColor,
                        BlendMode.srcIn,
                      ),
                      child: Image.network(
                        category.image,
                        width: iconSize,
                        height: iconSize,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.category_outlined,
                          size: iconSize,
                          color: isSelected
                              ? Colors.white
                              : Constants.primaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.category_outlined,
                      size: iconSize,
                      color: isSelected ? Colors.white : Constants.primaryColor,
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11 * textScale,
                color: isSelected ? Constants.primaryColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowAllItem(BuildContext context, bool isSelected) {
    final localizations = AppLocalizations.of(context);
    final isTablet = AppResponsive.isTablet(context);
    final iconSize = isTablet ? 48.0 : 35.0;
    final itemWidth = isTablet ? 88.0 : 68.0;
    final itemPadding = isTablet ? 13.0 : 12.0;
    final textScale = AppResponsive.tabletScale(context);
    return GestureDetector(
      onTap: () => widget.onCategorySelected(null),
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(itemPadding),
              decoration: BoxDecoration(
                color: isSelected ? Constants.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Constants.primaryColor
                      : Colors.grey.shade300,
                ),
              ),
              child: SvgPicture.asset(
                'assets/icon/apps.svg',
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(
                  isSelected ? Colors.white : Constants.primaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations?.translate('all') ?? 'الكل',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11 * textScale,
                color: isSelected ? Constants.primaryColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
