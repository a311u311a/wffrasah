import '../utils/expiry.dart';

class Carousel {
  final String name;
  final String nameAr;
  final String nameEn;
  final String image;
  final String web;
  final DateTime? expiryDate;

  bool get isExpired => isExpiredDate(expiryDate);

  Carousel({
    required this.name,
    required this.nameAr,
    required this.nameEn,
    required this.image,
    required this.web,
    this.expiryDate,
  });

  factory Carousel.fromMap(Map<String, dynamic> data, String langCode) {
    final nAr = (data['name_ar'] ?? data['name'] ?? '').toString();
    final nEn = (data['name_en'] ?? data['name'] ?? '').toString();

    return Carousel(
      name: langCode == 'ar' ? nAr : nEn,
      nameAr: nAr,
      nameEn: nEn,
      image: (data['image'] ?? '').toString(),
      web: (data['web'] ?? '').toString(),
      expiryDate: parseExpiryDate(data['expiry_date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'name_ar': nameAr,
      'name_en': nameEn,
      'image': image,
      'web': web,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }
}
