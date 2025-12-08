import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';

/// Represents a single filter chip
class FilterChipData {
  final String label;
  final String value;
  final VoidCallback onRemove;

  const FilterChipData({
    required this.label,
    required this.value,
    required this.onRemove,
  });
}

/// Widget to display active filters as chips
class FilterChips extends StatelessWidget {
  final List<FilterChipData> filters;
  final VoidCallback? onClearAll;
  final bool showClearAll;

  const FilterChips({
    super.key,
    required this.filters,
    this.onClearAll,
    this.showClearAll = true,
  });

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...filters.map((filter) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text(
                      filter.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 18,
                    ),
                    onDeleted: filter.onRemove,
                    backgroundColor: isDarkMode
                        ? kPrimaryColor.withValues(alpha: 0.2)
                        : kPrimaryColorLight,
                    labelStyle: TextStyle(
                      color: isDarkMode ? kPrimaryColorLight : kPrimaryColor,
                    ),
                    deleteIconColor: isDarkMode
                        ? kPrimaryColorLight
                        : kPrimaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                )),
            if (showClearAll && onClearAll != null && filters.length > 1)
              TextButton(
                onPressed: onClearAll,
                child: Text(
                  'Clear all',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

