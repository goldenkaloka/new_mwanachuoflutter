# 🎯 Complete UI Integration Plan

## Goal: Properly integrate all UI files into Clean Architecture

---

## Phase 1: Create Remaining Features (Business Logic)

### 1. **Messages Feature** ⏳
- Domain layer (entities, repository, use cases)
- Data layer (models, data sources, repository impl)
- Presentation layer (BLoC, states, events)
- Move UI: `messages_page.dart`, `chat_screen.dart`

### 2. **Profile Feature** ⏳
- Domain layer
- Data layer
- Presentation layer
- Move UI: `profile_page.dart`, `edit_profile_screen.dart`, `my_listings_screen.dart`, `account_settings_screen.dart`

### 3. **Dashboard Feature** ⏳
- Domain layer
- Data layer
- Presentation layer
- Move UI: `seller_dashboard_screen.dart`

### 4. **Promotions Feature** ⏳
- Domain layer
- Data layer
- Presentation layer
- Move UI: `create_promotion_screen.dart`, `promotion_detail_page.dart`

---

## Phase 2: Move UI Files to Proper Locations

### **Products UI** (3 files)
```
FROM: lib/features/product/
TO:   lib/features/products/presentation/pages/

Files:
- all_products_page.dart
- product_details_page.dart
- post_product_screen.dart
```

### **Services UI** (3 files)
```
FROM: lib/features/services/ (root level)
TO:   lib/features/services/presentation/pages/

Files:
- service_detail_page.dart
- services_screen.dart
- create_service_screen.dart
```

### **Accommodations UI** (3 files)
```
FROM: lib/features/accommodation/
TO:   lib/features/accommodations/presentation/pages/

Files:
- accommodation_detail_page.dart
- student_housing_screen.dart
- create_accommodation_screen.dart
```

### **Notifications UI** (1 file)
```
FROM: lib/features/notifications/
TO:   lib/features/shared/notifications/presentation/pages/

Files:
- notifications_page.dart
```

### **Search UI** (1 file)
```
FROM: lib/features/search/
TO:   lib/features/shared/search/presentation/pages/

Files:
- search_results_page.dart
```

---

## Phase 3: Update Imports

**Files to update**:
- main_app.dart (route definitions)
- home_page.dart (navigation calls)
- seller_dashboard_screen.dart (quick actions)
- All UI files that import other UI files

**Search & Replace Pattern**:
```
OLD: package:mwanachuo/features/product/
NEW: package:mwanachuo/features/products/presentation/pages/

OLD: package:mwanachuo/features/accommodation/
NEW: package:mwanachuo/features/accommodations/presentation/pages/

(etc.)
```

---

## Phase 4: Cleanup Old Folders

**Remove**:
- `lib/features/product/`
- `lib/features/accommodation/`
- `lib/features/promotion/`
- `lib/features/notifications/` (old location)
- `lib/features/search/` (old location)
- `lib/features/messages/` (old location)
- `lib/features/profile/` (old location)
- `lib/features/dashboard/` (old location)
- `lib/features/settings/`
- `lib/features/auth/presentation/pages/university_selection_screen.dart` (duplicate)

---

## Phase 5: Verification

1. Run `flutter analyze` - should have 0 errors
2. Test app compilation - `flutter build`
3. Update main_app.dart routes
4. Test navigation flows

---

## ⏱️ Estimated Time

**Phase 1**: 8-10 hours (create 4 features)
**Phase 2**: 1 hour (move files)
**Phase 3**: 1-2 hours (update imports)
**Phase 4**: 30 min (cleanup)
**Phase 5**: 30 min (verification)

**Total**: 11-14 hours

---

## 🎯 Current Status

**Starting Phase 1 now: Creating Messages Feature!**

