import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class WhatsAppContactHelper {
  /// Launches WhatsApp with a pre-filled message
  static Future<void> contactSeller({
    required BuildContext context,
    required String phoneNumber,
    required String message,
  }) async {
    if (phoneNumber.isEmpty) {
      _showError(context, 'Seller phone number is not available');
      return;
    }

    // Format phone number (ensure country code)
    final formattedPhone = _formatPhoneNumber(phoneNumber);
    if (formattedPhone == null) {
      _showError(context, 'Invalid phone number format');
      return;
    }

    // Create WhatsApp URL
    final urlString = _getWhatsAppUrl(formattedPhone, message);
    final Uri? url = Uri.tryParse(urlString);

    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showError(context, 'Could not launch WhatsApp');
    }
  }

  /// Formats phone number to international format (e.g. 255...)
  /// Expects Tanzanian numbers like 0755... or +255...
  static String? _formatPhoneNumber(String phone) {
    String p = phone.replaceAll(RegExp(r'\s+'), ''); // Remove spaces

    // If starts with +, remove it
    if (p.startsWith('+')) {
      p = p.substring(1);
    }

    // If starts with 0 (e.g. 07...), replace with 255
    if (p.startsWith('0')) {
      p = '255${p.substring(1)}';
    }

    // Basic length check (255 + 9 digits = 12 digits)
    if (p.length < 10) return null; // Too short

    return p;
  }

  static String _getWhatsAppUrl(String phone, String message) {
    if (Platform.isAndroid) {
      // Android intent
      return "whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}";
    } else {
      // iOS / Web universal link
      return "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
