-- Fill the "نساء" (Women) category from several AliExpress women's-clothing
-- sub-categories, modest styles only. Each `|` part is its own search
-- (needs the aliexpress-sync version that splits on `|`).
-- Left out on purpose: lingerie, bikinis, bras, tanks/camis/bodysuits.
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
  'women oversized t-shirt',
  'women wide leg jeans',
  'women wide leg pants trousers',
  'women modest jumpsuit long sleeve',
  'women sweater pullover',
  'women cardigan',
  'women hoodie sweatshirt',
  'women pajamas robe set',
  'women blazer suit set',
  'women jacket vest',
  'women down coat parka',
  'women wool trench coat',
  'women leather fur coat',
  'women cape poncho'
)
where name_en = 'Women';
