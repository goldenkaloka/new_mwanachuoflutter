import 'package:flutter/material.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class RestaurantAdminDashboard extends StatelessWidget {
  const RestaurantAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
      appBar: AppBar(
        title: Text(
          'Restaurant Manager', 
          style: GoogleFonts.plusJakartaSans(
            color: isDarkMode ? Colors.white : Colors.black, 
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode ? kSurfaceColorDark : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: isDarkMode ? Colors.white : Colors.black), 
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsGrid(isDarkMode),
            const SizedBox(height: 32),
            _buildSectionHeader('Live Orders', 'View All', isDarkMode),
            _buildOrderList(isDarkMode),
            const SizedBox(height: 32),
            _buildQuickActions(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isDarkMode) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Income', 'TZS 450k', Icons.payments_outlined, kSuccessColor),
        _buildStatCard('Orders', '24', Icons.shopping_bag_outlined, kInfoColor),
        _buildStatCard('Rating', '4.8', Icons.star_outline, kWarningColor),
        _buildStatCard('Status', 'Open', Icons.access_time, kPrimaryColor),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value, 
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: color,
                ),
              ),
              Text(
                label, 
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, 
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title, 
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20, 
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        TextButton(
          onPressed: () {}, 
          child: Text(action, style: const TextStyle(color: kPrimaryColor)),
        ),
      ],
    );
  }

  Widget _buildOrderList(bool isDarkMode) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) => _buildOrderItem(index, isDarkMode),
    );
  }

  Widget _buildOrderItem(int index, bool isDarkMode) {
    final statuses = ['Preparing', 'New', 'Ready'];
    final status = statuses[index % 3];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? kSurfaceColorDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: kPrimaryColor.withValues(alpha: 0.1), 
            child: Text('#$index', style: const TextStyle(color: kPrimaryColor)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'John Doe', 
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '2x Burger, 1x Coke', 
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, 
                    color: isDarkMode ? Colors.white38 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status == 'New' ? kInfoColor.withValues(alpha: 0.1) : kWarningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status, 
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, 
                fontWeight: FontWeight.bold,
                color: status == 'New' ? kInfoColor : kWarningColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Management', 
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20, 
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionTile(context, Icons.restaurant_menu, 'Manage Menu', 'Update prices and items', () {
          Navigator.pushNamed(context, '/restaurant-menu-manage');
        }, isDarkMode),
        _buildActionTile(context, Icons.history, 'Order History', 'View past transactions', () {}, isDarkMode),
        _buildActionTile(context, Icons.campaign_outlined, 'Promotions', 'Create special offers', () {}, isDarkMode),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap, bool isDarkMode) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white10 : Colors.grey[100], 
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: kPrimaryColor),
      ),
      title: Text(
        title, 
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle, 
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12, 
          color: isDarkMode ? Colors.white38 : Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}
