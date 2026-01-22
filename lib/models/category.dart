class Category {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String web;
  final String image;

  Category({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.web,
    required this.image,
  });

  factory Category.fromSupabase(Map<String, dynamic> data, String langCode) {
    final nAr = data['name_ar'] ?? data['name'] ?? '';
    final nEn = data['name_en'] ?? data['name'] ?? '';
    final dAr = data['description_ar'] ?? data['description'] ?? '';
    final dEn = data['description_en'] ?? data['description'] ?? '';

    return Category(
      id: data['id'].toString(),
      categoryId: data['categoryId']?.toString() ?? '',
      name: langCode == 'ar' ? nAr : nEn,
      description: langCode == 'ar' ? dAr : dEn,
      nameAr: nAr,
      nameEn: nEn,
      descriptionAr: dAr,
      descriptionEn: dEn,
      web: data['web'] ?? '',
      image: data['image'] ?? '',
    );
  }
}
