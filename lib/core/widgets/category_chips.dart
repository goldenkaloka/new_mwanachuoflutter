import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/shared/categories/domain/entities/category_entity.dart';
import 'package:mwanachuo/features/shared/categories/presentation/cubit/category_cubit.dart';
import 'package:mwanachuo/features/shared/categories/presentation/cubit/category_state.dart';

/// Horizontal scrolling category chips widget (Alibaba-style)
class CategoryChips extends StatelessWidget {
  final List<ProductCategoryEntity> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;
  final bool showAllOption;
  final String? allLabel;

  const CategoryChips({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
    this.showAllOption = true,
    this.allLabel = 'All',
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? kBackgroundColorDark : kBackgroundColorLight;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // "All" option
            if (showAllOption)
              _CategoryChip(
                label: allLabel!,
                isSelected: selectedCategory == null,
                onTap: () => onCategorySelected(null),
                icon: Icons.apps,
              ),
            // Category chips
            ...categories.map((category) {
              return _CategoryChip(
                label: category.name,
                isSelected: selectedCategory == category.name,
                onTap: () => onCategorySelected(category.name),
                icon: _getIconForCategory(category.icon),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String? iconName) {
    if (iconName == null) return Icons.category_outlined;
    
    // Map icon names to Material icons
    final iconMap = {
      'book': Icons.book_outlined,
      'laptop': Icons.laptop_outlined,
      'chair': Icons.chair_outlined,
      'tshirt': Icons.checkroom_outlined,
      'dumbbell': Icons.fitness_center_outlined,
      'spa': Icons.spa_outlined,
      'fastfood': Icons.fastfood_outlined,
      'pencil': Icons.edit_outlined,
      'car': Icons.directions_car_outlined,
      'blender': Icons.blender_outlined,
      'heart_plus': Icons.favorite_border_outlined,
      'palette': Icons.palette_outlined,
      'guitar': Icons.music_note_outlined,
      'gamepad': Icons.sports_esports_outlined,
      'star': Icons.star_border_outlined,
      'wrench': Icons.build_outlined,
      'ticket': Icons.confirmation_number_outlined,
      'ring': Icons.diamond_outlined,
      'more_horiz': Icons.more_horiz,
    };

    return iconMap[iconName] ?? Icons.category_outlined;
  }
}

/// Category chip item
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? kPrimaryColor
                : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: kPrimaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.grey[300] : Colors.grey[700]),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDarkMode ? Colors.grey[300] : Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category chips widget with BlocBuilder for automatic category loading
class CategoryChipsWithBloc extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;
  final bool showAllOption;
  final String? allLabel;

  const CategoryChipsWithBloc({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
    this.showAllOption = true,
    this.allLabel = 'All',
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return _CategoryChipsSkeleton();
        }

        if (state is CategoryError) {
          return const SizedBox.shrink(); // Hide on error
        }

        if (state is CategoriesLoaded) {
          return CategoryChips(
            categories: state.categories,
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
            showAllOption: showAllOption,
            allLabel: allLabel,
          );
        }

        // Initial state - load categories
        if (state is CategoryInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<CategoryCubit>().loadAll();
          });
          return _CategoryChipsSkeleton();
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// Loading skeleton for category chips
class _CategoryChipsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? kBackgroundColorDark : kBackgroundColorLight;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(
            5,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 100,
                height: 40,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

