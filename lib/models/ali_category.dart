/// فئة من فئات علي إكسبرس (جدول ali_categories)، منفصلة عن فئات المتاجر.
class AliCategory {
  final String id;
  final String nameAr;
  final String nameEn;
  final String icon;
  final int sortOrder;
  final String keywords;
  final bool active;

  const AliCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.sortOrder,
    this.keywords = '',
    this.active = true,
  });

  String name(String langCode) =>
      langCode == 'en' && nameEn.isNotEmpty ? nameEn : nameAr;

  factory AliCategory.fromMap(Map<String, dynamic> m) => AliCategory(
        id: (m['id'] ?? '').toString(),
        nameAr: (m['name_ar'] ?? '').toString(),
        nameEn: (m['name_en'] ?? '').toString(),
        icon: (m['icon'] ?? '').toString(),
        sortOrder: num.tryParse('${m['sort_order']}')?.toInt() ?? 0,
        keywords: (m['keywords'] ?? '').toString(),
        active: m['active'] != false,
      );
}
