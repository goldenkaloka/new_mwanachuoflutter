import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/features/food/domain/entities/food_item.dart';
import 'package:mwanachuo/features/food/domain/entities/food_additive.dart';
import 'package:mwanachuo/features/food/presentation/bloc/food_bloc.dart';
import 'package:intl/intl.dart';

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage> {
  @override
  void initState() {
    super.initState();
    final restaurant = context.read<FoodBloc>().state.userRestaurant;
    if (restaurant != null) {
      context.read<FoodBloc>().add(LoadMenu(restaurant.id));
    } else {
      // Try to reload restaurant if missing
      context.read<FoodBloc>().add(CheckUserRestaurant());
    }
  }

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
            onPressed: () {
              final restaurant = context.read<FoodBloc>().state.userRestaurant;
              if (restaurant != null) {
                // Navigate to add food item page (we'll create this next)
                Navigator.pushNamed(context, '/restaurant-food-add', arguments: {'restaurant_id': restaurant.id});
              }
            },
            icon: const Icon(Icons.add, color: kPrimaryColor),
            label: Text(
              'Add Item',
              style: GoogleFonts.plusJakartaSans(color: kPrimaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: BlocListener<FoodBloc, FoodState>(
        listener: (context, state) {
          if (state.registrationSuccess) {
             final restaurant = state.userRestaurant;
             if (restaurant != null) {
               context.read<FoodBloc>().add(LoadMenu(restaurant.id));
             }
          }
          if (state.userRestaurant != null && (state.restaurantId != state.userRestaurant!.id || state.status == FoodStatus.success) && state.status != FoodStatus.loading) {
             context.read<FoodBloc>().add(LoadMenu(state.userRestaurant!.id));
          }
        },
        child: BlocBuilder<FoodBloc, FoodState>(
          builder: (context, state) {
            if (state.status == FoodStatus.loading && state.menu.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.userRestaurant == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Loading restaurant details...', style: GoogleFonts.plusJakartaSans()),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<FoodBloc>().add(CheckUserRestaurant()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state.menu.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 64, color: isDarkMode ? Colors.white10 : Colors.black12),
                    const SizedBox(height: 16),
                    Text(
                      'Your menu is empty',
                      style: GoogleFonts.plusJakartaSans(
                        color: isDarkMode ? Colors.white38 : Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/restaurant-food-add', arguments: {'restaurant_id': state.userRestaurant!.id}),
                      icon: const Icon(Icons.add),
                      label: const Text('Add your first item'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.menu.length,
              itemBuilder: (context, index) => _buildMenuListItem(state.menu[index], isDarkMode),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuListItem(FoodItem item, bool isDarkMode) {
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
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildPlaceholderImage(isDarkMode),
                      )
                    : _buildPlaceholderImage(isDarkMode),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'TZS ${NumberFormat('#,###').format(item.price)}',
                      style: GoogleFonts.plusJakartaSans(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (item.category != null) ...[
                          _buildBadge(item.category!, kInfoColor),
                          const SizedBox(width: 8),
                        ],
                        _buildBadge(
                          item.isAvailable ? 'Available' : 'Unavailable',
                          item.isAvailable ? kSuccessColor : Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: isDarkMode ? Colors.white38 : Colors.grey),
                    onPressed: () {
                      Navigator.pushNamed(context, '/restaurant-food-add', arguments: {'item': item, 'restaurant_id': item.restaurantId});
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(item),
                  ),
                ],
              ),
            ],
          ),
          if (item.additives != null && item.additives!.isNotEmpty) ...[
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Additives:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...item.additives!.map((a) => Chip(
                      label: Text('${a.name} (+${a.price.toInt()})', style: const TextStyle(fontSize: 10)),
                      onDeleted: () => context.read<FoodBloc>().add(DeleteFoodAdditiveEvent(a.id, item.restaurantId)),
                      deleteIconColor: Colors.redAccent,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )),
                ActionChip(
                  label: const Text('Add', style: TextStyle(fontSize: 10, color: kPrimaryColor)),
                  avatar: const Icon(Icons.add, size: 14, color: kPrimaryColor),
                  onPressed: () => _showAddAdditiveDialog(item.id, item.restaurantId),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ] else ...[
             const SizedBox(height: 8),
             Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showAddAdditiveDialog(item.id, item.restaurantId),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Add Additives', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(bool isDarkMode) {
    return Container(
      width: 80,
      height: 80,
      color: isDarkMode ? Colors.white10 : Colors.grey[100],
      child: const Icon(Icons.fastfood_outlined, color: Colors.white24),
    );
  }

  void _confirmDelete(FoodItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<FoodBloc>().add(DeleteFoodItemEvent(item.id, item.restaurantId));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddAdditiveDialog(String foodItemId, String restaurantId) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Additive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name (e.g. Extra Cheese)'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price (e.g. 2000)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                final additive = FoodAdditive(
                  id: '', // Will be generated by backend
                  foodItemId: foodItemId,
                  name: nameController.text,
                  price: double.parse(priceController.text),
                );
                context.read<FoodBloc>().add(AddFoodAdditiveEvent(additive, restaurantId));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
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
