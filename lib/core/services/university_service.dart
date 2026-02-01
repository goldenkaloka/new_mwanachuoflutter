import 'package:shared_preferences/shared_preferences.dart';

class UniversityService {
  static const String _universityKey = 'selected_university';
  static const String _universityLogoKey = 'selected_university_logo';

  // University data matching the selection screen
  static final Map<String, Map<String, String>> universities = {
    'University of Dar es Salaam': {
      'id': '9f0462c3-5b37-409d-9030-af396e9e7b30',
      'name': 'University of Dar es Salaam',
      'logo':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDrJZvKSUBKbX014yoj27QHwYw1hGpHwLWDa-d66qvo5YqtQ3uzIsUSgs8__rUyQd7hkNqFatWlOGYhw1oK_ITNZ9e9RzI5VWhHjCkm0HqVSSgrtX7rC4HNuBrGqP7ERp6_h45AnDB7XqoPO1Ooof9K2i-oLIC2umUhAhLXDTY2PvukJohgpe90md0GRL4dggiLB1P3Gq9_U_gLuCwraNbdQmkhlC80WgiBXG0R2xQ7cVLnB6gb21JoO7LTtRd12rh2-1vS7hv2DoZl',
    },
    'Sokoine University of Agriculture': {
      'id': '0a2ab3af-4ef5-456d-bcca-38920b14d103',
      'name': 'Sokoine University of Agriculture',
      'logo':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCV7Lro8VWDLsE_FhWbicwxIUdLZ6n4gfjt3C_Uue-EaXXmLx6A09sMe_aMhoVMRxxiW6OgBlHmyv5Q9_RX2F46ItRSMcDE_vyG8yMm5zxCuu8-zqhlSY09o0G1DPeX4jYxGnmJrEOUZllXbVu_Ky0NMPtI59UrwmBKAqb5C3id-G7F4Xp3830wzLHukTVd0AmdWwyD73itd9rdpRdGxSiEEOrIPXH5h--Nd6FWn5rLaA6nqCuyaWhuQw5lzsm0yQbKQRs6xECGsEd0',
    },
    'Muhimbili University of Health and Allied Sciences': {
      'id': 'edb05f53-f2ec-49f4-833d-e91def6bbd3b',
      'name': 'Muhimbili University of Health and Allied Sciences',
      'logo':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBCyUxOQfDD9KvUVUbj1VEtheY6mcUEC4SDCjXxfGm0iuTcGbwkHWM6EDS4Mr45BbuFA7YykSvsFQYzcE4tCZ16sFocRLe0O1XqP2Gd5P849z-FR7D7C3SWAaPUxe2VXkFgmXmtgblAl9hWNBec50NT1T0umO4sJpEvhBGFJmJe0HXP9ia7eRwWVyghMHROdlC2FlR7iChDj80DkxLj9dTHnQQp7YVBFXkZjeQMDVxaagwd6BTZEn4BrRscyUmp3OTGCAMuOoU4P7_r',
    },
    'University of Dodoma': {
      'id': '2d4e21b0-17d7-4310-bc83-9c694c9bb74c',
      'name': 'University of Dodoma',
      'logo':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA36WevzZJZ1cW_aU3Ala0iUEW8eWTgcCW06md27Ou7oKpI7SlOw6bM288IDeoQ3pYh2w-KPUXhFluD-194EWmd4xbRA9ED9PUW4_g4Nte0X1r5qKEPQZhfX9_VYOCuR29IwPmsC2s2OlX16lsbCQWSzeivRbV9VamX9_-gBlCkGcPZ1nVuVzvS9dO3UzWRZBtSiZ3qV9HNr1WPe2TtuQbr_t01sA0Sg50pBFlhI-vYP_JXs0wjuGy9ncc7tLmoS9toLLoXeEs62NI0',
    },
    'Ardhi University': {
      'id': '23530896-b8da-463f-9f79-5932d6b62f61',
      'name': 'Ardhi University',
      'logo':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDTlkvMXW9Iz4iARLFSlhBNOrVcbCbYYMrTmbAiA9Y7bIFiz-_KAHiRB6RJ9gM3pBDLw4cSIdAmZV2bPydexk86KCkZFPRQNOVsE99fAETj4joZUHgZRkSYA5jNRLVkAPw1dnX5RjD897kc_TixQaLXuO_L51VUEa4lC9yi0088KyL70hpF77zozdMghbONHjb_-6405jrOoq5MXniXA5gcMhRLoy_U6LVRpIz_7tVuGfuiq8kcUerKLUEVH7O8cimfydOyuOPz6i0E',
    },
    'Nelson Mandela African Institution of Science and Technology': {
      'id': '0a2a6c44-347f-40f9-ad48-e9493440c27d',
      'name': 'Nelson Mandela African Institution of Science and Technology',
      'logo':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAI34gA1utFKxP0wnoQoMPCa7V3RQPdRRMJ7e3cmVYC2A8CUKX_D7CAQFgbVDS6jW5gdGM-uSxbbm3VrcIce08twisf8rT-9ISm_TGii0CifTQ344ZKUZf6AMFUAedL_0NPUDnQrOWoSOwdqsTWJ9psmq_0AQiuKWcWwuajaA9ktZDRqty1dkfLgKdXktA7AvYNDHJXuYdSW92sCVj6FoN1BYIwGRL4jMXhGa3UpzZ_5WVHa0Iuh4emJWcwSOvoU6bLXAqY5pMOF_WV',
    },
    'Mzumbe University': {
      'id': '97ecdf6c-a7f9-4901-a4d8-cad7f4fdb2ac',
      'name': 'Mzumbe University',
      'logo':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC-bkf0eZXvRbYdr6143OEVpm3NT9sboFNQc5j4PdQTq6X_LzmQMwjVIZmOPhZ4ofZuST9hP8RsVL_rlAO8zCNzI3gxjAeqyRqWO8PITwnIHJtB1sbwQTzlidb6kudzhExak8k8cGnxgeKQXwrAhDTPelDfPgVhD4rA_WkyMBzUW58bQha2bU4JFSeYNFyTATFJxV4WTdFrrbTkKUqXjeHtZ_5Hx6ZZ7d7o_pkGxSgssBg2LgloSN4n9jjn0zzfwWlWlhksX0S1wM4K',
    },
  };

  static Future<void> saveSelectedUniversity(String universityName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_universityKey, universityName);
    if (universities.containsKey(universityName)) {
      await prefs.setString(
        _universityLogoKey,
        universities[universityName]!['logo']!,
      );
    }
  }

  static Future<String?> getSelectedUniversity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_universityKey);
  }

  static Future<String?> getSelectedUniversityLogo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_universityLogoKey);
  }

  static Future<Map<String, String>?> getSelectedUniversityData() async {
    final universityName = await getSelectedUniversity();
    if (universityName != null && universities.containsKey(universityName)) {
      return universities[universityName];
    }
    return null;
  }
}
