-- Enable insert for authenticated users
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON "public"."products";
CREATE POLICY "Enable insert for authenticated users" ON "public"."products" FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Enable insert for authenticated users" ON "public"."services";
CREATE POLICY "Enable insert for authenticated users" ON "public"."services" FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Enable insert for authenticated users" ON "public"."accommodations";
CREATE POLICY "Enable insert for authenticated users" ON "public"."accommodations" FOR INSERT TO authenticated WITH CHECK (true);

-- Ensure users can update their own items
-- Product: seller_id
DROP POLICY IF EXISTS "Enable update for owners" ON "public"."products";
CREATE POLICY "Enable update for owners" ON "public"."products" FOR UPDATE TO authenticated USING (auth.uid() = seller_id);

-- Service: provider_id
DROP POLICY IF EXISTS "Enable update for owners" ON "public"."services";
CREATE POLICY "Enable update for owners" ON "public"."services" FOR UPDATE TO authenticated USING (auth.uid() = provider_id);

-- Accommodation: owner_id
DROP POLICY IF EXISTS "Enable update for owners" ON "public"."accommodations";
CREATE POLICY "Enable update for owners" ON "public"."accommodations" FOR UPDATE TO authenticated USING (auth.uid() = owner_id);

-- Delete policies
-- Product: seller_id
DROP POLICY IF EXISTS "Enable delete for owners" ON "public"."products";
CREATE POLICY "Enable delete for owners" ON "public"."products" FOR DELETE TO authenticated USING (auth.uid() = seller_id);

-- Service: provider_id
DROP POLICY IF EXISTS "Enable delete for owners" ON "public"."services";
CREATE POLICY "Enable delete for owners" ON "public"."services" FOR DELETE TO authenticated USING (auth.uid() = provider_id);

-- Accommodation: owner_id
DROP POLICY IF EXISTS "Enable delete for owners" ON "public"."accommodations";
CREATE POLICY "Enable delete for owners" ON "public"."accommodations" FOR DELETE TO authenticated USING (auth.uid() = owner_id);
