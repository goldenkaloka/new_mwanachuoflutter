# Mwanachuo Campus Marketplace - Clean Architecture Documentation

## Overview
This document outlines the clean architecture implementation for the Mwanachuo Campus Marketplace application.

## Architecture Layers

### 1. Presentation Layer (`lib/features/*/presentation/`)
- **BLoCs/Cubits**: State management logic
- **Pages**: Full-screen UI components
- **Widgets**: Reusable UI components

### 2. Domain Layer (`lib/features/*/domain/`)
- **Entities**: Core business models (pure Dart, no dependencies)
- **Use Cases**: Business logic operations
- **Repositories**: Abstract repository interfaces

### 3. Data Layer (`lib/features/*/data/`)
- **Models**: Data transfer objects (extends entities)
- **Data Sources**: Remote (Supabase) and Local (Hive/SharedPreferences)
- **Repositories**: Concrete repository implementations

### 4. Core Layer (`lib/core/`)
- **Errors**: Custom exceptions and failures
- **Network**: Network connectivity checks
- **DI**: Dependency injection setup
- **Constants**: App-wide constants
- **Utils**: Shared utilities
- **Widgets**: Shared UI components

## User Roles System

### Roles
1. **Buyer** (Default): Can browse and purchase
2. **Seller**: Can list products/services/accommodations
3. **Admin**: Can manage users and approve seller requests

### Role Flow
```
User Registration → Buyer (default)
                     ↓
           Request Seller Access → Admin Approval
                                      ↓
                                   Seller
```

## Supabase Integration

### Database Tables

#### 1. users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
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
```

#### 2. universities
```sql
CREATE TABLE universities (
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
```

#### 3. products
```sql
CREATE TABLE products (
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
```

#### 4. services
```sql
CREATE TABLE services (
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
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS (similar to products)
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
```

#### 5. accommodations
```sql
CREATE TABLE accommodations (
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
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS (similar to products)
ALTER TABLE accommodations ENABLE ROW LEVEL SECURITY;
```

#### 6. promotions
```sql
CREATE TABLE promotions (
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
```

#### 7. reviews
```sql
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  item_id UUID NOT NULL,
  item_type TEXT NOT NULL CHECK (item_type IN ('product', 'service', 'accommodation', 'promotion')),
  rating DECIMAL(2, 1) CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  helpful_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, item_id, item_type)
);

-- Enable RLS
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
```

#### 8. messages
```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
```

#### 9. conversations
```sql
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  participant_1_id UUID REFERENCES users(id) ON DELETE CASCADE,
  participant_2_id UUID REFERENCES users(id) ON DELETE CASCADE,
  last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(participant_1_id, participant_2_id)
);

-- Enable RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
```

#### 10. seller_requests
```sql
CREATE TABLE seller_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID REFERENCES users(id),
  review_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, status) -- Only one pending request per user
);

-- Enable RLS
ALTER TABLE seller_requests ENABLE ROW LEVEL SECURITY;
```

#### 11. notifications
```sql
CREATE TABLE notifications (
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
```

### Database Functions

#### 1. Handle New User (Trigger)
```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'name', ''), 'buyer');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

#### 2. Update Updated At Timestamp
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Repeat for other tables...
```

#### 3. Approve Seller Request (Function)
```sql
CREATE OR REPLACE FUNCTION approve_seller_request(request_id UUID, admin_id UUID, notes TEXT DEFAULT NULL)
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
  
  -- Update request status
  UPDATE seller_requests
  SET status = 'approved', reviewed_by = admin_id, review_notes = notes, updated_at = NOW()
  WHERE id = request_id;
  
  -- Update user role
  UPDATE users SET role = 'seller', updated_at = NOW() WHERE id = request_user_id;
  
  -- Create notification
  INSERT INTO notifications (user_id, type, title, message)
  VALUES (request_user_id, 'seller_request', 'Seller Request Approved', 'Congratulations! You are now a seller.');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Storage Buckets Setup

```javascript
// Run in Supabase SQL Editor or via Supabase Dashboard

// Create buckets
INSERT INTO storage.buckets (id, name, public) VALUES
  ('product-images', 'product-images', true),
  ('service-images', 'service-images', true),
  ('accommodation-images', 'accommodation-images', true),
  ('promotion-images', 'promotion-images', true),
  ('profile-images', 'profile-images', true);

// Storage Policies
CREATE POLICY "Anyone can view images" ON storage.objects
  FOR SELECT USING (bucket_id IN ('product-images', 'service-images', 'accommodation-images', 'promotion-images', 'profile-images'));

CREATE POLICY "Authenticated users can upload images" ON storage.objects
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update their own images" ON storage.objects
  FOR UPDATE USING (auth.uid()::text = owner);

CREATE POLICY "Users can delete their own images" ON storage.objects
  FOR DELETE USING (auth.uid()::text = owner);
```

## Feature Organization

Each feature follows this structure:
```
lib/features/<feature_name>/
├── data/
│   ├── datasources/
│   │   ├── <feature>_local_data_source.dart
│   │   └── <feature>_remote_data_source.dart
│   ├── models/
│   │   └── <feature>_model.dart
│   └── repositories/
│       └── <feature>_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── <feature>_entity.dart
│   ├── repositories/
│   │   └── <feature>_repository.dart
│   └── usecases/
│       ├── get_<feature>.dart
│       ├── create_<feature>.dart
│       ├── update_<feature>.dart
│       └── delete_<feature>.dart
└── presentation/
    ├── bloc/
    │   ├── <feature>_bloc.dart
    │   ├── <feature>_event.dart
    │   └── <feature>_state.dart
    ├── cubit/
    │   ├── <feature>_cubit.dart
    │   └── <feature>_state.dart
    ├── pages/
    │   └── <feature>_page.dart
    └── widgets/
        └── <feature>_widgets.dart
```

## Key Features

### Authentication
- Email/Password authentication via Supabase Auth
- Role-based access control (Buyer, Seller, Admin)
- Session persistence
- Auto-login on app start

### Products
- CRUD operations for products
- University-based filtering
- Image upload to Supabase Storage
- Real-time updates via Supabase Realtime

### Services
- Service listings management
- Provider verification
- Booking system

### Accommodations
- Property listings
- Landlord verification
- Visit scheduling

### Promotions
- Time-based promotions
- University-specific offers

### Messages
- Real-time chat via Supabase Realtime
- Conversation management
- Seller-buyer communication

### Reviews
- Product/Service/Accommodation reviews
- Rating system
- Helpful votes

## State Management

### BLoC Pattern
- Used for complex features (Auth, Products, Messages)
- Event-driven
- Testable

### Cubit Pattern
- Used for simpler features (Settings, Filters)
- State-driven
- Lightweight

## Data Flow

```
UI (Widgets) → BLoC/Cubit → Use Case → Repository → Data Source → Supabase
     ↑                                                                ↓
     └────────────────── State Updates ───────────────────────────────┘
```

## Error Handling

All errors are converted to `Failure` objects:
- `ServerFailure`: Supabase server errors
- `NetworkFailure`: No internet connection
- `CacheFailure`: Local storage errors
- `AuthenticationFailure`: Auth errors
- `ValidationFailure`: Input validation errors

## Testing Strategy

1. **Unit Tests**: Test use cases, repositories
2. **Widget Tests**: Test UI components
3. **BLoC Tests**: Test state management
4. **Integration Tests**: Test end-to-end flows

## Security

### Row Level Security (RLS)
- All tables have RLS enabled
- Users can only access their own data
- Role-based policies for sellers and admins

### ACID Compliance
- Supabase PostgreSQL ensures ACID properties
- Use transactions for critical operations
- Proper error handling and rollbacks

## Performance Optimization

1. **Database Indexing**
```sql
CREATE INDEX idx_products_university ON products(university_id);
CREATE INDEX idx_products_seller ON products(seller_id);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
```

2. **Caching Strategy**
- Use Hive for offline data
- Cache frequently accessed data
- Implement cache invalidation

3. **Pagination**
- Implement cursor-based pagination
- Limit query results

4. **Realtime Subscriptions**
- Subscribe only to relevant channels
- Unsubscribe when not needed

## Next Steps

1. ✅ Create folder structure
2. ✅ Add dependencies
3. ✅ Set up core layer
4. ⏳ Create domain entities
5. ⏳ Implement data sources
6. ⏳ Create repositories
7. ⏳ Implement BLoCs/Cubits
8. ⏳ Migrate existing UI
9. ⏳ Set up Supabase backend
10. ⏳ Implement authentication flow

