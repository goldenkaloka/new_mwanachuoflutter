class RoomTypes {
  static const single = 'Single Room';
  static const shared = 'Shared Room';
  static const studio = 'Studio';
  static const apartment = 'Apartment';
  static const hostel = 'Hostel';

  static List<String> get all => [single, shared, studio, apartment, hostel];
}

class PriceTypes {
  static const perMonth = 'Per Month';
  static const perSemester = 'Per Semester';
  static const perYear = 'Per Year';

  static List<String> get all => [perMonth, perSemester, perYear];
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

