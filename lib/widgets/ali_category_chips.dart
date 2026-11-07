import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/ali_category.dart';
import '../services/ali_products_service.dart';

/// شريط فئات علي إكسبرس (من ali_categories بترتيبها)، مع "الكل" في البداية.
/// يعرض فقط الفئات المفعّلة اللي فيها منتجات.
class AliCategoryChips extends StatefulWidget {
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const AliCategoryChips({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  State<AliCategoryChips> createState() => _AliCategoryChipsState();
}

class _AliCategoryChipsState extends State<AliCategoryChips> {
  late final Future<List<AliCategory>> _future =
      AliProductsService.fetchCategories();

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    return SizedBox(
      height: 46,
      child: FutureBuilder<List<AliCategory>>(
        future: _future,
        builder: (context, snapshot) {
          final categories = snapshot.data ?? const <AliCategory>[];
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              if (i == 0) {
                return _chip(null, langCode == 'en' ? 'All' : 'الكل', '');
              }
              final c = categories[i - 1];
              return _chip(c.id, c.name(langCode), c.icon);
            },
          );
        },
      ),
    );
  }

  Widget _chip(String? id, String label, String icon) {
    final selected = widget.selectedId == id;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => widget.onSelected(id),
      avatar: icon.isEmpty
          ? null
          : ClipOval(
              child: Container(
                color: Colors.white,
                child: CachedNetworkImage(
                  imageUrl: icon,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 13,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? Colors.white : Constants.textColor,
        ),
      ),
      selectedColor: Constants.primaryColor,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? Constants.primaryColor : Constants.mutedBorderColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
