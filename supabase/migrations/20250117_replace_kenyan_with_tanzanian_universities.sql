-- Migration: Replace Kenyan universities with Tanzanian universities
-- Date: 2025-01-17

-- First, deactivate all Kenyan universities
UPDATE universities
SET is_active = false
WHERE name IN (
  'University of Nairobi',
  'Kenyatta University',
  'Moi University',
  'Egerton University',
  'Jomo Kenyatta University of Agriculture and Technology',
  'Maseno University',
  'Strathmore University'
);

-- Insert Tanzanian universities
-- Note: Using gen_random_uuid() for IDs. Adjust logo_urls with actual URLs when available.

INSERT INTO universities (id, name, short_name, location, logo_url, description, is_active)
VALUES
  (
    gen_random_uuid(),
    'University of Dar es Salaam',
    'UDSM',
    'Dar es Salaam',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDrJZvKSUBKbX014yoj27QHwYw1hGpHwLWDa-d66qvo5YqtQ3uzIsUSgs8__rUyQd7hkNqFatWlOGYhw1oK_ITNZ9e9RzI5VWhHjCkm0HqVSSgrtX7rC4HNuBrGqP7ERp6_h45AnDB7XqoPO1Ooof9K2i-oLIC2umUhAhLXDTY2PvukJohgpe90md0GRL4dggiLB1P3Gq9_U_gLuCwraNbdQmkhlC80WgiBXG0R2xQ7cVLnB6gb21JoO7LTtRd12rh2-1vS7hv2DoZl',
    'The oldest and largest public university in Tanzania',
    true
  ),
  (
    gen_random_uuid(),
    'Sokoine University of Agriculture',
    'SUA',
    'Morogoro',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCV7Lro8VWDLsE_FhWbicwxIUdLZ6n4gfjt3C_Uue-EaXXmLx6A09sMe_aMhoVMRxxiW6OgBlHmyv5Q9_RX2F46ItRSMcDE_vyG8yMm5zxCuu8-zqhlSY09o0G1DPeX4jYxGnmJrEOUZllXbVu_Ky0NMPtI59UrwmBKAqb5C3id-G7F4Xp3830wzLHukTVd0AmdWwyD73itd9rdpRdGxSiEEOrIPXH5h--Nd6FWn5rLaA6nqCuyaWhuQw5lzsm0yQbKQRs6xECGsEd0',
    'Leading university in agriculture and related sciences',
    true
  ),
  (
    gen_random_uuid(),
    'Muhimbili University of Health and Allied Sciences',
    'MUHAS',
    'Dar es Salaam',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBCyUxOQfDD9KvUVUbj1VEtheY6mcUEC4SDCjXxfGm0iuTcGbwkHWM6EDS4Mr45BbuFA7YykSvsFQYzcE4tCZ16sFocRLe0O1XqP2Gd5P849z-FR7D7C3SWAaPUxe2VXkFgmXmtgblAl9hWNBec50NT1T0umO4sJpEvhBGFJmJe0HXP9ia7eRwWVyghMHROdlC2FlR7iChDj80DkxLj9dTHnQQp7YVBFXkZjeQMDVxaagwd6BTZEn4BrRscyUmp3OTGCAMuOoU4P7_r',
    'Premier institution for health sciences education and research',
    true
  ),
  (
    gen_random_uuid(),
    'University of Dodoma',
    'UDOM',
    'Dodoma',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuA36WevzZJZ1cW_aU3Ala0iUEW8eWTgcCW06md27Ou7oKpI7SlOw6bM288IDeoQ3pYh2w-KPUXhFluD-194EWmd4xbRA9ED9PUW4_g4Nte0X1r5qKEPQZhfX9_VYOCuR29IwPmsC2s2OlX16lsbCQWSzeivRbV9VamX9_-gBlCkGcPZ1nVuVzvS9dO3UzWRZBtSiZ3qV9HNr1WPe2TtuQbr_t01sA0Sg50pBFlhI-vYP_JXs0wjuGy9ncc7tLmoS9toLLoXeEs62NI0',
    'Public university located in the capital city of Tanzania',
    true
  ),
  (
    gen_random_uuid(),
    'Ardhi University',
    'ARU',
    'Dar es Salaam',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDTlkvMXW9Iz4iARLFSlhBNOrVcbCbYYMrTmbAiA9Y7bIFiz-_KAHiRB6RJ9gM3pBDLw4cSIdAmZV2bPydexk86KCkZFPRQNOVsE99fAETj4joZUHgZRkSYA5jNRLVkAPw1dnX5RjD897kc_TixQaLXuO_L51VUEa4lC9yi0088KyL70hpF77zozdMghbONHjb_-6405jrOoq5MXniXA5gcMhRLoy_U6LVRpIz_7tVuGfuiq8kcUerKLUEVH7O8cimfydOyuOPz6i0E',
    'Specialized university in land, housing, and urban development',
    true
  ),
  (
    gen_random_uuid(),
    'Nelson Mandela African Institution of Science and Technology',
    'NM-AIST',
    'Arusha',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAI34gA1utFKxP0wnoQoMPCa7V3RQPdRRMJ7e3cmVYC2A8CUKX_D7CAQFgbVDS6jW5gdGM-uSxbbm3VrcIce08twisf8rT-9ISm_TGii0CifTQ344ZKUZf6AMFUAedL_0NPUDnQrOWoSOwdqsTWJ9psmq_0AQiuKWcWwuajaA9ktZDRqty1dkfLgKdXktA7AvYNDHJXuYdSW92sCVj6FoN1BYIwGRL4jMXhGa3UpzZ_5WVHa0Iuh4emJWcwSOvoU6bLXAqY5pMOF_WV',
    'Postgraduate institution focused on science, engineering, and technology',
    true
  ),
  (
    gen_random_uuid(),
    'Mzumbe University',
    'MU',
    'Morogoro',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuC-bkf0eZXvRbYdr6143OEVpm3NT9sboFNQc5j4PdQTq6X_LzmQMwjVIZmOPhZ4ofZuST9hP8RsVL_rlAO8zCNzI3gxjAeqyRqWO8PITwnIHJtB1sbwQTzlidb6kudzhExak8k8cGnxgeKQXwrAhDTPelDfPgVhD4rA_WkyMBzUW58bQha2bU4JFSeYNFyTATFJxV4WTdFrrbTkKUqXjeHtZ_5Hx6ZZ7d7o_pkGxSgssBg2LgloSN4n9jjn0zzfwWlWlhksX0S1wM4K',
    'Public university specializing in business, law, and public administration',
    true
  )
ON CONFLICT (name) DO NOTHING;

-- Note: After running this migration, you may want to:
-- 1. Update the logo_urls with actual university logo URLs
-- 2. Verify that all Tanzanian universities are active and visible
-- 3. Check if any existing users need to update their university selections

