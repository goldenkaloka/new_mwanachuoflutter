# Feature Dependencies & Organization

## 🎯 Feature Classification Summary

**Total Features**: 13
- **Shared Features**: 5 (Reviews, Search, University, Notifications, Media)
- **Standalone Features**: 8 (Auth, Products, Services, Accommodations, Messages, Profile, Dashboard, Promotions, Settings, Home)

---

## 📊 Visual Dependency Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CORE LAYER                                  │
│  (Constants, DI, Errors, Network, Theme, Utils, Base Widgets)      │
└─────────────────────────────────────────────────────────────────────┘
                              ↑
                              │ (All features depend on Core)
                              │
┌─────────────────────────────────────────────────────────────────────┐
│                      SHARED FEATURES LAYER                          │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │  University  │  │    Media     │  │   Reviews    │            │
│  │  Selection   │  │   Upload     │  │  & Ratings   │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│         ↑                 ↑                  ↑                      │
│         │                 │                  │                      │
│  ┌──────────────┐  ┌──────────────┐                               │
│  │ Notifications│  │    Search    │◄─────────────────────┐        │
│  └──────────────┘  └──────────────┘                      │        │
│         ↑                 ↑                               │        │
└─────────┼─────────────────┼───────────────────────────────┼────────┘
          │                 │                               │
          │                 │                               │
┌─────────┼─────────────────┼───────────────────────────────┼────────┐
│         │    STANDALONE FEATURES LAYER                    │        │
│         │                 │                               │        │
│  ┌──────┴────────┐        │                               │        │
│  │     Auth      │        │                               │        │
│  │ (✅ Complete) │        │                               │        │
│  └───────────────┘        │                               │        │
│                           │                               │        │
│  ┌───────────────┐  ┌─────┴──────┐  ┌──────────────┐    │        │
│  │   Products    │──┤   Search    │──┤  Services    │────┘        │
│  │               │  └─────┬──────┘  │              │             │
│  │  • Reviews    │        │         │  • Reviews   │             │
│  │  • Media      │        │         │  • Media     │             │
│  │  • University │        │         │  • University│             │
│  └───────┬───────┘        │         └──────┬───────┘             │
│          │                │                │                      │
│  ┌───────┴──────────┐     │         ┌──────┴────────┐            │
│  │ Accommodations   │─────┘         │   Messages    │            │
│  │                  │               │               │            │
│  │  • Reviews       │               │ • Notifications│           │
│  │  • Media         │               └───────────────┘            │
│  │  • University    │                                             │
│  └──────────────────┘                                             │
│                                                                    │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐        │
│  │    Profile    │  │   Dashboard   │  │  Promotions   │        │
│  │               │  │               │  │               │        │
│  │  • Auth       │  │  • Products   │  │  • Products   │        │
│  │  • Media      │  │  • Services   │  └───────────────┘        │
│  └───────────────┘  │  • Accommod.  │                            │
│                     └───────────────┘                            │
│                                                                   │
│  ┌───────────────┐  ┌───────────────────────────────────────┐   │
│  │   Settings    │  │            Home                       │   │
│  │               │  │  (Aggregates data from all features)  │   │
│  │  • Auth       │  │                                       │   │
│  └───────────────┘  │  • Products  • Services  • Accommod.  │   │
│                     │  • Promotions • University            │   │
│                     └───────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Feature Dependency Matrix

| Feature         | Type       | Depends On (Shared)                   | Depends On (Standalone) |
|----------------|------------|---------------------------------------|-------------------------|
| Auth           | Standalone | -                                     | -                       |
| University     | Shared     | -                                     | -                       |
| Media          | Shared     | -                                     | -                       |
| Reviews        | Shared     | -                                     | -                       |
| Notifications  | Shared     | -                                     | -                       |
| Search         | Shared     | -                                     | Products, Services, Accommodations (for indexing) |
| Products       | Standalone | Reviews, Media, University            | -                       |
| Services       | Standalone | Reviews, Media, University            | -                       |
| Accommodations | Standalone | Reviews, Media, University            | -                       |
| Messages       | Standalone | Notifications                         | -                       |
| Profile        | Standalone | Media                                 | Auth                    |
| Dashboard      | Standalone | -                                     | Products, Services, Accommodations |
| Promotions     | Standalone | -                                     | Products                |
| Settings       | Standalone | -                                     | Auth                    |
| Home           | Standalone | University                            | Products, Services, Accommodations, Promotions |

---

## 📂 Actual Folder Structure After Reorganization

```
lib/
├── core/                                   # Infrastructure
│   ├── constants/
│   ├── di/
│   ├── enums/
│   ├── errors/
│   ├── network/
│   ├── theme/
│   ├── usecases/
│   ├── utils/
│   └── widgets/                           # Only pure UI widgets
│
├── config/
│   └── supabase_config.dart
│
└── features/
    │
    ├── shared/                            # ← NEW: Shared features
    │   ├── university/                    # Move from auth/presentation/pages
    │   │   ├── domain/
    │   │   │   ├── entities/
    │   │   │   │   └── university_entity.dart
    │   │   │   ├── repositories/
    │   │   │   │   └── university_repository.dart
    │   │   │   └── usecases/
    │   │   │       ├── get_universities.dart
    │   │   │       ├── get_selected_university.dart
    │   │   │       └── set_selected_university.dart
    │   │   ├── data/
    │   │   │   ├── models/
    │   │   │   │   └── university_model.dart
    │   │   │   ├── datasources/
    │   │   │   │   ├── university_remote_data_source.dart
    │   │   │   │   └── university_local_data_source.dart
    │   │   │   └── repositories/
    │   │   │       └── university_repository_impl.dart
    │   │   └── presentation/
    │   │       ├── cubit/
    │   │       │   ├── university_cubit.dart
    │   │       │   └── university_state.dart
    │   │       └── pages/
    │   │           └── university_selection_screen.dart
    │   │
    │   ├── media/                         # NEW: Centralized media handling
    │   │   ├── domain/
    │   │   ├── data/
    │   │   └── presentation/
    │   │
    │   ├── reviews/                       # Move from core/widgets
    │   │   ├── domain/
    │   │   ├── data/
    │   │   └── presentation/
    │   │       └── widgets/
    │   │           └── comments_and_ratings_section.dart
    │   │
    │   ├── search/                        # Move from features/search
    │   │   ├── domain/
    │   │   ├── data/
    │   │   └── presentation/
    │   │
    │   └── notifications/                 # Move from features/notifications
    │       ├── domain/
    │       ├── data/
    │       └── presentation/
    │
    ├── auth/                              # ✅ Complete
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │       ├── bloc/
    │       └── pages/
    │           ├── splash_screen.dart
    │           ├── onboarding_screen.dart
    │           ├── login_page.dart
    │           └── create_account_screen.dart
    │
    ├── products/                          # Rename from 'product'
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │       ├── bloc/
    │       └── pages/
    │           ├── all_products_page.dart
    │           ├── product_details_page.dart
    │           └── post_product_screen.dart
    │
    ├── services/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │       ├── bloc/
    │       └── pages/
    │           ├── services_screen.dart
    │           ├── service_detail_page.dart
    │           └── create_service_screen.dart
    │
    ├── accommodations/                    # Rename from 'accommodation'
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │       ├── bloc/
    │       └── pages/
    │           ├── student_housing_screen.dart
    │           ├── accommodation_detail_page.dart
    │           └── create_accommodation_screen.dart
    │
    ├── messages/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │       ├── bloc/
    │       └── pages/
    │           ├── messages_page.dart
    │           └── chat_screen.dart
    │
    ├── profile/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │       ├── cubit/
    │       └── pages/
    │           ├── profile_page.dart
    │           ├── edit_profile_screen.dart
    │           └── my_listings_screen.dart
    │
    ├── dashboard/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │       ├── cubit/
    │       └── pages/
    │           └── seller_dashboard_screen.dart
    │
    ├── promotions/                        # Rename from 'promotion'
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │       ├── cubit/
    │       └── pages/
    │           ├── promotion_detail_page.dart
    │           └── create_promotion_screen.dart
    │
    ├── settings/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │       ├── cubit/
    │       └── pages/
    │           └── account_settings_screen.dart
    │
    └── home/
        ├── domain/
        ├── data/
        └── presentation/
            ├── cubit/
            └── pages/
                └── home_page.dart
```

---

## 🚀 Implementation Order & Timeline

### Phase 1: Shared Features Foundation (Week 1)
**Goal**: Build shared infrastructure that all features will use

1. **University Feature** (6-8 hours)
   - Move from `auth/presentation/pages/`
   - Full Clean Architecture implementation
   - Update auth to import from shared

2. **Media Feature** (8-10 hours)
   - Create new shared feature
   - Image picker, upload, compression
   - Supabase Storage integration

3. **Reviews Feature** (10-12 hours)
   - Move from `core/widgets/`
   - Full Clean Architecture
   - Rating & review system

**Total**: ~24-30 hours

---

### Phase 2: Content Features (Week 2-3)
**Goal**: Core marketplace functionality

4. **Products Feature** (12-15 hours)
   - Uses: Reviews, Media, University
   - CRUD operations
   - Filtering, sorting

5. **Services Feature** (10-12 hours)
   - Uses: Reviews, Media, University
   - Service listings
   - Booking system

6. **Accommodations Feature** (10-12 hours)
   - Uses: Reviews, Media, University
   - Housing listings
   - Visit scheduling

**Total**: ~32-39 hours

---

### Phase 3: Discovery & Communication (Week 4)
**Goal**: Enable discovery and user interaction

7. **Search Feature** (10-12 hours)
   - Move from `features/search/`
   - Cross-content search
   - Advanced filtering

8. **Notifications Feature** (8-10 hours)
   - Move from `features/notifications/`
   - Push notifications
   - In-app notifications

9. **Messages Feature** (15-18 hours)
   - Uses: Notifications
   - Real-time chat
   - Conversation management

**Total**: ~33-40 hours

---

### Phase 4: User Experience (Week 5)
**Goal**: Complete user-facing features

10. **Profile Feature** (8-10 hours)
    - Uses: Auth, Media
    - User profiles
    - My listings

11. **Dashboard Feature** (10-12 hours)
    - Uses: Products, Services, Accommodations
    - Analytics
    - Seller tools

12. **Promotions Feature** (8-10 hours)
    - Uses: Products
    - Promotional campaigns

13. **Settings Feature** (6-8 hours)
    - Uses: Auth
    - App preferences

14. **Home Feature** (8-10 hours)
    - Uses: All content features
    - Aggregated view

**Total**: ~40-50 hours

---

## ⚡ Quick Start Action Plan

### Today (2-3 hours):
```bash
# 1. Create shared features structure
mkdir -p lib/features/shared/{university,media,reviews,search,notifications}

# 2. Move university selection
# Already in auth, will refactor to shared

# 3. Start with University feature (most critical)
# - Create domain layer
# - Create data layer  
# - Create presentation layer
# - Update auth to use it
```

### Tomorrow (Full Day):
- Complete Media feature (new)
- Start Reviews feature (move from core/widgets)

### Next 3 Days:
- Complete Reviews feature
- Complete Notifications feature (move from features)
- Complete Search feature (move from features)

### Following Week:
- Products → Services → Accommodations
- All use the shared features

---

## ✅ Key Benefits Summary

### 1. **Code Reusability**
- Write reviews system once, use in Products, Services, Accommodations
- Single media upload logic across all features
- Unified search across all content

### 2. **Consistent User Experience**
- Same review interface everywhere
- Consistent image upload process
- Unified search behavior

### 3. **Easier Maintenance**
- Fix bug in reviews? Fixed everywhere
- Update image compression? Applied globally
- Improve search? Benefits all content

### 4. **Better Testing**
- Test shared features thoroughly once
- Reduced test duplication
- Higher confidence in quality

### 5. **Team Collaboration**
- Clear boundaries between features
- Less merge conflicts
- Easier to parallelize work

### 6. **Scalability**
- Add new content type? Use existing shared features
- Add new university? Update once
- Add new notification type? Extend once

---

**Next Step**: Start creating the shared features infrastructure, beginning with University feature.


