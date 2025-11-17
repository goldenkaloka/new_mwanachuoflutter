/// Service category constants
class ServiceCategories {
  static const tutoring = 'Tutoring';
  static const transportation = 'Transportation';
  static const cleaning = 'Cleaning';
  static const laundry = 'Laundry';
  static const foodDelivery = 'Food Delivery';
  static const photography = 'Photography';
  static const eventPlanning = 'Event Planning';
  static const techSupport = 'Tech Support';
  static const fitness = 'Fitness & Training';
  static const beautyServices = 'Beauty Services';
  static const repairs = 'Repairs & Maintenance';
  static const other = 'Other';

  static List<String> get all => [
        tutoring,
        transportation,
        cleaning,
        laundry,
        foodDelivery,
        photography,
        eventPlanning,
        techSupport,
        fitness,
        beautyServices,
        repairs,
        other,
      ];
}

/// Service price types
class ServicePriceType {
  static const hourly = 'Hourly';
  static const fixed = 'Fixed';
  static const perSession = 'Per Session';
  static const perDay = 'Per Day';

  static List<String> get all => [
        hourly,
        fixed,
        perSession,
        perDay,
      ];
}

