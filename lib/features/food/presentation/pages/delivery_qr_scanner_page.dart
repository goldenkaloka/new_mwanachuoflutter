import 'package:flutter/material.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class DeliveryQrScannerPage extends StatelessWidget {
  const DeliveryQrScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Mock Scanner View
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: kPrimaryColor, width: 4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_2, size: 150, color: Colors.white24),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Scan Rider\'s QR Code',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will release funds from Escrow to the restaurant.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[400], 
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Header
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Text(
                  'Handshake', 
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.flashlight_on, color: Colors.white), 
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Bottom Hint
          Positioned(
            bottom: 50,
            left: 50,
            right: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: kPrimaryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Verify items before scanning', 
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white, 
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
