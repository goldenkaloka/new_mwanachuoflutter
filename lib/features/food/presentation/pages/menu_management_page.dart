import 'package:flutter/material.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuManagementPage extends StatelessWidget {
  const MenuManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
      appBar: AppBar(
        title: Text(
          'Menu Management', 
          style: GoogleFonts.plusJakartaSans(
            color: isDarkMode ? Colors.white : Colors.black, 
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode ? kSurfaceColorDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black), 
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, color: kPrimaryColor),
            label: Text(
              'Add Item', 
              style: GoogleFonts.plusJakartaSans(color: kPrimaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) => _buildMenuListItem(isDarkMode),
      ),
    );
  }

  Widget _buildMenuListItem(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? kSurfaceColorDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200', 
              width: 80, 
              height: 80, 
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Double Cheese Burger', 
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'TZS 12,000', 
                  style: GoogleFonts.plusJakartaSans(
                    color: kPrimaryColor, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildBadge('Main', kInfoColor),
                    const SizedBox(width: 8),
                    _buildBadge('Available', kSuccessColor),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: isDarkMode ? Colors.white38 : Colors.grey), 
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text, 
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
