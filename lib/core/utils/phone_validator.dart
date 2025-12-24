class PhoneValidator {
  static const String countryCode = '+255';

  /// Validates a Tanzanian phone number.
  /// Supported formats:
  /// - +255 7xx xxx xxx
  /// - 255 7xx xxx xxx
  /// - 07xx xxx xxx
  static bool isValid(String? phone) {
    if (phone == null || phone.isEmpty) return false;

    // Remove whitespace and hyphens
    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');

    // Check basic patterns
    // Allows 06xxx and 07xxx
    if (cleanPhone.startsWith('+255')) {
      return RegExp(r'^\+255[67]\d{8}$').hasMatch(cleanPhone);
    } else if (cleanPhone.startsWith('255')) {
      return RegExp(r'^255[67]\d{8}$').hasMatch(cleanPhone);
    } else if (cleanPhone.startsWith('0')) {
      return RegExp(r'^0[67]\d{8}$').hasMatch(cleanPhone);
    }

    return false;
  }

  /// Formats a phone number to E.164 format (+255...).
  /// Returns null if the phone number is invalid.
  static String? format(String? phone) {
    if (!isValid(phone)) return null;

    final cleanPhone = phone!.replaceAll(RegExp(r'[\s-]'), '');

    if (cleanPhone.startsWith('0')) {
      return '$countryCode${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('255')) {
      return '+$cleanPhone';
    } else if (cleanPhone.startsWith('+255')) {
      return cleanPhone;
    }

    return null;
  }
}
