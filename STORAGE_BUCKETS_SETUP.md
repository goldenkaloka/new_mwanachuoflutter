# 📦 Storage Buckets Setup Guide

## Quick Setup (5 minutes)

### Step 1: Go to Supabase Dashboard

1. Open your Supabase project
2. Click **Storage** in the left sidebar
3. Click **New bucket**

---

### Step 2: Create 5 Buckets

Create each bucket with these settings:

#### 1. **product-images**
- Name: `product-images`
- Public: ✅ **YES**
- File size limit: 5 MB
- Allowed MIME types: `image/*`

#### 2. **service-images**
- Name: `service-images`
- Public: ✅ **YES**
- File size limit: 5 MB
- Allowed MIME types: `image/*`

#### 3. **accommodation-images**
- Name: `accommodation-images`
- Public: ✅ **YES**
- File size limit: 5 MB
- Allowed MIME types: `image/*`

#### 4. **profile-images**
- Name: `profile-images`
- Public: ✅ **YES**
- File size limit: 2 MB
- Allowed MIME types: `image/*`

#### 5. **promotion-images**
- Name: `promotion-images`
- Public: ✅ **YES**
- File size limit: 5 MB
- Allowed MIME types: `image/*`

---

### Step 3: Set Bucket Policies (For Each Bucket)

Go to each bucket → **Policies** tab → Add these policies:

#### Policy 1: Allow Authenticated Uploads

```sql
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'product-images');
```

#### Policy 2: Allow Public Downloads

```sql
CREATE POLICY "Allow public downloads"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'product-images');
```

#### Policy 3: Allow Users to Delete Own Files

```sql
CREATE POLICY "Allow users delete own files"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'product-images' AND auth.uid() = owner);
```

**⚠️ Important**: Replace `'product-images'` with the actual bucket name for each bucket!

---

## ✅ Verification

After setup, verify:

- [ ] 5 buckets created and public
- [ ] Each bucket has 3 policies (upload, download, delete)
- [ ] Test upload: Go to bucket → Upload a test image
- [ ] Test public URL: Copy URL and open in browser

---

## 🎯 Quick Test

```dart
// Test image upload
final mediaCubit = sl<MediaCubit>();
await mediaCubit.pickFromGallery();
if (state is MediaPicked) {
  await mediaCubit.uploadSingleImage(
    imageFile: state.files.first,
    bucket: 'product-images',
    folder: 'test',
  );
}
// Should work without errors!
```

---

**Setup Time**: 5-10 minutes

**Status**: Ready for production! ✅

