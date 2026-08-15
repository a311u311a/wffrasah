-- Add "مكتبات" category to public.categories.
-- Safe to run more than once and works even if some optional columns do not exist.

do $$
declare
  insert_columns text[] := array['id'];
  insert_values text[] := array['gen_random_uuid()'];
begin
  if exists (
    select 1
    from public.categories
    where (to_jsonb(categories) ->> 'name') = 'مكتبات'
       or (to_jsonb(categories) ->> 'name_ar') = 'مكتبات'
       or (to_jsonb(categories) ->> 'name_en') = 'Libraries'
  ) then
    return;
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'categories'
      and column_name = 'categoryId'
  ) then
    insert_columns := array_append(insert_columns, '"categoryId"');
    insert_values := array_append(insert_values, quote_literal('libraries'));
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'categories'
      and column_name = 'name'
  ) then
    insert_columns := array_append(insert_columns, 'name');
    insert_values := array_append(insert_values, quote_literal('مكتبات'));
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'categories'
      and column_name = 'name_ar'
  ) then
    insert_columns := array_append(insert_columns, 'name_ar');
    insert_values := array_append(insert_values, quote_literal('مكتبات'));
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'categories'
      and column_name = 'name_en'
  ) then
    insert_columns := array_append(insert_columns, 'name_en');
    insert_values := array_append(insert_values, quote_literal('Libraries'));
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'categories'
      and column_name = 'description'
  ) then
    insert_columns := array_append(insert_columns, 'description');
    insert_values := array_append(insert_values, quote_literal('كتب، قرطاسية، مكتبات، ولوازم تعليمية'));
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'categories'
      and column_name = 'web'
  ) then
    insert_columns := array_append(insert_columns, 'web');
    insert_values := array_append(insert_values, quote_literal(''));
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'categories'
      and column_name = 'image'
  ) then
    insert_columns := array_append(insert_columns, 'image');
    insert_values := array_append(insert_values, quote_literal(''));
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'categories'
      and column_name = 'ali_keywords'
  ) then
    insert_columns := array_append(insert_columns, 'ali_keywords');
    insert_values := array_append(insert_values, quote_literal('كتب, مكتبات, قرطاسية, لوازم مدرسية, books, stationery'));
  end if;

  execute format(
    'insert into public.categories (%s) values (%s)',
    array_to_string(insert_columns, ', '),
    array_to_string(insert_values, ', ')
  );
end $$;
