class RoomTypes {
  static const single = 'Single Room';
  static const shared = 'Shared Room';
  static const studio = 'Studio';
  static const apartment = 'Apartment';
  static const hostel = 'Hostel';

  static List<String> get all => [single, shared, studio, apartment, hostel];
}

class PriceTypes {
  // Stored format (database format)
  static const perMonth = 'per_month';
  static const perSemester = 'per_semester';
  static const perYear = 'per_year';

  static List<String> get all => [perMonth, perSemester, perYear];

  // Display format (for UI)
  static String getDisplayName(String priceType) {
    switch (priceType) {
      case perMonth:
        return 'Per Month';
      case perSemester:
        return 'Per Semester';
      case perYear:
        return 'Per Year';
      default:
        return priceType.replaceAll('_', ' ').split(' ').map((word) {
          return word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1);
        }).join(' ');
    }
  }
}

class Amenities {
  static const wifi = 'WiFi';
  static const parking = 'Parking';
  static const laundry = 'Laundry';
  static const kitchen = 'Kitchen';
  static const airConditioning = 'Air Conditioning';
  static const heating = 'Heating';
  static const furnished = 'Furnished';
  static const petsAllowed = 'Pets Allowed';
  static const security = '24/7 Security';
  static const gym = 'Gym';
  static const pool = 'Swimming Pool';
  static const balcony = 'Balcony';

  static List<String> get all => [
        wifi,
        parking,
        laundry,
        kitchen,
        airConditioning,
        heating,
        furnished,
        petsAllowed,
        security,
        gym,
        pool,
        balcony,
      ];
}

