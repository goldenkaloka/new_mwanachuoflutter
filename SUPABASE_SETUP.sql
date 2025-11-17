-- Mwanachuo Campus Marketplace - Supabase Database Schema
-- Run this script in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. UNIVERSITIES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS universities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  logo_url TEXT,
  location TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE universities ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can view universities
CREATE POLICY "Anyone can view universities" ON universities
  FOR SELECT USING (true);

-- Insert sample universities
INSERT INTO universities (name, logo_url, location) VALUES
  ('University of Nairobi', 'https://lh3.googleusercontent.com/aida-public/AB6AXuDrJZvKSUBKbX014yoj27QHwYw1hGpHwLWDa-d66qvo5YqtQ3uzIsUSgs8__rUyQd7hkNqFatWlOGYhw1oK_ITNZ9e9RzI5VWhHjCkm0HqVSSgrtX7rC4HNuBrGqP7ERp6_h45AnDB7XqoPO1Ooof9K2i-oLIC2umUhAhLXDTY2PvukJohgpe90md0GRL4dggiLB1P3Gq9_U_gLuCwraNbdQmkhlC80WgiBXG0R2xQ7cVLnB6gb21JoO7LTtRd12rh2-1vS7hv2DoZl', 'Nairobi, Kenya'),
  ('Kenyatta University', 'https://lh3.googleusercontent.com/aida-public/AB6AXuCV7Lro8VWDLsE_FhWbicwxIUdLZ6n4gfjt3C_Uue-EaXXmLx6A09sMe_aMhoVMRxxiW6OgBlHmyv5Q9_RX2F46ItRSMcDE_vyG8yMm5zxCuu8-zqhlSY09o0G1DPeX4jYxGnmJrEOUZllXbVu_Ky0NMPtI59UrwmBKAqb5C3id-G7F4Xp3830wzLHukTVd0AmdWwyD73itd9rdpRdGxSiEEOrIPXH5h--Nd6FWn5rLaA6nqCuyaWhuQw5lzsm0yQbKQRs6xECGsEd0', 'Nairobi, Kenya'),
  ('Moi University', 'https://lh3.googleusercontent.com/aida-public/AB6AXuBCyUxOQfDD9KvUVUbj1VEtheY6mcUEC4SDCjXxfGm0iuTcGbwkHWM6EDS4Mr45BbuFA7YykSvsFQYzcE4tCZ16sFocRLe0O1XqP2Gd5P849z-FR7D7C3SWAaPUxe2VXkFgmXmtbblAl9hWNBec50NT1T0umO4sJpEvhBGFJmJe0HXP9ia7eRwWVyghMHROdlC2FlR7iChDj80DkxLj9dTHnQQp7YVBFXkZjeQMDVxaagwd6BTZEn4BrRscyUmp3OTGCAMuOoU4P7_r', 'Eldoret, Kenya')
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- 2. USERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'buyer' CHECK (role IN ('buyer', 'seller', 'admin')),
  university_id UUID REFERENCES universities(id),
  profile_picture TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own data" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON users
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================================
-- 3. PRODUCTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  seller_id UUID REFERENCES users(id) ON DELETE CASCADE,
  university_id UUID REFERENCES universities(id),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  category TEXT NOT NULL,
  condition TEXT NOT NULL,
  images TEXT[] DEFAULT '{}',
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'sold', 'inactive')),
  views INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Anyone can view active products" ON products
  FOR SELECT USING (status = 'active');

CREATE POLICY "Sellers can create products" ON products
  FOR INSERT WITH CHECK (
    auth.uid() = seller_id AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('seller', 'admin'))
  );

CREATE POLICY "Sellers can update their own products" ON products
  FOR UPDATE USING (auth.uid() = seller_id);

CREATE POLICY "Sellers can delete their own products" ON products
  FOR DELETE USING (auth.uid() = seller_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_products_university ON products(university_id);
CREATE INDEX IF NOT EXISTS idx_products_seller ON products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at DESC);

-- ============================================================================
-- 4. SERVICES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS services (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  provider_id UUID REFERENCES users(id) ON DELETE CASCADE,
  university_id UUID REFERENCES universities(id),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  price_per_hour DECIMAL(10, 2),
  images TEXT[] DEFAULT '{}',
  availability JSONB,
  contact_info TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  views INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE services ENABLE ROW LEVEL SECURITY;

-- Policies (similar to products)
CREATE POLICY "Anyone can view active services" ON services
  FOR SELECT USING (status = 'active');

CREATE POLICY "Sellers can create services" ON services
  FOR INSERT WITH CHECK (
    auth.uid() = provider_id AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('seller', 'admin'))
  );

CREATE POLICY "Providers can update their own services" ON services
  FOR UPDATE USING (auth.uid() = provider_id);

CREATE POLICY "Providers can delete their own services" ON services
  FOR DELETE USING (auth.uid() = provider_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_services_university ON services(university_id);
CREATE INDEX IF NOT EXISTS idx_services_provider ON services(provider_id);
CREATE INDEX IF NOT EXISTS idx_services_category ON services(category);

-- ============================================================================
-- 5. ACCOMMODATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS accommodations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
  university_id UUID REFERENCES universities(id),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  location TEXT NOT NULL,
  room_type TEXT NOT NULL,
  price_per_month DECIMAL(10, 2) NOT NULL,
  amenities TEXT[] DEFAULT '{}',
  images TEXT[] DEFAULT '{}',
  contact_info TEXT,
  status TEXT DEFAULT 'available' CHECK (status IN ('available', 'rented', 'inactive')),
  views INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE accommodations ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Anyone can view available accommodations" ON accommodations
  FOR SELECT USING (status IN ('available', 'rented'));

CREATE POLICY "Sellers can create accommodations" ON accommodations
  FOR INSERT WITH CHECK (
    auth.uid() = owner_id AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('seller', 'admin'))
  );

CREATE POLICY "Owners can update their own accommodations" ON accommodations
  FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Owners can delete their own accommodations" ON accommodations
  FOR DELETE USING (auth.uid() = owner_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_accommodations_university ON accommodations(university_id);
CREATE INDEX IF NOT EXISTS idx_accommodations_owner ON accommodations(owner_id);
CREATE INDEX IF NOT EXISTS idx_accommodations_room_type ON accommodations(room_type);

-- ============================================================================
-- 6. PROMOTIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS promotions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_by UUID REFERENCES users(id) ON DELETE CASCADE,
  university_id UUID REFERENCES universities(id),
  title TEXT NOT NULL,
  subtitle TEXT,
  description TEXT NOT NULL,
  banner_image TEXT,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  terms TEXT[],
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'inactive')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Anyone can view active promotions" ON promotions
  FOR SELECT USING (
    status = 'active' AND
    (start_date IS NULL OR start_date <= NOW()) AND
    (end_date IS NULL OR end_date >= NOW())
  );

CREATE POLICY "Sellers can create promotions" ON promotions
  FOR INSERT WITH CHECK (
    auth.uid() = created_by AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('seller', 'admin'))
  );

CREATE POLICY "Creators can update their own promotions" ON promotions
  FOR UPDATE USING (auth.uid() = created_by);

-- ============================================================================
-- 7. CONVERSATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  participant_1_id UUID REFERENCES users(id) ON DELETE CASCADE,
  participant_2_id UUID REFERENCES users(id) ON DELETE CASCADE,
  last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT unique_conversation UNIQUE(participant_1_id, participant_2_id)
);

-- Enable RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own conversations" ON conversations
  FOR SELECT USING (
    auth.uid() = participant_1_id OR auth.uid() = participant_2_id
  );

CREATE POLICY "Users can create conversations" ON conversations
  FOR INSERT WITH CHECK (
    auth.uid() = participant_1_id OR auth.uid() = participant_2_id
  );

-- Index
CREATE INDEX IF NOT EXISTS idx_conversations_participants ON conversations(participant_1_id, participant_2_id);

-- ============================================================================
-- 8. MESSAGES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view messages in their conversations" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE id = conversation_id AND
      (participant_1_id = auth.uid() OR participant_2_id = auth.uid())
    )
  );

CREATE POLICY "Users can send messages" ON messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update their own messages" ON messages
  FOR UPDATE USING (auth.uid() = sender_id);

-- Index
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at DESC);

-- ============================================================================
-- 9. REVIEWS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  item_id UUID NOT NULL,
  item_type TEXT NOT NULL CHECK (item_type IN ('product', 'service', 'accommodation', 'promotion')),
  rating DECIMAL(2, 1) CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  helpful_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT unique_review UNIQUE(user_id, item_id, item_type)
);

-- Enable RLS
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Anyone can view reviews" ON reviews
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create reviews" ON reviews
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reviews" ON reviews
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reviews" ON reviews
  FOR DELETE USING (auth.uid() = user_id);

-- Index
CREATE INDEX IF NOT EXISTS idx_reviews_item ON reviews(item_id, item_type);

-- ============================================================================
-- 10. NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- Index
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, created_at DESC);

-- ============================================================================
-- 11. SELLER REQUESTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS seller_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID REFERENCES users(id),
  review_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE seller_requests ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own requests" ON seller_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create seller requests" ON seller_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all requests" ON seller_requests
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can update requests" ON seller_requests
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function: Handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
    'buyer'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Create user record on auth signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to all tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_services_updated_at BEFORE UPDATE ON services
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_accommodations_updated_at BEFORE UPDATE ON accommodations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_promotions_updated_at BEFORE UPDATE ON promotions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_seller_requests_updated_at BEFORE UPDATE ON seller_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function: Approve seller request
CREATE OR REPLACE FUNCTION approve_seller_request(
  request_id UUID,
  admin_id UUID,
  notes TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  request_user_id UUID;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (SELECT 1 FROM users WHERE id = admin_id AND role = 'admin') THEN
    RAISE EXCEPTION 'Only admins can approve seller requests';
  END IF;
  
  -- Get user_id from request
  SELECT user_id INTO request_user_id FROM seller_requests WHERE id = request_id;
  
  IF request_user_id IS NULL THEN
    RAISE EXCEPTION 'Seller request not found';
  END IF;
  
  -- Update request status
  UPDATE seller_requests
  SET 
    status = 'approved',
    reviewed_by = admin_id,
    review_notes = notes,
    updated_at = NOW()
  WHERE id = request_id;
  
  -- Update user role
  UPDATE users SET role = 'seller', updated_at = NOW() WHERE id = request_user_id;
  
  -- Create notification
  INSERT INTO notifications (user_id, type, title, message)
  VALUES (
    request_user_id,
    'seller_request',
    'Seller Request Approved',
    'Congratulations! You are now a seller. You can start listing products, services, and accommodations.'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Update conversation last_message_at
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update conversation on new message
CREATE TRIGGER update_conversation_on_new_message
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION update_conversation_timestamp();

-- ============================================================================
-- STORAGE BUCKETS (Run in Supabase Dashboard or via API)
-- ============================================================================

-- Note: Create these buckets in Supabase Dashboard > Storage
-- Or run via Supabase Management API:
-- - product-images (public)
-- - service-images (public)
-- - accommodation-images (public)
-- - promotion-images (public)
-- - profile-images (public)

-- Storage policies (apply after creating buckets)
-- CREATE POLICY "Anyone can view images" ON storage.objects
--   FOR SELECT USING (bucket_id IN ('product-images', 'service-images', 'accommodation-images', 'promotion-images', 'profile-images'));

-- CREATE POLICY "Authenticated users can upload images" ON storage.objects
--   FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- CREATE POLICY "Users can update their own images" ON storage.objects
--   FOR UPDATE USING (auth.uid()::text = owner);

-- CREATE POLICY "Users can delete their own images" ON storage.objects
--   FOR DELETE USING (auth.uid()::text = owner);

