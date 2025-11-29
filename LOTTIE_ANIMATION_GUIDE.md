# Lottie Animation Guide for Splash Screen

## Recommended Animations for Mwanachuoshop

### Best Options (Shopping/Marketplace Theme):

1. **Shopping Cart Animation**
   - Search: "shopping cart" or "cart animation"
   - LottieFiles: https://lottiefiles.com/search?q=shopping%20cart
   - Recommended IDs: Look for animations with IDs like:
     - `lf20_xxx` (shopping cart with items)
     - `lf30_xxx` (cart loading/filling)

2. **Marketplace/Store Animation**
   - Search: "marketplace" or "store" or "shop"
   - LottieFiles: https://lottiefiles.com/search?q=marketplace
   - Look for: Store icons, shopping bags, or marketplace concepts

3. **Loading/Spinner with Shopping Theme**
   - Search: "shopping loading" or "cart loading"
   - Good for: Simple, clean loading animation

4. **Bag Animation**
   - Search: "shopping bag" or "bag"
   - Matches your current icon (CupertinoIcons.cart_fill)

## How to Download:

### Step 1: Visit LottieFiles
Go to: https://lottiefiles.com/

### Step 2: Search for Animation
Use these search terms:
- "shopping cart"
- "marketplace"
- "shopping bag"
- "cart loading"
- "store animation"

### Step 3: Preview and Download
1. Click on an animation you like
2. Click the "Download" button
3. Select "Lottie JSON" format
4. Save the file

### Step 4: Add to Project
1. Place the downloaded JSON file in: `assets/animations/`
2. Name it: `splash_animation.json` (or any name you prefer)
3. Update `pubspec.yaml` to include the animations folder (already done)
4. Update the splash screen code to use the animation

## Specific Recommendations:

### Option 1: Simple Cart Animation
- Search: "Shopping Cart" by various creators
- Look for: Simple, clean animations (2-3 seconds)
- File size: Keep under 100KB for best performance

### Option 2: Loading Cart
- Search: "Cart Loading" or "Shopping Loading"
- Good for: Professional, subtle animation
- Duration: 1-2 seconds loop

### Option 3: Bag Fill Animation
- Search: "Shopping Bag Fill" or "Bag Animation"
- Matches: Your current cart icon theme
- Style: Playful or professional

## Quick Download Links:

1. **Popular Shopping Cart Animations:**
   - https://lottiefiles.com/search?q=shopping%20cart&category=animations
   - Filter by: Free, Popular, Recent

2. **Marketplace Animations:**
   - https://lottiefiles.com/search?q=marketplace
   - Look for: Simple, clean designs

3. **Loading Animations:**
   - https://lottiefiles.com/search?q=shopping%20loading
   - Good for: Subtle, professional look

## After Downloading:

1. Save the file as `splash_animation.json` in `assets/animations/`
2. The code is already set up - just uncomment the Lottie widget in `splash_screen.dart`
3. Test the animation and adjust size/duration as needed

## Tips:

- **File Size**: Keep animations under 100KB for fast loading
- **Duration**: 1-3 seconds is ideal for splash screens
- **Style**: Match your app's color scheme (green/white)
- **Loop**: Set `repeat: true` for continuous animation, or `false` for one-time play

