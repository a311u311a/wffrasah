-- Fill the "نساء" (Women) category from several AliExpress women's-clothing
-- sub-categories, modest styles only. Each `|` part is its own search
-- (needs the aliexpress-sync version that splits on `|`).
-- Left out on purpose: lingerie, bikinis, bras, tanks/camis/bodysuits.
-- The last `-` group lists title words that drop a product (sheer, revealing,
-- short skirts/shorts, men's or kids' items) - needs the sync version with
-- exclude groups.
update public.categories
set ali_keywords = concat_ws(' | ',
  '2026 women modest long maxi dress',
  'women abaya 2026',
  'women casual long dress modest',
  'women modest evening gown long sleeve',
  'modest wedding dress long sleeve',
  'modest prom dress long sleeve',
  'women matching sets long sleeve',
  'women blouse shirt long sleeve',
  'women long sleeve tunic top modest',
  'women wide leg jeans',
  'women wide leg pants trousers',
  'women modest jumpsuit long sleeve',
  'women sweater pullover',
  'women cardigan',
  'women hoodie sweatshirt',
  'women long sleeve pajamas set',
  'women blazer suit set',
  'women jacket vest',
  'women down coat parka',
  'women wool trench coat',
  'women leather fur coat',
  'women cape poncho',
  '-مثير, سكسي, sexy, شفاف, شفافة, see through, sheer, مكشوف, مكشوفة, عاري, عارية, '
  || 'بكيني, bikini, لانجري, lingerie, ملابس داخلية, قميص نوم, تنورة قصيرة, mini skirt, '
  || 'ميني, شورت, shorts, كروب, crop, ظهر مفتوح, backless, الرجال, للرجال, رجالي, '
  || 'للأطفال, أطفال'
)
where name_en = 'Women';
