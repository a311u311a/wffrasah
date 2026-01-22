class Store {
  final String id;
  final String slug; // ✅ من الداتابيس (قد يكون فاضي)

  final String name;
  final String description;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String image;

  Store({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.image,
  });

  /// ✅ مفتاح الربط الموحّد:
  /// استخدميه في الفلترة والربط بدل slug مباشرة
  String get key => (slug.trim().isNotEmpty) ? slug.trim() : id;

  bool get hasSlug => slug.trim().isNotEmpty;

  factory Store.fromSupabase(Map<String, dynamic> data, String langCode) {
    final id = (data['id'] ?? '').toString().trim();

    final nAr = (data['name_ar'] ?? data['name'] ?? '').toString().trim();
    final nEn = (data['name_en'] ?? data['name'] ?? '').toString().trim();

    final dAr =
        (data['description_ar'] ?? data['description'] ?? '').toString().trim();
    final dEn =
        (data['description_en'] ?? data['description'] ?? '').toString().trim();

    // ✅ slug الحقيقي من الداتابيس فقط (بدون fallback هنا)
    final slug = (data['slug'] ?? '').toString().trim();

    final displayName = (langCode == 'ar')
        ? (nAr.isNotEmpty ? nAr : (nEn.isNotEmpty ? nEn : ''))
        : (nEn.isNotEmpty ? nEn : (nAr.isNotEmpty ? nAr : ''));

    final displayDesc = (langCode == 'ar')
        ? (dAr.isNotEmpty ? dAr : dEn)
        : (dEn.isNotEmpty ? dEn : dAr);

    return Store(
      id: id,
      slug: slug,
      name: displayName,
      description: displayDesc,
      nameAr: nAr,
      nameEn: nEn,
      descriptionAr: dAr,
      descriptionEn: dEn,
      image: (data['image'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'image': image,
      'slug': slug,
    };
  }
}
