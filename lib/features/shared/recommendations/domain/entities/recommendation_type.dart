/// Enum representing the type of item being recommended
enum RecommendationType { product, service, accommodation }

extension RecommendationTypeExtension on RecommendationType {
  String get value {
    switch (this) {
      case RecommendationType.product:
        return 'product';
      case RecommendationType.service:
        return 'service';
      case RecommendationType.accommodation:
        return 'accommodation';
    }
  }

  static RecommendationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'product':
        return RecommendationType.product;
      case 'service':
        return RecommendationType.service;
      case 'accommodation':
        return RecommendationType.accommodation;
      default:
        return RecommendationType.product;
    }
  }
}


