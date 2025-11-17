# 🎯 Prioritized Action Items

**Generated:** January 17, 2025  
**Status:** Ready for Implementation

---

## 🚨 URGENT - Fix Immediately (3-4 hours)

### 1. Complete Accommodations CRUD Operations ⚠️

**Priority:** CRITICAL  
**Impact:** Users cannot edit or delete their accommodation listings  
**Effort:** 3-4 hours  

**Tasks:**

#### A. Create Missing Use Cases (1.5 hours)
```bash
# Files to create:
lib/features/accommodations/domain/usecases/
  - update_accommodation.dart
  - delete_accommodation.dart
  - get_my_accommodations.dart
  - increment_view_count.dart
```

#### B. Update Repository Interface (0.5 hours)
```dart
// lib/features/accommodations/domain/repositories/accommodation_repository.dart
// Add methods:
Future<Either<Failure, AccommodationEntity>> updateAccommodation(...);
Future<Either<Failure, void>> deleteAccommodation(String id);
```

#### C. Add BLoC Events & Handlers (1 hour)
```dart
// accommodation_event.dart
class UpdateAccommodationEvent extends AccommodationEvent {...}
class DeleteAccommodationEvent extends AccommodationEvent {...}
class LoadMyAccommodationsEvent extends AccommodationEvent {...}

// accommodation_bloc.dart
Future<void> _onUpdateAccommodation(...);
Future<void> _onDeleteAccommodation(...);
Future<void> _onLoadMyAccommodations(...);
```

#### D. Update UI (1 hour)
```dart
// accommodation_detail_page.dart
// Add Edit & Delete buttons for owner
// Navigate to edit screen
// Show delete confirmation dialog
```

**Files to Modify:**
1. `lib/features/accommodations/domain/repositories/accommodation_repository.dart`
2. `lib/features/accommodations/data/repositories/accommodation_repository_impl.dart`
3. `lib/features/accommodations/presentation/bloc/accommodation_event.dart`
4. `lib/features/accommodations/presentation/bloc/accommodation_state.dart`
5. `lib/features/accommodations/presentation/bloc/accommodation_bloc.dart`
6. `lib/features/accommodations/presentation/pages/accommodation_detail_page.dart`
7. Create: `lib/features/accommodations/presentation/pages/edit_accommodation_screen.dart`

**Reference Implementation:** Check `products` or `services` feature for pattern

---

## 🔥 HIGH PRIORITY - This Week (11-12 hours)

### 2. Implement Retry Logic for File Uploads (4-5 hours)

**Priority:** HIGH  
**Impact:** Poor user experience when uploads fail  
**Effort:** 4-5 hours  

**Tasks:**

#### A. Add Retry to Media Feature (2-3 hours)
```dart
// lib/features/shared/media/data/datasources/media_remote_data_source.dart

Future<MediaEntity> uploadImageWithRetry({
  required File imageFile,
  required String bucket,
  required String folder,
  int maxRetries = 3,
}) async {
  int attempts = 0;
  Duration delay = Duration(seconds: 1);
  
  while (attempts < maxRetries) {
    try {
      return await uploadImage(imageFile, bucket, folder);
    } catch (e) {
      attempts++;
      if (attempts >= maxRetries) rethrow;
      await Future.delayed(delay);
      delay *= 2; // Exponential backoff
    }
  }
  throw ServerException('Upload failed after $maxRetries attempts');
}
```

#### B. Add UI Feedback (2 hours)
```dart
// Show retry button on failure
// Show upload progress
// Allow manual retry
```

**Files to Modify:**
1. `lib/features/shared/media/data/datasources/media_remote_data_source.dart`
2. `lib/features/shared/media/domain/usecases/upload_image.dart`
3. `lib/features/shared/media/presentation/cubit/media_cubit.dart`
4. Add retry UI widget

---

### 3. Add Infinite Scroll to Products & Services (4-5 hours)

**Priority:** HIGH  
**Impact:** Better performance and UX for large lists  
**Effort:** 4-5 hours  

**Tasks:**

#### A. Products Infinite Scroll (2 hours)
```dart
// lib/features/products/presentation/pages/all_products_page.dart

final ScrollController _scrollController = ScrollController();

@override
void initState() {
  super.initState();
  _scrollController.addListener(_onScroll);
}

void _onScroll() {
  if (_scrollController.position.pixels >= 
      _scrollController.position.maxScrollExtent * 0.9) {
    if (state is ProductsLoaded && state.hasMore) {
      context.read<ProductBloc>().add(
        LoadMoreProductsEvent(offset: state.products.length)
      );
    }
  }
}
```

#### B. Services Infinite Scroll (2-3 hours)
- Same pattern as Products
- Add LoadMoreServicesEvent
- Update ServicesLoaded state with hasMore flag
- Implement scroll listener

**Files to Modify:**
1. `lib/features/products/presentation/pages/all_products_page.dart`
2. `lib/features/services/presentation/pages/services_screen.dart`
3. `lib/features/services/presentation/bloc/service_event.dart`
4. `lib/features/services/presentation/bloc/service_state.dart`
5. `lib/features/services/presentation/bloc/service_bloc.dart`

**Reference:** `lib/features/messages/` has perfect pagination implementation

---

### 4. Improve Cache Strategy (3-4 hours)

**Priority:** HIGH  
**Impact:** Reduced network requests, better offline support  
**Effort:** 3-4 hours  

**Tasks:**

#### A. Implement Incremental Cache Updates (2 hours)
```dart
// Products Repository - like Messages feature
@override
Future<Either<Failure, ProductEntity>> createProduct(...) async {
  final result = await remoteDataSource.createProduct(...);
  
  // ❌ OLD: await localDataSource.clearCache();
  // ✅ NEW: await localDataSource.addProductToCache(product);
  
  return Right(result);
}
```

#### B. Add Cache TTL Configuration (1-2 hours)
```dart
// core/constants/cache_constants.dart
class CacheConstants {
  static const Duration productCacheTTL = Duration(hours: 1);
  static const Duration serviceCacheTTL = Duration(hours: 1);
  static const Duration conversationCacheTTL = Duration(minutes: 30);
}
```

**Files to Modify:**
1. `lib/features/products/data/datasources/product_local_data_source.dart`
2. `lib/features/products/data/repositories/product_repository_impl.dart`
3. `lib/features/services/data/datasources/service_local_data_source.dart`
4. `lib/features/services/data/repositories/service_repository_impl.dart`
5. Create: `lib/core/constants/cache_constants.dart`

**Reference:** `lib/features/messages/data/` has perfect incremental caching

---

## 🟡 MEDIUM PRIORITY - Next 2 Weeks (13-16 hours)

### 5. Add Pagination to Remaining Features (6-8 hours)

**Features needing pagination:**
- Accommodations (2 hours)
- Reviews (2 hours)
- Notifications (2 hours)
- Search Results (2 hours)

**Pattern to follow:** Messages feature pagination

---

### 6. Replace Debug Logging with Logger Package (2-3 hours)

**Tasks:**

#### A. Add Logger Dependency (0.5 hours)
```yaml
# pubspec.yaml
dependencies:
  logger: ^2.4.0
```

#### B. Create Logger Utility (0.5 hours)
```dart
// lib/core/utils/app_logger.dart
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  static void debug(String message) => _logger.d(message);
  static void info(String message) => _logger.i(message);
  static void warning(String message) => _logger.w(message);
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
```

#### C. Replace All debugPrint (1-2 hours)
```bash
# Find all debug prints:
grep -r "debugPrint" lib/features/ | wc -l

# Replace with AppLogger:
debugPrint('✅ Success') → AppLogger.info('Success')
debugPrint('❌ Error: $e') → AppLogger.error('Error', e)
```

**Files with most debug prints:**
1. `lib/features/products/data/repositories/product_repository_impl.dart` (15 prints)
2. `lib/features/services/data/datasources/service_remote_data_source.dart` (12 prints)
3. `lib/features/accommodations/data/datasources/accommodation_remote_data_source.dart` (10 prints)
4. `lib/features/messages/data/datasources/message_remote_data_source.dart` (cleaned recently)

---

### 7. Add Loading Skeletons (3-4 hours)

**Impact:** Better perceived performance  
**Effort:** 3-4 hours  

**Tasks:**
- Create reusable skeleton widgets
- Replace CircularProgressIndicator with skeletons
- Add shimmer effect

**Package:** `shimmer: ^3.0.0`

---

### 8. Implement Error Retry UI (2-3 hours)

**Tasks:**
- Create retry button widget
- Add to all error states
- Connect to BLoC retry events
- Show helpful error messages

---

## 🟢 LOW PRIORITY - Next Month (18-23 hours)

### 9. Implement Favoriting/Wishlist System (8-10 hours)

**Database Migration:**
```sql
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  item_id UUID NOT NULL,
  item_type TEXT NOT NULL, -- 'product', 'service', 'accommodation'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, item_id, item_type)
);

CREATE INDEX idx_favorites_user ON favorites(user_id);
CREATE INDEX idx_favorites_item ON favorites(item_id, item_type);
```

**Feature Structure:**
```
lib/features/favorites/
  - domain/
    - entities/favorite_entity.dart
    - repositories/favorite_repository.dart
    - usecases/
      - add_favorite.dart
      - remove_favorite.dart
      - get_favorites.dart
      - is_favorite.dart
  - data/
    - models/favorite_model.dart
    - datasources/favorite_remote_data_source.dart
    - repositories/favorite_repository_impl.dart
  - presentation/
    - cubit/favorite_cubit.dart
    - pages/favorites_page.dart
    - widgets/favorite_button.dart
```

---

### 10. Admin Promotions Management (6-8 hours)

**Create Admin UI:**
```
lib/features/promotions/presentation/pages/
  - admin_promotions_page.dart (list all promotions)
  - create_promotion_form.dart (create/edit)
```

**Add CRUD Use Cases:**
```
lib/features/promotions/domain/usecases/
  - create_promotion.dart
  - update_promotion.dart
  - delete_promotion.dart
  - toggle_promotion_status.dart
```

---

### 11. Rating Analytics & Charts (4-5 hours)

**Tasks:**
- Rating distribution histogram
- Review trends line chart
- Average rating by category
- Top rated items widget

**Package:** `fl_chart: ^0.69.0`

---

## 📊 Time Estimates Summary

| Priority | Items | Time Range | Total |
|----------|-------|------------|-------|
| **URGENT** | 1 | 3-4 hours | **3-4 hours** |
| **HIGH** | 3 | 11-14 hours | **11-14 hours** |
| **MEDIUM** | 4 | 13-16 hours | **13-16 hours** |
| **LOW** | 3 | 18-23 hours | **18-23 hours** |

**Grand Total: 45-57 hours (1-1.5 weeks with 1 full-time developer)**

---

## 🎯 Recommended Implementation Order

### Week 1 (Days 1-5)
1. ✅ **Day 1-2:** Complete Accommodations CRUD (3-4 hours)
2. ✅ **Day 2-3:** Implement retry logic (4-5 hours)
3. ✅ **Day 3-4:** Add infinite scroll (4-5 hours)
4. ✅ **Day 4-5:** Improve caching (3-4 hours)

**Week 1 Total: 14-18 hours**

### Week 2 (Days 6-10)
5. ✅ **Day 6-7:** Add pagination everywhere (6-8 hours)
6. ✅ **Day 8:** Replace debug logging (2-3 hours)
7. ✅ **Day 9:** Add loading skeletons (3-4 hours)
8. ✅ **Day 10:** Implement retry UI (2-3 hours)

**Week 2 Total: 13-18 hours**

### Week 3-4 (Optional - Low Priority)
9. ✅ Favoriting system (8-10 hours)
10. ✅ Admin promotions (6-8 hours)
11. ✅ Rating analytics (4-5 hours)

**Week 3-4 Total: 18-23 hours**

---

## 📋 Checklist for Each Task

Before marking a task as complete, ensure:

- [ ] Code follows existing architecture patterns
- [ ] No linter errors or warnings
- [ ] Debug prints removed or replaced with logger
- [ ] Error handling implemented
- [ ] Loading states handled
- [ ] UI updated if needed
- [ ] Cache strategy considered
- [ ] Network failures handled gracefully
- [ ] Commented any complex logic
- [ ] Tested manually on device/emulator

---

## 🔗 Reference Implementations

When implementing these tasks, refer to these well-implemented features:

1. **Perfect CRUD:** `lib/features/products/` or `lib/features/services/`
2. **Perfect Pagination:** `lib/features/messages/`
3. **Perfect Caching:** `lib/features/messages/data/datasources/message_local_data_source.dart`
4. **Perfect Real-time:** `lib/features/messages/data/datasources/message_remote_data_source.dart`
5. **Perfect BLoC:** `lib/features/products/presentation/bloc/product_bloc.dart`

---

## 🎉 Quick Wins (30 minutes each)

If you have limited time, start with these quick improvements:

1. ✅ **Add pull-to-refresh** to Products/Services lists (30 min)
2. ✅ **Add search bar** to My Listings page (30 min)
3. ✅ **Add filter chips** to Products page (30 min)
4. ✅ **Add empty state widgets** (30 min)
5. ✅ **Add success snackbars** after CRUD operations (30 min)

---

**Status:** Ready for Implementation  
**Next Action:** Start with Accommodations CRUD (Item #1)  
**Updated:** January 17, 2025

