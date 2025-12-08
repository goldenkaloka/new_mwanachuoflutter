import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';

/// Filter option for bottom sheet
class FilterOption {
  final String label;
  final String value;
  final bool isSelected;

  const FilterOption({
    required this.label,
    required this.value,
    this.isSelected = false,
  });

  FilterOption copyWith({bool? isSelected}) {
    return FilterOption(
      label: label,
      value: value,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Filter section in bottom sheet
class FilterSection {
  final String title;
  final List<FilterOption> options;
  final bool isMultiSelect;

  const FilterSection({
    required this.title,
    required this.options,
    this.isMultiSelect = false,
  });
}

/// Price range filter
class PriceRange {
  final double? min;
  final double? max;

  const PriceRange({this.min, this.max});

  bool get hasValue => min != null || max != null;

  PriceRange copyWith({double? min, double? max}) {
    return PriceRange(
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }
}

/// Bottom sheet modal for filter options
class FilterBottomSheet extends StatefulWidget {
  final List<FilterSection> sections;
  final PriceRange? priceRange;
  final Function(List<FilterSection>, PriceRange?)? onApply;
  final VoidCallback? onReset;

  const FilterBottomSheet({
    super.key,
    required this.sections,
    this.priceRange,
    this.onApply,
    this.onReset,
  });

  static Future<void> show({
    required BuildContext context,
    required List<FilterSection> sections,
    PriceRange? priceRange,
    Function(List<FilterSection>, PriceRange?)? onApply,
    VoidCallback? onReset,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        sections: sections,
        priceRange: priceRange,
        onApply: onApply,
        onReset: onReset,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late List<FilterSection> _sections;
  late PriceRange? _priceRange;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sections = widget.sections.map((section) {
      return FilterSection(
        title: section.title,
        options: section.options.map((opt) => opt.copyWith()).toList(),
        isMultiSelect: section.isMultiSelect,
      );
    }).toList();
    _priceRange = widget.priceRange;
    _minPriceController.text = _priceRange?.min?.toStringAsFixed(0) ?? '';
    _maxPriceController.text = _priceRange?.max?.toStringAsFixed(0) ?? '';
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _toggleOption(int sectionIndex, int optionIndex) {
    setState(() {
      final section = _sections[sectionIndex];
      if (section.isMultiSelect) {
        _sections[sectionIndex] = FilterSection(
          title: section.title,
          options: section.options.asMap().entries.map((entry) {
            if (entry.key == optionIndex) {
              return entry.value.copyWith(isSelected: !entry.value.isSelected);
            }
            return entry.value;
          }).toList(),
          isMultiSelect: section.isMultiSelect,
        );
      } else {
        // Single select - deselect all others
        _sections[sectionIndex] = FilterSection(
          title: section.title,
          options: section.options.asMap().entries.map((entry) {
            return entry.value.copyWith(
              isSelected: entry.key == optionIndex
                  ? !entry.value.isSelected
                  : false,
            );
          }).toList(),
          isMultiSelect: section.isMultiSelect,
        );
      }
    });
  }

  void _applyFilters() {
    // Parse price range
    final minPrice = _minPriceController.text.isEmpty
        ? null
        : double.tryParse(_minPriceController.text);
    final maxPrice = _maxPriceController.text.isEmpty
        ? null
        : double.tryParse(_maxPriceController.text);

    final priceRange = (minPrice != null || maxPrice != null)
        ? PriceRange(min: minPrice, max: maxPrice)
        : null;

    if (widget.onApply != null) {
      widget.onApply!(_sections, priceRange);
    }
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _sections = widget.sections.map((section) {
        return FilterSection(
          title: section.title,
          options: section.options.map((opt) => opt.copyWith(isSelected: false)).toList(),
          isMultiSelect: section.isMultiSelect,
        );
      }).toList();
      _priceRange = null;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
    if (widget.onReset != null) {
      widget.onReset!();
    }
  }

  int _getActiveFilterCount() {
    int count = 0;
    for (final section in _sections) {
      count += section.options.where((opt) => opt.isSelected).length;
    }
    if (_minPriceController.text.isNotEmpty || _maxPriceController.text.isNotEmpty) {
      count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? kBackgroundColorDark : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode ? (Colors.grey[400]!) : (Colors.grey[600]!);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: secondaryTextColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    if (_getActiveFilterCount() > 0)
                      TextButton(
                        onPressed: _resetFilters,
                        child: Text(
                          'Reset',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Price Range Section
                    _buildPriceRangeSection(isDarkMode, primaryTextColor, secondaryTextColor),
                    const SizedBox(height: 24),
                    // Filter Sections
                    ..._sections.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildFilterSection(
                          entry.key,
                          entry.value,
                          isDarkMode,
                          primaryTextColor,
                          secondaryTextColor,
                        ),
                      );
                    }),
                    const SizedBox(height: 100), // Space for buttons
                  ],
                ),
              ),
              // Apply Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: isDarkMode ? kBorderColorDark : kBorderColor,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetFilters,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: kPrimaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Reset',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: kPrimaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Apply Filters${_getActiveFilterCount() > 0 ? ' (${_getActiveFilterCount()})' : ''}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPriceRangeSection(
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Min Price',
                  hintText: '0',
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Price',
                  hintText: 'No limit',
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterSection(
    int sectionIndex,
    FilterSection section,
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: section.options.asMap().entries.map((entry) {
            final option = entry.value;
            return FilterChip(
              label: Text(option.label),
              selected: option.isSelected,
              onSelected: (selected) => _toggleOption(sectionIndex, entry.key),
              selectedColor: kPrimaryColorLight,
              checkmarkColor: kPrimaryColor,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: option.isSelected ? FontWeight.w600 : FontWeight.normal,
                color: option.isSelected ? kPrimaryColor : (primaryTextColor),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

