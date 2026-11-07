-- Phase 4 review: sharper searches and per-category exclusions after the
-- first sync showed car accessories, anime keychains and off-topic items
-- leaking into other categories. Same format as ali_categories.keywords:
-- searches separated by `|`, and a `-` group of title words to drop.
-- Women and the other untouched categories keep their keywords.

update public.ali_categories set updated_at = now(), keywords = v.keywords
from (values
  ('home-kitchen',
    'kitchen gadgets | coffee tools | incense burner bakhoor | home decor | storage organizer | bedding set'
    || ' | -السيارة, سيارة, للسيارة, car , الأحذية'
    || ' | -الاتحاد الأوروبي, معيار الاتحاد, eu plug, قابس أوروبي, القابس الأوروبي'),
  ('phones',
    'phone case | fast charger | wireless earbuds | phone holder | usb c cable | power bank'
    || ' | -مقعد السيارة, الفجوة'
    || ' | -الاتحاد الأوروبي, معيار الاتحاد, eu plug, قابس أوروبي, القابس الأوروبي'),
  ('beauty',
    'makeup brushes tools | facial cleansing device | hair styling tools | nail art | skin care tools'
    || ' | -ساعة ذكية, الساعات الذكية, smart watch, ميزان الحرارة'),
  ('men',
    'men shirt long sleeve | men pants trousers | men jacket | men hoodie | men thobe accessories'
    || ' | -مثير, سكسي, sexy, شفاف, see through, ملابس داخلية, underwear, شورت قصير, دبوس'),
  ('shoes',
    'women shoes | men shoes | kids shoes | women sneakers | men sneakers'
    || ' | -أربطة, ممحاة, غسالة, insole, نعل ممتص'),
  ('bags-travel',
    'women handbag | backpack | luggage suitcase | wallet | travel organizer'
    || ' | -BT21, أنيمي, anime, سترة, ميدالية'),
  ('watches-jewelry',
    'watches | smart watch | women jewelry | men ring bracelet | women sunglasses | men sunglasses'
    || ' | -السيارة, سيارة, للسيارة, حزام خصر, تكتيكي, ديكور'),
  ('cars',
    'car interior accessories | car electronics | car cleaning tools | car phone holder'
    || ' | -كابل بيانات'),
  ('appliances',
    'electric kettle | portable blender | handheld vacuum cleaner home | air humidifier home | electric toothbrush | hair dryer'
    || ' | -السيارة, سيارة, للسيارة, car , مانيكير, الأظافر, كابل'
    || ' | -الاتحاد الأوروبي, معيار الاتحاد, eu plug, قابس أوروبي, القابس الأوروبي'),
  ('pets',
    'cat supplies | dog supplies | pet bed | pet toys'
    || ' | -طلاء الأظافر, الأظافر, هلام'),
  ('office-school',
    'stationery | office supplies | school backpack | desk organizer'
    || ' | -BT21, أنيمي, anime, أكياس البلاستيك, أكياس تسوق, دبابيس المينا, دبوس'),
  ('gifts-occasions',
    'ramadan decoration | eid mubarak decoration | gift box packaging | birthday party decoration | balloons party'
    || ' | -سبونجبوب, حوض, عشوائي, mystery, الغموض')
) as v(id, keywords)
where public.ali_categories.id = v.id;
