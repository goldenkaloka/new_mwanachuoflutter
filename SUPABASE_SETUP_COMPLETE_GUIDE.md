# 🗄️ Complete Supabase Setup Guide

## Overview

This guide will set up your complete Supabase database for the Mwanachuo marketplace app.

**What You'll Create**:
- 10 database tables
- 5 storage buckets
- RLS (Row Level Security) policies
- Database functions
- Triggers for auto-updates

**Estimated Time**: 30-45 minutes

---

## 📋 Pre-requisites

1. ✅ Supabase account created
2. ✅ New project created
3. ✅ Project URL and anon key ready
4. ✅ Update `.env` file with credentials

---

## Step 1: Create Tables

### Run this in Supabase SQL Editor:

```sql
-- ============================================
-- USERS TABLE (Extended from auth.users)
-- ============================================
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

-- ============================================
-- UNIVERSITIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.universities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  location TEXT NOT NULL,
  logo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- SELLER REQUESTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.seller_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewed_by UUID REFERENCES public.users(id)
);

-- ============================================
-- PRODUCTS TABLE
-- ============================================
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

-- ============================================
-- SERVICES TABLE
-- ============================================
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

-- ============================================
-- ACCOMMODATIONS TABLE
-- ============================================
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

-- ============================================
-- REVIEWS TABLES
-- ============================================
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

-- ============================================
-- MESSAGES & CONVERSATIONS
-- ============================================
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

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================
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

-- ============================================
-- PROMOTIONS TABLE
-- ============================================
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
```

---

## Step 2: Create Indexes

```sql
-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_university ON public.users(university_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- Products indexes
CREATE INDEX IF NOT EXISTS idx_products_seller ON public.products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_university ON public.products(university_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_active ON public.products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_featured ON public.products(is_featured);
CREATE INDEX IF NOT EXISTS idx_products_search ON public.products USING gin(to_tsvector('english', title || ' ' || description));

-- Services indexes
CREATE INDEX IF NOT EXISTS idx_services_provider ON public.services(provider_id);
CREATE INDEX IF NOT EXISTS idx_services_university ON public.services(university_id);
CREATE INDEX IF NOT EXISTS idx_services_category ON public.services(category);
CREATE INDEX IF NOT EXISTS idx_services_active ON public.services(is_active);

-- Accommodations indexes
CREATE INDEX IF NOT EXISTS idx_accommodations_owner ON public.accommodations(owner_id);
CREATE INDEX IF NOT EXISTS idx_accommodations_university ON public.accommodations(university_id);
CREATE INDEX IF NOT EXISTS idx_accommodations_active ON public.accommodations(is_active);

-- Reviews indexes
CREATE INDEX IF NOT EXISTS idx_product_reviews_item ON public.product_reviews(item_id);
CREATE INDEX IF NOT EXISTS idx_service_reviews_item ON public.service_reviews(item_id);
CREATE INDEX IF NOT EXISTS idx_accommodation_reviews_item ON public.accommodation_reviews(item_id);

-- Messages indexes
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_conversations_users ON public.conversations(user1_id, user2_id);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id, is_read) WHERE is_read = false;

-- Promotions indexes
CREATE INDEX IF NOT EXISTS idx_promotions_active ON public.promotions(is_active, start_date, end_date);
```

---

## Step 3: Create Functions

```sql
-- Function to increment product views
CREATE OR REPLACE FUNCTION increment_product_views(product_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.products 
  SET view_count = view_count + 1 
  WHERE id = product_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment service views
CREATE OR REPLACE FUNCTION increment_service_views(service_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.services 
  SET view_count = view_count + 1 
  WHERE id = service_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment accommodation views
CREATE OR REPLACE FUNCTION increment_accommodation_views(accommodation_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.accommodations 
  SET view_count = view_count + 1 
  WHERE id = accommodation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment review helpful count
CREATE OR REPLACE FUNCTION increment_helpful_count(review_id UUID, table_name TEXT)
RETURNS VOID AS $$
BEGIN
  EXECUTE format('UPDATE %I SET helpful_count = helpful_count + 1 WHERE id = $1', table_name)
  USING review_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Step 4: Create Triggers

```sql
-- Trigger to update product rating when reviews change
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

CREATE TRIGGER trigger_update_product_rating
AFTER INSERT OR UPDATE OR DELETE ON public.product_reviews
FOR EACH ROW
EXECUTE FUNCTION update_product_rating();

-- Trigger to update service rating
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

CREATE TRIGGER trigger_update_service_rating
AFTER INSERT OR UPDATE OR DELETE ON public.service_reviews
FOR EACH ROW
EXECUTE FUNCTION update_service_rating();

-- Trigger to update accommodation rating
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

CREATE TRIGGER trigger_update_accommodation_rating
AFTER INSERT OR UPDATE OR DELETE ON public.accommodation_reviews
FOR EACH ROW
EXECUTE FUNCTION update_accommodation_rating();
```

---

## Step 5: Enable Row Level Security (RLS)

```sql
-- Enable RLS on all tables
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
```

---

## Step 6: Create RLS Policies

```sql
-- ============================================
-- USERS POLICIES
-- ============================================
CREATE POLICY "Users can view all users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- ============================================
-- PRODUCTS POLICIES
-- ============================================
CREATE POLICY "Active products viewable by everyone" ON public.products 
  FOR SELECT USING (is_active = true);

CREATE POLICY "Sellers can view own products" ON public.products 
  FOR SELECT USING (auth.uid() = seller_id);

CREATE POLICY "Sellers can insert products" ON public.products 
  FOR INSERT WITH CHECK (auth.uid() = seller_id);

CREATE POLICY "Sellers can update own products" ON public.products 
  FOR UPDATE USING (auth.uid() = seller_id);

CREATE POLICY "Sellers can delete own products" ON public.products 
  FOR DELETE USING (auth.uid() = seller_id);

-- ============================================
-- SERVICES POLICIES
-- ============================================
CREATE POLICY "Active services viewable by everyone" ON public.services 
  FOR SELECT USING (is_active = true);

CREATE POLICY "Providers can view own services" ON public.services 
  FOR SELECT USING (auth.uid() = provider_id);

CREATE POLICY "Providers can insert services" ON public.services 
  FOR INSERT WITH CHECK (auth.uid() = provider_id);

CREATE POLICY "Providers can update own services" ON public.services 
  FOR UPDATE USING (auth.uid() = provider_id);

CREATE POLICY "Providers can delete own services" ON public.services 
  FOR DELETE USING (auth.uid() = provider_id);

-- ============================================
-- ACCOMMODATIONS POLICIES
-- ============================================
CREATE POLICY "Active accommodations viewable by everyone" ON public.accommodations 
  FOR SELECT USING (is_active = true);

CREATE POLICY "Owners can view own accommodations" ON public.accommodations 
  FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "Owners can insert accommodations" ON public.accommodations 
  FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update own accommodations" ON public.accommodations 
  FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Owners can delete own accommodations" ON public.accommodations 
  FOR DELETE USING (auth.uid() = owner_id);

-- ============================================
-- REVIEWS POLICIES
-- ============================================
CREATE POLICY "Reviews viewable by everyone" ON public.product_reviews FOR SELECT USING (true);
CREATE POLICY "Reviews viewable by everyone" ON public.service_reviews FOR SELECT USING (true);
CREATE POLICY "Reviews viewable by everyone" ON public.accommodation_reviews FOR SELECT USING (true);

CREATE POLICY "Users can insert own reviews" ON public.product_reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can insert own reviews" ON public.service_reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can insert own reviews" ON public.accommodation_reviews FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reviews" ON public.product_reviews FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can update own reviews" ON public.service_reviews FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can update own reviews" ON public.accommodation_reviews FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own reviews" ON public.product_reviews FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own reviews" ON public.service_reviews FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own reviews" ON public.accommodation_reviews FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- MESSAGES POLICIES
-- ============================================
CREATE POLICY "Users can view own conversations" ON public.conversations 
  FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can create conversations" ON public.conversations 
  FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can view own messages" ON public.messages 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.conversations 
      WHERE id = conversation_id 
      AND (user1_id = auth.uid() OR user2_id = auth.uid())
    )
  );

CREATE POLICY "Users can send messages" ON public.messages 
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update own messages" ON public.messages 
  FOR UPDATE USING (auth.uid() = sender_id);

-- ============================================
-- NOTIFICATIONS POLICIES
-- ============================================
CREATE POLICY "Users can view own notifications" ON public.notifications 
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications" ON public.notifications 
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update own notifications" ON public.notifications 
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications" ON public.notifications 
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- PROMOTIONS POLICIES
-- ============================================
CREATE POLICY "Everyone can view active promotions" ON public.promotions 
  FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage promotions" ON public.promotions 
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

## Step 7: Enable Realtime

```sql
-- Enable Realtime for messages and notifications
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
```

---

## Step 8: Insert Sample Universities

```sql
-- Insert some sample universities
INSERT INTO public.universities (name, location) VALUES
  ('University of Nairobi', 'Nairobi'),
  ('Kenyatta University', 'Nairobi'),
  ('Strathmore University', 'Nairobi'),
  ('USIU-Africa', 'Nairobi'),
  ('Moi University', 'Eldoret'),
  ('Egerton University', 'Njoro'),
  ('JKUAT', 'Juja'),
  ('Maseno University', 'Maseno')
ON CONFLICT (name) DO NOTHING;
```

---

## Step 9: Create Storage Buckets

### Go to Supabase Dashboard → Storage → Create New Bucket

Create these buckets (all **PUBLIC**):

1. ✅ `product-images`
2. ✅ `service-images`
3. ✅ `accommodation-images`
4. ✅ `profile-images`
5. ✅ `promotion-images`

### For each bucket, set these policies:

```sql
-- Allow authenticated users to upload
CREATE POLICY "Allow authenticated uploads" ON storage.objects 
  FOR INSERT TO authenticated 
  WITH CHECK (bucket_id = 'product-images');

-- Allow public to view
CREATE POLICY "Allow public downloads" ON storage.objects 
  FOR SELECT TO public 
  USING (bucket_id = 'product-images');

-- Allow users to delete their own files
CREATE POLICY "Allow users to delete own files" ON storage.objects 
  FOR DELETE TO authenticated 
  USING (bucket_id = 'product-images' AND auth.uid()::text = (storage.foldername(name))[1]);
```

**Repeat for each bucket** (replace 'product-images' with other bucket names)

---

## Step 10: Update Environment Variables

Create `.env` file in project root:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

Update `lib/config/supabase_config.dart` to use these values.

---

## ✅ Verification Checklist

After running all scripts:

- [ ] 10 tables created
- [ ] All indexes created
- [ ] All functions created
- [ ] All triggers created
- [ ] RLS enabled on all tables
- [ ] All RLS policies created
- [ ] Realtime enabled for messages & notifications
- [ ] 5 storage buckets created
- [ ] Storage policies configured
- [ ] Sample universities inserted
- [ ] Environment variables set

---

## 🚀 Quick Start Script

**Run this complete script in Supabase SQL Editor**:

(See `SUPABASE_COMPLETE_SETUP.sql` file)

---

## 🎯 Next Steps After Setup

1. ✅ Run Flutter app: `flutter run`
2. ✅ Test authentication
3. ✅ Test university selection
4. ✅ Test creating products/services
5. ✅ Test image uploads
6. ✅ Test messaging
7. ✅ Test notifications

---

**Total Setup Time**: 30-45 minutes

**After Setup**: Fully working marketplace app! 🎉

