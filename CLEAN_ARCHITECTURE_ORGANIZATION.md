# Clean Architecture Organization Strategy

## 📁 Feature Classification

### Standalone Features (Feature-Specific)
Features that are self-contained and don't need to be accessed by other features.

### Shared Features (Cross-Cutting)
Features that are used across multiple other features and should be accessible everywhere.

---

## 🎯 Your Project Structure

### ✅ STANDALONE FEATURES

These are independent, domain-specific features:

#### 1. **Auth** (Already Implemented)
**Location**: `lib/features/auth/`
**Reason**: Self-contained authentication flow
**Used By**: Only the app initialization
**Dependencies**: None from other features

#### 2. **Products**
**Location**: `lib/features/products/` (rename from `product`)
**Reason**: Core marketplace domain
**Used By**: Home (displays products), Search (searches products)
**Dependencies**: Reviews (shared), University (shared)

#### 3. **Services**
**Location**: `lib/features/services/`
**Reason**: Distinct domain (service marketplace)
**Used By**: Home (displays services)
**Dependencies**: Reviews (shared), University (shared)

#### 4. **Accommodations**
**Location**: `lib/features/accommodations/` (rename from `accommodation`)
**Reason**: Distinct domain (housing marketplace)
**Used By**: Home (displays accommodations)
**Dependencies**: Reviews (shared), University (shared)

#### 5. **Messages**
**Location**: `lib/features/messages/`
**Reason**: Communication feature
**Used By**: Products, Services, Accommodations (contact seller)
**Dependencies**: Notifications (shared)

#### 6. **Profile**
**Location**: `lib/features/profile/`
**Reason**: User-specific feature
**Used By**: Navigation, Settings
**Dependencies**: Auth (for user data)

#### 7. **Dashboard**
**Location**: `lib/features/dashboard/`
**Reason**: Seller-specific analytics
**Used By**: Seller users only
**Dependencies**: Products, Services, Accommodations (for stats)

#### 8. **Promotions**
**Location**: `lib/features/promotions/` (rename from `promotion`)
**Reason**: Marketing feature
**Used By**: Home (displays promotions)
**Dependencies**: Products (links to products)

#### 9. **Settings**
**Location**: `lib/features/settings/`
**Reason**: App configuration
**Used By**: Profile, Navigation
**Dependencies**: Auth (for account settings)

#### 10. **Home**
**Location**: `lib/features/home/`
**Reason**: Main entry point/aggregator
**Used By**: Navigation
**Dependencies**: Products, Services, Accommodations, Promotions, University (all for display)

---

### 🔄 SHARED FEATURES

These features are used across multiple domains and should be accessible to all:

#### 1. **Reviews & Ratings** ⭐ CRITICAL
**Current**: `lib/core/widgets/comments_and_ratings_section.dart`
**Move To**: `lib/features/shared/reviews/`

**Reason**: Used by Products, Services, Accommodations
**Structure**:
```
lib/features/shared/reviews/
├── domain/
│   ├── entities/
│   │   ├── review_entity.dart
│   │   └── rating_entity.dart
│   ├── repositories/
│   │   └── review_repository.dart
│   └── usecases/
│       ├── get_reviews.dart
│       ├── create_review.dart
│       ├── update_review.dart
│       ├── delete_review.dart
│       └── get_average_rating.dart
├── data/
│   ├── models/
│   │   ├── review_model.dart
│   │   └── rating_model.dart
│   ├── datasources/
│   │   ├── review_remote_data_source.dart
│   │   └── review_local_data_source.dart
│   └── repositories/
│       └── review_repository_impl.dart
└── presentation/
    ├── cubit/
    │   ├── review_cubit.dart
    │   └── review_state.dart
    └── widgets/
        ├── review_list.dart
        ├── review_item.dart
        ├── rating_display.dart
        ├── rating_input.dart
        └── review_form.dart
```

#### 2. **Search** 🔍 CRITICAL
**Current**: `lib/features/search/`
**Move To**: `lib/features/shared/search/`

**Reason**: Searches across Products, Services, Accommodations
**Structure**:
```
lib/features/shared/search/
├── domain/
│   ├── entities/
│   │   ├── search_result_entity.dart
│   │   └── search_filter_entity.dart
│   ├── repositories/
│   │   └── search_repository.dart
│   └── usecases/
│       ├── search_all.dart
│       ├── search_products.dart
│       ├── search_services.dart
│       ├── search_accommodations.dart
│       └── apply_filters.dart
├── data/
│   ├── models/
│   │   ├── search_result_model.dart
│   │   └── search_filter_model.dart
│   ├── datasources/
│   │   └── search_remote_data_source.dart
│   └── repositories/
│       └── search_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── search_bloc.dart
    │   ├── search_event.dart
    │   └── search_state.dart
    └── pages/
        └── search_results_page.dart
```

#### 3. **University** 🏫 CRITICAL
**Current**: `lib/features/auth/presentation/pages/university_selection_screen.dart`
**Move To**: `lib/features/shared/university/`

**Reason**: Used in onboarding AND filtering throughout the app
**Structure**:
```
lib/features/shared/university/
├── domain/
│   ├── entities/
│   │   └── university_entity.dart
│   ├── repositories/
│   │   └── university_repository.dart
│   └── usecases/
│       ├── get_universities.dart
│       ├── get_selected_university.dart
│       ├── set_selected_university.dart
│       └── filter_by_university.dart
├── data/
│   ├── models/
│   │   └── university_model.dart
│   ├── datasources/
│   │   ├── university_remote_data_source.dart
│   │   └── university_local_data_source.dart
│   └── repositories/
│       └── university_repository_impl.dart
└── presentation/
    ├── cubit/
    │   ├── university_cubit.dart
    │   └── university_state.dart
    └── pages/
        └── university_selection_screen.dart
```

#### 4. **Notifications** 🔔
**Current**: `lib/features/notifications/`
**Move To**: `lib/features/shared/notifications/`

**Reason**: Notifications triggered by Products, Services, Accommodations, Messages, etc.
**Structure**:
```
lib/features/shared/notifications/
├── domain/
│   ├── entities/
│   │   └── notification_entity.dart
│   ├── repositories/
│   │   └── notification_repository.dart
│   └── usecases/
│       ├── get_notifications.dart
│       ├── mark_as_read.dart
│       ├── send_notification.dart
│       └── delete_notification.dart
├── data/
│   ├── models/
│   │   └── notification_model.dart
│   ├── datasources/
│   │   ├── notification_remote_data_source.dart
│   │   └── notification_local_data_source.dart
│   └── repositories/
│       └── notification_repository_impl.dart
└── presentation/
    ├── cubit/
    │   ├── notification_cubit.dart
    │   └── notification_state.dart
    └── pages/
        └── notifications_page.dart
```

#### 5. **Media** 📷
**New Feature** (Currently scattered)
**Create**: `lib/features/shared/media/`

**Reason**: Image upload/management used by Products, Services, Accommodations, Profile
**Structure**:
```
lib/features/shared/media/
├── domain/
│   ├── entities/
│   │   └── media_entity.dart
│   ├── repositories/
│   │   └── media_repository.dart
│   └── usecases/
│       ├── upload_image.dart
│       ├── delete_image.dart
│       ├── compress_image.dart
│       └── pick_image.dart
├── data/
│   ├── models/
│   │   └── media_model.dart
│   ├── datasources/
│   │   ├── media_remote_data_source.dart (Supabase Storage)
│   │   └── media_local_data_source.dart (Cache)
│   └── repositories/
│       └── media_repository_impl.dart
└── presentation/
    ├── cubit/
    │   ├── media_cubit.dart
    │   └── media_state.dart
    └── widgets/
        ├── image_picker_widget.dart
        ├── image_preview.dart
        └── image_uploader.dart
```

---

## 📂 Complete Recommended Structure

```
lib/
├── core/                           # Core/Infrastructure Layer
│   ├── constants/                  # App-wide constants
│   │   ├── app_constants.dart
│   │   ├── database_constants.dart
│   │   └── storage_constants.dart
│   ├── di/                        # Dependency Injection
│   │   └── injection_container.dart
│   ├── enums/                     # App-wide enums
│   │   └── user_role.dart
│   ├── errors/                    # Error handling
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/                   # Network utilities
│   │   └── network_info.dart
│   ├── theme/                     # App theming
│   │   └── app_theme.dart
│   ├── usecases/                  # Base use case
│   │   └── usecase.dart
│   ├── utils/                     # Utilities
│   │   ├── responsive.dart
│   │   └── validators.dart
│   └── widgets/                   # Reusable widgets (UI only, no business logic)
│       ├── network_image_with_fallback.dart
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       └── loading_indicator.dart
│
├── config/                        # App configuration
│   └── supabase_config.dart
│
├── features/
│   ├── shared/                    # SHARED FEATURES (Cross-cutting)
│   │   ├── reviews/              # Reviews & Ratings (used by Products, Services, Accommodations)
│   │   │   ├── domain/
│   │   │   ├── data/
│   │   │   └── presentation/
│   │   ├── search/               # Search (across all content)
│   │   │   ├── domain/
│   │   │   ├── data/
│   │   │   └── presentation/
│   │   ├── university/           # University selection & filtering
│   │   │   ├── domain/
│   │   │   ├── data/
│   │   │   └── presentation/
│   │   ├── notifications/        # Notifications (used by all features)
│   │   │   ├── domain/
│   │   │   ├── data/
│   │   │   └── presentation/
│   │   └── media/                # Media upload/management
│   │       ├── domain/
│   │       ├── data/
│   │       └── presentation/
│   │
│   ├── auth/                     # STANDALONE: Authentication
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │       ├── bloc/
│   │       └── pages/
│   │           ├── splash_screen.dart
│   │           ├── onboarding_screen.dart
│   │           ├── login_page.dart
│   │           └── create_account_screen.dart
│   │
│   ├── products/                 # STANDALONE: Product marketplace
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── product_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── product_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_products.dart
│   │   │       ├── get_product_by_id.dart
│   │   │       ├── create_product.dart
│   │   │       ├── update_product.dart
│   │   │       ├── delete_product.dart
│   │   │       ├── get_products_by_university.dart
│   │   │       └── get_featured_products.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── product_model.dart
│   │   │   ├── datasources/
│   │   │   │   ├── product_remote_data_source.dart
│   │   │   │   └── product_local_data_source.dart
│   │   │   └── repositories/
│   │   │       └── product_repository_impl.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── product_bloc.dart
│   │       │   ├── product_event.dart
│   │       │   └── product_state.dart
│   │       └── pages/
│   │           ├── product_pages.dart
│   │           ├── all_products_page.dart
│   │           ├── product_details_page.dart
│   │           └── post_product_screen.dart
│   │
│   ├── services/                 # STANDALONE: Service marketplace
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── accommodations/           # STANDALONE: Housing marketplace
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── messages/                 # STANDALONE: Messaging
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── profile/                  # STANDALONE: User profile
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── dashboard/                # STANDALONE: Seller dashboard
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── promotions/               # STANDALONE: Promotions
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── settings/                 # STANDALONE: App settings
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   └── home/                     # STANDALONE: Home/Dashboard aggregator
│       ├── domain/
│       ├── data/
│       └── presentation/
│
├── main.dart
└── main_app.dart
```

---

## 🔄 Dependency Rules (Clean Architecture)

### Layer Dependencies (Within a Feature)
```
Presentation → Domain ← Data
     ↓           ↑
  (uses)    (implements)
```

**Rules**:
1. **Presentation** depends on **Domain** (uses use cases, entities)
2. **Data** depends on **Domain** (implements repository interfaces)
3. **Domain** depends on NOTHING (pure business logic)
4. **Presentation** NEVER depends on **Data** directly

### Feature Dependencies (Between Features)

**Rules**:
1. **Standalone features** can depend on **Shared features**
2. **Standalone features** should NOT depend on other **Standalone features**
3. **Shared features** should NOT depend on **Standalone features**
4. **Shared features** can depend on other **Shared features** (carefully)

**Example of CORRECT dependencies**:
```
✅ Products (standalone) → Reviews (shared)
✅ Services (standalone) → Reviews (shared)
✅ Products (standalone) → University (shared)
✅ Home (standalone) → Products (standalone) - for display only
✅ Search (shared) → Products (standalone) - for searching
```

**Example of WRONG dependencies**:
```
❌ Products (standalone) → Services (standalone)
❌ Reviews (shared) → Products (standalone)
❌ University (shared) → Auth (standalone)
```

---

## 🎯 Implementation Strategy

### Phase 1: Create Shared Features First
1. **University** - Needed by onboarding and all content filtering
2. **Media** - Needed by Products, Services, Accommodations for uploads
3. **Reviews** - Needed by Products, Services, Accommodations
4. **Search** - Needed for discovery across all content
5. **Notifications** - Needed by Messages and other features

### Phase 2: Migrate Standalone Features (Using Shared)
1. Products (uses: Reviews, Media, University)
2. Services (uses: Reviews, Media, University)
3. Accommodations (uses: Reviews, Media, University)
4. Messages (uses: Notifications)
5. Profile (uses: Media)
6. Dashboard (aggregates data from Products, Services, Accommodations)
7. Promotions (links to Products)
8. Settings
9. Home (aggregates everything)

---

## 📝 Dependency Injection Organization

```dart
// lib/core/di/injection_container.dart

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // External Dependencies
  await _initExternalDependencies();
  
  // Core Dependencies
  _initCoreDependencies();
  
  // Shared Features (in order of dependency)
  await _initUniversityFeature();      // No dependencies
  await _initMediaFeature();           // No dependencies
  await _initReviewsFeature();         // No dependencies
  await _initNotificationsFeature();   // No dependencies
  await _initSearchFeature();          // Depends on Products, Services, Accommodations
  
  // Standalone Features
  await _initAuthFeature();            // Already done
  await _initProductsFeature();        // Depends on Reviews, Media, University
  await _initServicesFeature();        // Depends on Reviews, Media, University
  await _initAccommodationsFeature();  // Depends on Reviews, Media, University
  await _initMessagesFeature();        // Depends on Notifications
  await _initProfileFeature();         // Depends on Auth, Media
  await _initDashboardFeature();       // Depends on Products, Services, Accommodations
  await _initPromotionsFeature();      // Depends on Products
  await _initSettingsFeature();        // Depends on Auth
  await _initHomeFeature();            // Depends on most features
}
```

---

## 🚀 Migration Checklist

### Immediate Actions:

1. **Create Shared Features Folder**
   ```bash
   mkdir -p lib/features/shared/{reviews,search,university,notifications,media}
   ```

2. **Move University Selection**
   - Move from `auth/presentation/pages/` to `shared/university/`
   - Implement full Clean Architecture for it
   - Update auth feature to import from shared

3. **Extract Reviews**
   - Move from `core/widgets/` to `shared/reviews/`
   - Implement full Clean Architecture
   - Update Products, Services, Accommodations to use it

4. **Move Search**
   - Move from `features/search/` to `shared/search/`
   - Implement Clean Architecture
   - Make it work across all content types

5. **Move Notifications**
   - Move from `features/notifications/` to `shared/notifications/`
   - Implement Clean Architecture

6. **Create Media Feature**
   - New shared feature for image uploads
   - Centralize image picking/uploading logic

---

## ✅ Benefits of This Organization

1. **Clear Separation**: Easy to understand what's shared vs standalone
2. **Reduced Duplication**: Reviews, Search, Media logic written once
3. **Better Testing**: Shared features tested once, used everywhere
4. **Easier Maintenance**: Changes to shared features benefit all
5. **Scalability**: Easy to add new content types (all use same shared features)
6. **Clean Dependencies**: Clear dependency graph, no circular dependencies
7. **Reusability**: Shared features can be reused in future projects
8. **Team Collaboration**: Different developers can work on different features without conflicts

---

**Next Step**: Create the shared features infrastructure before migrating standalone features.


