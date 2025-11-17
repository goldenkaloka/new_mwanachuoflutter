-- ============================================
-- MWANACHUO MARKETPLACE - COMPLETE DATABASE SETUP
-- ============================================
-- Run this entire script in Supabase SQL Editor
-- Estimated time: 2-3 minutes
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLES
-- ============================================

-- Users table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone_number TEXT,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'buyer' CHECK (role IN ('buyer', 'seller', 'admin')),
  university_id UUID,
  bio TEXT,
  location TEXT,
  is_seller_approved BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE
);

-- Universities
CREATE TABLE IF NOT EXISTS public.universities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  location TEXT NOT NULL,
  logo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seller Requests
CREATE TABLE IF NOT EXISTS public.seller_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewed_by UUID REFERENCES public.users(id)
);

-- Products
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  price NUMERIC(10, 2) NOT NULL CHECK (price > 0),
  category TEXT NOT NULL,
  condition TEXT NOT NULL,
  images TEXT[] NOT NULL,
  seller_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  university_id UUID NOT NULL REFERENCES public.universities(id),
  location TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  view_count INT DEFAULT 0,
  rating NUMERIC(2, 1),
  review_count INT DEFAULT 0,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE
);

-- Services
CREATE TABLE IF NOT EXISTS public.services (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  price NUMERIC(10, 2) NOT NULL CHECK (price > 0),
  category TEXT NOT NULL,
  price_type TEXT NOT NULL DEFAULT 'fixed' CHECK (price_type IN ('hourly', 'fixed', 'per_session', 'per_day')),
  images TEXT[] NOT NULL,
  provider_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  university_id UUID NOT NULL REFERENCES public.universities(id),
  location TEXT NOT NULL,
  contact_phone TEXT NOT NULL,
  contact_email TEXT,
  availability TEXT[] NOT NULL,
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  view_count INT DEFAULT 0,
  rating NUMERIC(2, 1),
  review_count INT DEFAULT 0,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE
);

-- Accommodations
CREATE TABLE IF NOT EXISTS public.accommodations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price NUMERIC(10, 2) NOT NULL CHECK (price > 0),
  price_type TEXT NOT NULL DEFAULT 'per_month' CHECK (price_type IN ('per_month', 'per_semester', 'per_year')),
  room_type TEXT NOT NULL,
  images TEXT[] NOT NULL,
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  university_id UUID NOT NULL REFERENCES public.universities(id),
  location TEXT NOT NULL,
  contact_phone TEXT NOT NULL,
  contact_email TEXT,
  amenities TEXT[] NOT NULL,
  bedrooms INT NOT NULL,
  bathrooms INT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  view_count INT DEFAULT 0,
  rating NUMERIC(2, 1),
  review_count INT DEFAULT 0,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE
);

-- Product Reviews
CREATE TABLE IF NOT EXISTS public.product_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  item_type TEXT NOT NULL DEFAULT 'product',
  rating NUMERIC(2, 1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  images TEXT[],
  helpful_count INT DEFAULT 0,
  is_verified_purchase BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user_id, item_id)
);

-- Service Reviews
CREATE TABLE IF NOT EXISTS public.service_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  item_type TEXT NOT NULL DEFAULT 'service',
  rating NUMERIC(2, 1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  images TEXT[],
  helpful_count INT DEFAULT 0,
  is_verified_purchase BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user_id, item_id)
);

-- Accommodation Reviews
CREATE TABLE IF NOT EXISTS public.accommodation_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES public.accommodations(id) ON DELETE CASCADE,
  item_type TEXT NOT NULL DEFAULT 'accommodation',
  rating NUMERIC(2, 1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  images TEXT[],
  helpful_count INT DEFAULT 0,
  is_verified_purchase BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user_id, item_id)
);

-- Conversations
CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user1_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user1_name TEXT NOT NULL,
  user2_name TEXT NOT NULL,
  user1_avatar TEXT,
  user2_avatar TEXT,
  last_message TEXT,
  last_message_time TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user1_id, user2_id)
);

-- Messages
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_url TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE
);

-- Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  action_url TEXT,
  image_url TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE
);

-- Promotions
CREATE TABLE IF NOT EXISTS public.promotions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  subtitle TEXT NOT NULL,
  description TEXT NOT NULL,
  image_url TEXT,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  target_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_users_university ON public.users(university_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_products_seller ON public.products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_university ON public.products(university_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_active ON public.products(is_active);
CREATE INDEX IF NOT EXISTS idx_services_provider ON public.services(provider_id);
CREATE INDEX IF NOT EXISTS idx_services_university ON public.services(university_id);
CREATE INDEX IF NOT EXISTS idx_accommodations_owner ON public.accommodations(owner_id);
CREATE INDEX IF NOT EXISTS idx_accommodations_university ON public.accommodations(university_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id, is_read) WHERE is_read = false;

-- ============================================
-- FUNCTIONS
-- ============================================

CREATE OR REPLACE FUNCTION increment_product_views(product_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.products SET view_count = view_count + 1 WHERE id = product_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_service_views(service_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.services SET view_count = view_count + 1 WHERE id = service_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_accommodation_views(accommodation_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.accommodations SET view_count = view_count + 1 WHERE id = accommodation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGERS
-- ============================================

CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.products
  SET 
    rating = (SELECT AVG(rating) FROM public.product_reviews WHERE item_id = COALESCE(NEW.item_id, OLD.item_id)),
    review_count = (SELECT COUNT(*) FROM public.product_reviews WHERE item_id = COALESCE(NEW.item_id, OLD.item_id))
  WHERE id = COALESCE(NEW.item_id, OLD.item_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_product_rating ON public.product_reviews;
CREATE TRIGGER trigger_update_product_rating
AFTER INSERT OR UPDATE OR DELETE ON public.product_reviews
FOR EACH ROW EXECUTE FUNCTION update_product_rating();

CREATE OR REPLACE FUNCTION update_service_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.services
  SET 
    rating = (SELECT AVG(rating) FROM public.service_reviews WHERE item_id = COALESCE(NEW.item_id, OLD.item_id)),
    review_count = (SELECT COUNT(*) FROM public.service_reviews WHERE item_id = COALESCE(NEW.item_id, OLD.item_id))
  WHERE id = COALESCE(NEW.item_id, OLD.item_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_service_rating ON public.service_reviews;
CREATE TRIGGER trigger_update_service_rating
AFTER INSERT OR UPDATE OR DELETE ON public.service_reviews
FOR EACH ROW EXECUTE FUNCTION update_service_rating();

CREATE OR REPLACE FUNCTION update_accommodation_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.accommodations
  SET 
    rating = (SELECT AVG(rating) FROM public.accommodation_reviews WHERE item_id = COALESCE(NEW.item_id, OLD.item_id)),
    review_count = (SELECT COUNT(*) FROM public.accommodation_reviews WHERE item_id = COALESCE(NEW.item_id, OLD.item_id))
  WHERE id = COALESCE(NEW.item_id, OLD.item_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_accommodation_rating ON public.accommodation_reviews;
CREATE TRIGGER trigger_update_accommodation_rating
AFTER INSERT OR UPDATE OR DELETE ON public.accommodation_reviews
FOR EACH ROW EXECUTE FUNCTION update_accommodation_rating();

-- ============================================
-- ENABLE RLS
-- ============================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seller_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accommodations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accommodation_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================

-- Users policies
CREATE POLICY "Users viewable by everyone" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- Products policies
CREATE POLICY "Active products viewable" ON public.products FOR SELECT USING (is_active = true OR auth.uid() = seller_id);
CREATE POLICY "Sellers insert products" ON public.products FOR INSERT WITH CHECK (auth.uid() = seller_id);
CREATE POLICY "Sellers update own products" ON public.products FOR UPDATE USING (auth.uid() = seller_id);
CREATE POLICY "Sellers delete own products" ON public.products FOR DELETE USING (auth.uid() = seller_id);

-- Services policies
CREATE POLICY "Active services viewable" ON public.services FOR SELECT USING (is_active = true OR auth.uid() = provider_id);
CREATE POLICY "Providers insert services" ON public.services FOR INSERT WITH CHECK (auth.uid() = provider_id);
CREATE POLICY "Providers update own services" ON public.services FOR UPDATE USING (auth.uid() = provider_id);
CREATE POLICY "Providers delete own services" ON public.services FOR DELETE USING (auth.uid() = provider_id);

-- Accommodations policies
CREATE POLICY "Active accommodations viewable" ON public.accommodations FOR SELECT USING (is_active = true OR auth.uid() = owner_id);
CREATE POLICY "Owners insert accommodations" ON public.accommodations FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Owners update own accommodations" ON public.accommodations FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Owners delete own accommodations" ON public.accommodations FOR DELETE USING (auth.uid() = owner_id);

-- Reviews policies (all three tables)
CREATE POLICY "Reviews viewable by all" ON public.product_reviews FOR SELECT USING (true);
CREATE POLICY "Reviews viewable by all" ON public.service_reviews FOR SELECT USING (true);
CREATE POLICY "Reviews viewable by all" ON public.accommodation_reviews FOR SELECT USING (true);
CREATE POLICY "Users insert own reviews" ON public.product_reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users insert own reviews" ON public.service_reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users insert own reviews" ON public.accommodation_reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own reviews" ON public.product_reviews FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users update own reviews" ON public.service_reviews FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users update own reviews" ON public.accommodation_reviews FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users delete own reviews" ON public.product_reviews FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Users delete own reviews" ON public.service_reviews FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Users delete own reviews" ON public.accommodation_reviews FOR DELETE USING (auth.uid() = user_id);

-- Conversations policies
CREATE POLICY "Users view own conversations" ON public.conversations FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "Users create conversations" ON public.conversations FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Messages policies
CREATE POLICY "Users view conversation messages" ON public.messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.conversations WHERE id = conversation_id AND (user1_id = auth.uid() OR user2_id = auth.uid()))
);
CREATE POLICY "Users send messages" ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Users update own messages" ON public.messages FOR UPDATE USING (auth.uid() = sender_id);

-- Notifications policies
CREATE POLICY "Users view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System insert notifications" ON public.notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Users update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users delete own notifications" ON public.notifications FOR DELETE USING (auth.uid() = user_id);

-- Promotions policies
CREATE POLICY "Active promotions viewable" ON public.promotions FOR SELECT USING (is_active = true);

-- ============================================
-- ENABLE REALTIME
-- ============================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- ============================================
-- SAMPLE DATA
-- ============================================

-- Insert sample universities
INSERT INTO public.universities (name, location) VALUES
  ('University of Nairobi', 'Nairobi'),
  ('Kenyatta University', 'Nairobi'),
  ('Strathmore University', 'Nairobi'),
  ('USIU-Africa', 'Nairobi'),
  ('Moi University', 'Eldoret'),
  ('Egerton University', 'Njoro'),
  ('JKUAT', 'Juja'),
  ('Maseno University', 'Maseno'),
  ('Technical University of Kenya', 'Nairobi'),
  ('Daystar University', 'Nairobi')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- SETUP COMPLETE!
-- ============================================
-- Next steps:
-- 1. Go to Storage and create 5 buckets:
--    - product-images
--    - service-images  
--    - accommodation-images
--    - profile-images
--    - promotion-images
-- 2. Make all buckets PUBLIC
-- 3. Update your .env file with Supabase URL and anon key
-- 4. Run: flutter run
-- ============================================

