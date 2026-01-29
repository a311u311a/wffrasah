-- ===============================================
-- جدول المفضلة (Favorites)
-- ===============================================
-- هذا الجدول يحفظ العناصر المفضلة للمستخدمين
-- يدعم الكوبونات (coupons) والعروض (offers)

CREATE TABLE IF NOT EXISTS favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  item_id TEXT NOT NULL,
  item_type TEXT NOT NULL, -- 'coupon' أو 'offer'
  item_data JSONB NOT NULL, -- بيانات الكوبون/العرض الكاملة
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- منع تكرار نفس العنصر لنفس المستخدم
  UNIQUE(user_id, item_id)
);

-- ===============================================
-- Indexes لتحسين الأداء
-- ===============================================
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_item_id ON favorites(item_id);
CREATE INDEX IF NOT EXISTS idx_favorites_created_at ON favorites(created_at DESC);

-- ===============================================
-- Row Level Security (RLS)
-- ===============================================
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

-- Policy: المستخدم يمكنه قراءة مفضلته فقط
DROP POLICY IF EXISTS "Users can view their own favorites" ON favorites;
CREATE POLICY "Users can view their own favorites"
  ON favorites FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: المستخدم يمكنه إضافة لمفضلته
DROP POLICY IF EXISTS "Users can insert their own favorites" ON favorites;
CREATE POLICY "Users can insert their own favorites"
  ON favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: المستخدم يمكنه حذف من مفضلته
DROP POLICY IF EXISTS "Users can delete their own favorites" ON favorites;
CREATE POLICY "Users can delete their own favorites"
  ON favorites FOR DELETE
  USING (auth.uid() = user_id);

-- Policy: المستخدم يمكنه تحديث مفضلته (إذا لزم الأمر)
DROP POLICY IF EXISTS "Users can update their own favorites" ON favorites;
CREATE POLICY "Users can update their own favorites"
  ON favorites FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
