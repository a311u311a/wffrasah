import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../models/category.dart';
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
      height: 100,
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
    return GestureDetector(
      onTap: () => widget.onCategorySelected(category.id),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
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
                        width: 35,
                        height: 35,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.category_outlined,
                          size: 35,
                          color: isSelected
                              ? Colors.white
                              : Constants.primaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.category_outlined,
                      size: 35,
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
                fontSize: 11,
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
    return GestureDetector(
      onTap: () => widget.onCategorySelected(null),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
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
                width: 35,
                height: 35,
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
                fontSize: 11,
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
