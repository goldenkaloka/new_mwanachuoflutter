# 🧪 Mwanachuo Marketplace - Testing Guide

**Project Status:** 100% Feature-Complete ✅  
**Ready for:** End-to-End Testing & Deployment  
**Date:** November 9, 2025

---

## 🎯 TESTING OBJECTIVES

The app is fully built with all features integrated to Supabase. This guide will help you:
1. Add sample data to Supabase
2. Test all features end-to-end
3. Verify everything works correctly
4. Identify and fix any bugs

---

## 📋 PRE-TESTING CHECKLIST

### **✅ Verify Supabase Setup:**
1. Open Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Verify tables exist: `users`, `products`, `services`, `accommodations`, `messages`, `conversations`, `notifications`, `promotions`
4. Verify storage buckets exist: `products`, `services`, `accommodations`, `avatars`
5. Check RLS policies are enabled

### **✅ Verify Flutter Setup:**
```bash
# Check Flutter version
flutter --version

# Check dependencies
flutter pub get

# Verify no compilation errors
flutter analyze
```

---

## 🗂️ STEP 1: ADD SAMPLE DATA TO SUPABASE (15-20 mins)

### **1.1 Add Sample Products**

Open Supabase Dashboard → Table Editor → `products` → Insert Row

**Product 1:**
```
title: "Used MacBook Pro 2020"
description: "Excellent condition, barely used. Includes charger and case."
price: 450.00
category: electronics
condition: used
university_id: [Select any university from dropdown]
seller_id: [Will be filled by your user after signup]
images: ["https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800"]
is_available: true
location: "Main Campus"
```

**Product 2:**
```
title: "Calculus Textbook - 12th Edition"
description: "Like new, no markings. Perfect for first-year students."
price: 25.00
category: books
condition: like_new
university_id: [Select university]
seller_id: [Your user ID]
images: ["https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=800"]
is_available: true
location: "University Library"
```

**Product 3:**
```
title: "Wireless Mouse - Logitech"
description: "Bluetooth mouse, works great. Battery included."
price: 15.00
category: electronics
condition: used
university_id: [Select university]
seller_id: [Your user ID]
images: ["https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=800"]
is_available: true
location: "Campus Bookstore"
```

**Add 5-10 more products** with variety:
- Different categories (electronics, books, clothing, furniture, sports)
- Different conditions (new, like_new, used, fair)
- Different price ranges ($5 - $500)
- Different universities

---

### **1.2 Add Sample Services**

Navigate to `services` table → Insert Row

**Service 1:**
```
title: "Math Tutoring - Calculus & Algebra"
description: "Experienced tutor, helped 50+ students. Available evenings and weekends."
price: 25.00
price_type: hourly
category: tutoring
university_id: [Select university]
provider_id: [Your user ID]
images: ["https://images.unsplash.com/photo-1509062522246-3755977927d7?w=800"]
is_available: true
location: "Student Center"
```

**Service 2:**
```
title: "Graphic Design Services"
description: "Logo design, posters, social media graphics. Fast turnaround!"
price: 30.00
price_type: per_project
category: design
university_id: [Select university]
provider_id: [Your user ID]
images: ["https://images.unsplash.com/photo-1561070791-2526d30994b5?w=800"]
is_available: true
location: "Remote/Online"
```

**Service 3:**
```
title: "Laptop Repair & Upgrade"
description: "Fix hardware issues, install RAM/SSD, virus removal."
price: 20.00
price_type: per_service
category: repair
university_id: [Select university]
provider_id: [Your user ID]
images: ["https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=800"]
is_available: true
location: "Near Engineering Building"
```

**Add 5-10 more services** with variety.

---

### **1.3 Add Sample Accommodations**

Navigate to `accommodations` table → Insert Row

**Accommodation 1:**
```
name: "Cozy Studio Near Campus"
description: "Fully furnished studio apartment. Walking distance to main campus. Utilities included."
price: 500.00
price_type: monthly
room_type: studio
university_id: [Select university]
owner_id: [Your user ID]
images: ["https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800"]
is_available: true
amenities: ["wifi", "water", "electricity", "parking"]
location: "500m from Main Gate"
bedrooms: 0
bathrooms: 1
```

**Accommodation 2:**
```
name: "Shared 2-Bedroom Apartment"
description: "Looking for one roommate. Clean, safe neighborhood. Great landlord."
price: 350.00
price_type: monthly
room_type: shared
university_id: [Select university]
owner_id: [Your user ID]
images: ["https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800"]
is_available: true
amenities: ["wifi", "water", "electricity", "kitchen"]
location: "Westlands Area"
bedrooms: 2
bathrooms: 1
```

**Add 5-10 more accommodations** with variety.

---

### **1.4 Add Sample Promotions**

Navigate to `promotions` table → Insert Row

**Promotion 1:**
```
title: "End of Semester Sale - 50% Off Books!"
subtitle: "Get huge discounts on textbooks"
description: "Selling all my textbooks at half price before summer break."
discount_percentage: 50
start_date: [Today's date]
end_date: [30 days from now]
image_url: "https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=800"
is_active: true
target_category: books
```

**Promotion 2:**
```
title: "Welcome Week Special - Free Tutoring Sessions"
subtitle: "First session free for new students"
description: "Sign up for tutoring and get your first hour free!"
discount_percentage: 100
start_date: [Today]
end_date: [14 days from now]
image_url: "https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800"
is_active: true
target_category: tutoring
```

---

## 🧪 STEP 2: TESTING SCENARIOS

### **Test 1: Authentication Flow** (5 mins)

**Scenario A: New User Sign Up**
1. Run the app: `flutter run`
2. Wait for splash screen (should auto-detect no auth)
3. Navigate through onboarding
4. Select a university
5. Click "Create Account"
6. Enter email, password, full name, phone
7. Submit
8. **Expected:** Account created, navigate to home

**Scenario B: Existing User Login**
1. Close and restart app
2. Wait for splash screen
3. If auto-login works → Success!
4. If not, click "Sign In"
5. Enter credentials
6. **Expected:** Navigate to home

**Scenario C: Logout**
1. Navigate to Profile page
2. Click logout button
3. Confirm
4. **Expected:** Return to login page

**✅ Pass Criteria:**
- Sign up works
- Login works
- Logout works
- Sessions persist

---

### **Test 2: Browse Marketplace** (10 mins)

**Scenario: HomePage Display**
1. Open app and login
2. View HomePage
3. **Check:**
   - ✅ Promotions carousel shows (2 promotions)
   - ✅ Products grid shows (your sample products)
   - ✅ Services grid shows (your sample services)
   - ✅ Accommodations grid shows (your sample accommodations)
   - ✅ Loading states appear briefly
   - ✅ No errors displayed
   - ✅ Images load correctly

**Scenario: Empty States**
1. Remove all products from Supabase
2. Restart app
3. **Check:**
   - ✅ "No products available" message shows
   - ✅ Retry button works
   - ✅ Other sections still display

**✅ Pass Criteria:**
- All 4 sections load correctly
- Real data displays
- Empty states work
- Error handling works

---

### **Test 3: Detail Pages** (15 mins)

**Scenario A: Product Details**
1. From HomePage, tap any product
2. **Check:**
   - ✅ Product details page opens
   - ✅ Title, price, description display
   - ✅ Images appear
   - ✅ Category and condition show
   - ✅ Reviews section loads
   - ✅ "Contact Seller" button exists
   - ✅ Back button works

**Scenario B: Service Details**
1. Tap any service
2. **Check:**
   - ✅ Service details display correctly
   - ✅ Price and price type show
   - ✅ Reviews load
   - ✅ "Contact Provider" button works

**Scenario C: Accommodation Details**
1. Tap any accommodation
2. **Check:**
   - ✅ All details display
   - ✅ Image gallery works
   - ✅ Amenities list shows
   - ✅ "Contact Owner" button works

**✅ Pass Criteria:**
- All detail pages load
- Real data displays correctly
- Navigation works
- Contact buttons navigate to messages

---

### **Test 4: Messaging System** (10 mins)

**Scenario A: View Conversations**
1. Navigate to Messages tab
2. **Check:**
   - ✅ Conversation list loads (or shows empty state)
   - ✅ "No conversations yet" if empty
   - ✅ Loading spinner appears briefly

**Scenario B: Send Message (Manual Test)**
1. Using Supabase Dashboard, create a conversation:
   - Go to `conversations` table
   - Insert row with your user_id and another_user_id
2. Refresh messages page
3. Tap the conversation
4. Type a message
5. Click send
6. **Check:**
   - ✅ Message sends successfully
   - ✅ Message appears in chat
   - ✅ Timestamp displays
   - ✅ Message bubble shows correctly

**Scenario C: Error Handling**
1. Disconnect internet
2. Try to load messages
3. **Check:**
   - ✅ Error message displays
   - ✅ Retry button works
   - ✅ Reconnect → Data loads

**✅ Pass Criteria:**
- Conversations load
- Messages display
- Send message works
- Error handling works

---

### **Test 5: Notifications** (5 mins)

**Scenario: View Notifications**
1. Using Supabase Dashboard, create a notification:
   ```
   user_id: [Your user ID]
   type: message
   title: "New Message"
   message: "Someone sent you a message"
   is_read: false
   action_url: "/messages"
   ```
2. Navigate to Notifications page
3. **Check:**
   - ✅ Notification appears
   - ✅ Unread indicator shows
   - ✅ Correct icon and color

**Scenario: Mark as Read**
1. Tap the notification
2. **Check:**
   - ✅ Notification marked as read
   - ✅ Visual changes (background, dot removed)
   - ✅ Navigation works (if action_url set)

**Scenario: Delete Notification**
1. Swipe notification left
2. **Check:**
   - ✅ Delete animation appears
   - ✅ Notification removed from list
   - ✅ Deleted from Supabase

**✅ Pass Criteria:**
- Notifications display
- Mark as read works
- Delete works
- Navigation works

---

### **Test 6: Profile Page** (5 mins)

**Scenario: View Profile**
1. Navigate to Profile tab
2. **Check:**
   - ✅ Profile loads (or shows loading spinner)
   - ✅ User name displays
   - ✅ Email displays
   - ✅ Avatar displays (or default icon)
   - ✅ UI looks professional

**Scenario: Logout**
1. Click logout button
2. Confirm
3. **Check:**
   - ✅ Logged out successfully
   - ✅ Return to login page
   - ✅ Session cleared

**✅ Pass Criteria:**
- Profile data loads
- Logout works
- UI displays correctly

---

### **Test 7: Search Functionality** (5 mins)

**Scenario: Search Products**
1. From HomePage, click search bar
2. Type "laptop"
3. Press enter or search icon
4. **Check:**
   - ✅ Navigate to search results
   - ✅ Results display (if data exists)
   - ✅ Empty state if no results

**✅ Pass Criteria:**
- Search navigation works
- Results display correctly
- Empty state handles no results

---

### **Test 8: Navigation Flow** (10 mins)

**Scenario: Complete User Journey**
1. Start from splash screen
2. Login
3. Browse homepage
4. Tap a product → View details
5. Click "Contact Seller" → Open messages
6. Send message
7. Go to notifications
8. Navigate to profile
9. Logout

**✅ Pass Criteria:**
- All navigation works
- No crashes
- Smooth transitions
- Back button works everywhere

---

## 🐛 COMMON ISSUES & FIXES

### **Issue 1: "No data showing"**
**Cause:** Data not yet in Supabase  
**Fix:** Add sample data using guide above

### **Issue 2: "Authentication failed"**
**Cause:** Supabase credentials incorrect  
**Fix:** Check `lib/config/supabase_config.dart` has correct URL and anon key

### **Issue 3: "RLS policy error"**
**Cause:** User not authenticated or policies too restrictive  
**Fix:** Check RLS policies in Supabase Dashboard

### **Issue 4: "Images not loading"**
**Cause:** Storage bucket not public or URLs incorrect  
**Fix:** Check storage bucket policies in Supabase

### **Issue 5: "Messages not sending"**
**Cause:** Conversation doesn't exist  
**Fix:** Create conversation manually in Supabase first

---

## ✅ TESTING CHECKLIST

### **Functional Tests:**
- [ ] Sign up new account
- [ ] Login existing account
- [ ] Browse products (see real data)
- [ ] Browse services (see real data)
- [ ] Browse accommodations (see real data)
- [ ] View promotions carousel
- [ ] Tap product → See details
- [ ] Tap service → See details
- [ ] Tap accommodation → See details
- [ ] View reviews on detail pages
- [ ] Navigate to messages
- [ ] Send a message
- [ ] Receive notification (manual)
- [ ] Mark notification as read
- [ ] Delete notification
- [ ] View profile
- [ ] Logout
- [ ] Search for items

### **UI/UX Tests:**
- [ ] Loading states appear
- [ ] Error states display with retry
- [ ] Empty states show helpful messages
- [ ] Images load correctly
- [ ] Navigation is smooth
- [ ] Back buttons work
- [ ] Bottom navigation works
- [ ] Dark mode looks good
- [ ] Responsive on different screen sizes

### **Error Handling Tests:**
- [ ] Disconnect internet → Error displays
- [ ] Retry button works
- [ ] Invalid routes handled
- [ ] Missing data handled gracefully
- [ ] Failed uploads show errors

---

## 📊 TESTING REPORT TEMPLATE

### **Test Date:** _____________
### **Flutter Version:** _____________
### **Device:** _____________

| Feature | Status | Notes |
|---------|--------|-------|
| Authentication | ⬜ Pass / ❌ Fail | |
| Products Display | ⬜ Pass / ❌ Fail | |
| Services Display | ⬜ Pass / ❌ Fail | |
| Accommodations Display | ⬜ Pass / ❌ Fail | |
| Promotions Display | ⬜ Pass / ❌ Fail | |
| Product Details | ⬜ Pass / ❌ Fail | |
| Service Details | ⬜ Pass / ❌ Fail | |
| Accommodation Details | ⬜ Pass / ❌ Fail | |
| Reviews | ⬜ Pass / ❌ Fail | |
| Messaging | ⬜ Pass / ❌ Fail | |
| Notifications | ⬜ Pass / ❌ Fail | |
| Profile | ⬜ Pass / ❌ Fail | |
| Search | ⬜ Pass / ❌ Fail | |
| Navigation | ⬜ Pass / ❌ Fail | |
| Error Handling | ⬜ Pass / ❌ Fail | |

### **Bugs Found:**
1. ___________________________________________
2. ___________________________________________
3. ___________________________________________

### **Overall Result:**
- Total Tests: ___
- Passed: ___
- Failed: ___
- **Pass Rate: ___%**

---

## 🚀 AFTER TESTING

### **If All Tests Pass:**
1. ✅ Celebrate! The app works!
2. ✅ Consider deployment
3. ✅ Add more sample data
4. ✅ Invite alpha testers

### **If Some Tests Fail:**
1. Document the issues
2. Prioritize fixes (critical vs. minor)
3. Fix bugs
4. Re-test
5. Iterate until all pass

### **Optional Enhancements:**
- Add Realtime to messaging (30 mins)
- Add Realtime to notifications (15 mins)
- Add image upload functionality
- Add pagination to lists
- Add advanced search filters
- Add user favorites/saved items

---

## 💡 TESTING TIPS

1. **Test on Real Device:** Emulators can hide issues
2. **Test Both Light & Dark Mode:** UI bugs may appear in one mode
3. **Test Different Screen Sizes:** Responsive design verification
4. **Test Network Issues:** Disconnect/reconnect internet
5. **Test Edge Cases:** Empty lists, long text, special characters
6. **Test User Flows:** Complete journeys, not just individual features

---

## 📱 RUNNING THE APP

```bash
# Run on connected device/emulator
flutter run

# Run in release mode (faster)
flutter run --release

# Run on specific device
flutter devices  # List devices
flutter run -d <device-id>

# Build APK for testing
flutter build apk

# Build for iOS
flutter build ios
```

---

## 🎯 **READY TO TEST!**

**Your app has:**
- ✅ 10 major features
- ✅ Complete backend
- ✅ Professional UI
- ✅ Error handling
- ✅ Real data integration

**Time to see it all work together!** 🚀

**Good luck with testing!** 🧪✨

---

**P.S.** Remember to add sample data BEFORE testing, or you'll see lots of empty states! 😊

