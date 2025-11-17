# Step 5: Detail Pages Integration Strategy

## Overview
Connect Product, Service, and Accommodation detail pages to their respective BLoCs + ReviewCubit.

## Current Status

### **Product Details Page** ✅ **50% Complete**
**What's Done:**
- ✅ Added BLoC imports (ProductBloc, ReviewCubit, entities)
- ✅ Changed to StatelessWidget wrapper with MultiBlocProvider
- ✅ Load product by ID from route arguments
- ✅ Increment view count on page load
- ✅ Load reviews with stats for the product
- ✅ Invalid ID error handling

**What Remains:**
1. Wrap build method body with `BlocBuilder<ProductBloc, ProductState>`
2. Add loading/error/empty states
3. Pass `ProductEntity` to all builder methods
4. Update CommentsAndRatingsSection with real product ID
5. Update image carousel to use `product.images`
6. Update product info to use real data (title, price, rating, etc.)
7. Update seller info with real seller data

## Implementation Pattern

### **Phase 1: BLoC Infrastructure** ✅ (Already Done for Product Details)

```dart
class ProductDetailsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productId = ModalRoute.of(context)?.settings.arguments as String?;
    
    if (productId == null) {
      return Scaffold(body: Center(child: Text('Invalid product ID')));
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<ProductBloc>()
            ..add(LoadProductByIdEvent(productId: productId))
            ..add(IncrementViewCountEvent(productId: productId)),
        ),
        BlocProvider(
          create: (context) => sl<ReviewCubit>()
            ..loadReviewsWithStats(
              itemId: productId,
              itemType: ReviewType.product,
            ),
        ),
      ],
      child: const _ProductDetailsView(),
    );
  }
}
```

### **Phase 2: Add BlocBuilder Wrapper** ⏳ (Next Step)

The current build method body (lines 96-194) needs to be wrapped:

```dart
@override
Widget build(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final primaryTextColor = isDarkMode ? Colors.white : kBackgroundColorDark;
  final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  final cardBgColor = isDarkMode ? kBackgroundColorDark : Colors.white;
  final isExpanded = ResponsiveBreakpoints.isExpanded(context);

  return BlocBuilder<ProductBloc, ProductState>(
    builder: (context, state) {
      if (state is ProductLoading) {
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (state is ProductError) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(state.message),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final productId = ModalRoute.of(context)?.settings.arguments as String?;
                    if (productId != null) {
                      context.read<ProductBloc>().add(LoadProductByIdEvent(productId: productId));
                    }
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      if (state is ProductLoaded) {
        final product = state.product;
        
        return Scaffold(
          body: ResponsiveBuilder(
            builder: (context, screenSize) {
              // EXISTING CODE - but now pass 'product' to all builder methods
              if (isExpanded) {
                return _buildExpandedLayout(
                  context,
                  product,  // <- ADD THIS
                  isDarkMode,
                  primaryTextColor,
                  secondaryTextColor,
                  cardBgColor,
                );
              }
              
              return Stack(
                children: [
                  SingleChildScrollView(
                    // ... existing code ...
                    child: Column(
                      children: [
                        _buildImageCarousel(product, screenSize),  // <- PASS PRODUCT
                        _buildPageIndicators(product, isDarkMode, screenSize),
                        _buildProductInfo(product, primaryTextColor, screenSize),  // <- PASS PRODUCT
                        _buildDescription(product, primaryTextColor, secondaryTextColor, screenSize),
                        _buildSellerInfo(product, primaryTextColor, secondaryTextColor, cardBgColor, screenSize),
                        // Update CommentsAndRatingsSection
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: ResponsiveBreakpoints.responsiveHorizontalPadding(context)),
                          child: CommentsAndRatingsSection(
                            itemId: product.id,  // <- USE REAL ID
                            itemType: 'product',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildTopAppBar(isDarkMode, primaryTextColor, screenSize),
                  if (ResponsiveBreakpoints.isCompact(context))
                    _buildCtaButton(product, isDarkMode),  // <- PASS PRODUCT
                ],
              );
            },
          ),
        );
      }

      return Scaffold(body: Center(child: Text('Something went wrong')));
    },
  );
}
```

### **Phase 3: Update Builder Methods Signatures**

All the builder methods need to accept `ProductEntity product` as first parameter:

```dart
Widget _buildImageCarousel(ProductEntity product, ScreenSize screenSize) {
  return SizedBox(
    height: ResponsiveBreakpoints.responsiveValue(...),
    child: PageView.builder(
      controller: _pageController,
      itemCount: product.images.length,  // <- USE REAL IMAGE COUNT
      itemBuilder: (context, index) {
        return NetworkImageWithFallback(
          imageUrl: product.images[index],  // <- USE REAL IMAGES
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      },
    ),
  );
}

Widget _buildPageIndicators(ProductEntity product, bool isDarkMode, ScreenSize screenSize) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      product.images.length,  // <- USE REAL IMAGE COUNT
      (index) => Container(/* indicator dots */),
    ),
  );
}

Widget _buildProductInfo(ProductEntity product, Color primaryTextColor, ScreenSize screenSize) {
  return Padding(
    padding: EdgeInsets.all(...),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title,  // <- USE REAL TITLE
          style: GoogleFonts.plusJakartaSans(...),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Text(
              '\$${product.price.toStringAsFixed(2)}',  // <- USE REAL PRICE
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            Spacer(),
            if (product.rating != null) ...[
              Icon(Icons.star, color: Colors.amber, size: 20),
              SizedBox(width: 4),
              Text('${product.rating!.toStringAsFixed(1)} (${product.reviewCount})'),
            ],
          ],
        ),
        SizedBox(height: 8),
        Chip(
          label: Text(product.category),  // <- USE REAL CATEGORY
          backgroundColor: kPrimaryColor.withOpacity(0.2),
        ),
        SizedBox(height: 8),
        Text('Condition: ${product.condition}'),  // <- USE REAL CONDITION
      ],
    ),
  );
}

Widget _buildDescription(ProductEntity product, Color primaryTextColor, Color secondaryTextColor, ScreenSize screenSize) {
  return Padding(
    padding: EdgeInsets.all(...),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(
          product.description,  // <- USE REAL DESCRIPTION
          style: TextStyle(color: secondaryTextColor),
        ),
      ],
    ),
  );
}
```

## Same Pattern for Service & Accommodation Details

### **Service Details Page**
1. Add MultiBlocProvider with ServiceBloc + ReviewCubit
2. Load service by ID: `LoadServiceByIdEvent(serviceId: serviceId)`
3. Load reviews: `ReviewType.service`
4. Wrap with `BlocBuilder<ServiceBloc, ServiceState>`
5. Pass `ServiceEntity` to all methods
6. Update UI to show real service data

### **Accommodation Details Page**
1. Add MultiBlocProvider with AccommodationBloc + ReviewCubit
2. Load accommodation by ID: `LoadAccommodationByIdEvent(accommodationId: accommodationId)`
3. Load reviews: `ReviewType.accommodation`
4. Wrap with `BlocBuilder<AccommodationBloc, AccommodationState>`
5. Pass `AccommodationEntity` to all methods
6. Update UI to show real accommodation data

## Key Updates Summary

### **For Each Detail Page:**

1. **File Structure:**
   ```
   StatelessWidget (wrapper with MultiBlocProvider)
     └── StatefulWidget (internal view with state for PageController, etc.)
   ```

2. **Load Data on Init:**
   - Item by ID
   - Increment view count (products only)
   - Reviews with stats

3. **State Handling:**
   - Loading → Spinner
   - Error → Error message + Retry button
   - Loaded → Show real data
   - Empty → "Not found" message

4. **Pass Entity Everywhere:**
   - All builder methods receive entity as first param
   - Use entity fields instead of mock data
   - Update CommentsAndRatingsSection with real item ID

## Benefits of This Approach

✅ **Real Data:** No more mock data, everything from Supabase  
✅ **Loading States:** User sees feedback while data loads  
✅ **Error Handling:** Proper error messages with retry  
✅ **View Tracking:** Product views automatically incremented  
✅ **Reviews Integration:** Real reviews loaded for each item  
✅ **Type Safety:** Entities provide compile-time safety  

## Estimated Work

- **Product Details:** 1-2 hours (most complex with image carousel)
- **Service Details:** 45-60 minutes (similar to product)
- **Accommodation Details:** 45-60 minutes (similar pattern)

**Total:** ~3 hours for all three detail pages

## Alternative: Faster Implementation

If the full implementation is too time-consuming, we can:

1. Keep existing UI "as is" (with mock styling)
2. Only update the DATA sources (pass real entities)
3. Skip the BlocBuilder wrapper initially
4. Add state management in a future iteration

This would still show real data but skip the loading/error states for now.

---

**Next Action:** Choose approach:
- **Option A:** Full implementation (wrap with BlocBuilder, add all states)
- **Option B:** Quick implementation (just pass real data, skip state UI)
- **Option C:** I can implement it for you (may take multiple steps due to file size)

