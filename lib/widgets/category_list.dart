import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../models/category.dart';
import 'error_message.dart';
import 'loading_indicator.dart';

class CategoryList extends StatelessWidget {
  final Function(String?) onCategorySelected;
  final String? selectedCategoryId;

  const CategoryList({
    super.key,
    required this.onCategorySelected,
    this.selectedCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final supabase = Supabase.instance.client;

    return SizedBox(
      height: 100,
      child: StreamBuilder<List<dynamic>>(
        // ✅ جدول Supabase الصحيح: offers
        stream: supabase.from('offers').stream(primaryKey: ['id']),
        builder: (context, offersSnapshot) {
          if (offersSnapshot.hasError) return const SizedBox();
          if (!offersSnapshot.hasData) return const CustomLoadingIndicator();

          final offerRows =
              (offersSnapshot.data ?? []).cast<Map<String, dynamic>>();

          // ✅ الحقل الصحيح: category_id (مع fallback لو فيه بيانات قديمة)
          final Set<String> activeCategoryIds = offerRows
              .map((data) =>
                  (data['category_id'] ?? data['categoryId'])?.toString())
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toSet();

          return StreamBuilder<List<dynamic>>(
            // ✅ جدول Supabase الصحيح: categories
            stream: supabase.from('categories').stream(primaryKey: ['id']),
            builder: (context, categorySnapshot) {
              if (categorySnapshot.hasError) {
                return ErrorMessage(
                    message:
                        localizations?.translate('error_loading_categories') ??
                            'خطأ في تحميل الفئات');
              }
              if (!categorySnapshot.hasData)
                return const CustomLoadingIndicator();

              final categoryRows =
                  (categorySnapshot.data ?? []).cast<Map<String, dynamic>>();

              final categories = categoryRows
                  .map((data) => Category.fromSupabase(
                      data, localizations?.locale.languageCode ?? 'ar'))
                  // ✅ الآن يطابق categories.id لأننا صححنا offers.category_id في DB
                  .where((category) => activeCategoryIds.contains(category.id))
                  .toList();

              if (categories.isEmpty) return const SizedBox();

              return Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8, right: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildShowAllItem(
                          context, selectedCategoryId == null);
                    }
                    final category = categories[index - 1];
                    return _buildCategoryItem(
                        category, selectedCategoryId == category.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(Category category, bool isSelected) {
    return GestureDetector(
      onTap: () => onCategorySelected(category.id),
      child: Container(
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
                  ? Image.network(
                      category.image,
                      width: 35,
                      height: 35,
                      color: isSelected ? Colors.white : Constants.primaryColor,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.category_outlined,
                        size: 35,
                        color:
                            isSelected ? Colors.white : Constants.primaryColor,
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
      onTap: () => onCategorySelected(null),
      child: Container(
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
