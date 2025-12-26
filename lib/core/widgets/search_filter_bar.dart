import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/debouncer.dart';

/// Reusable search bar with filter icon and debounced input
class SearchFilterBar extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterPressed;
  final int activeFilterCount;
  final TextEditingController? controller;
  final bool showFilterButton;

  const SearchFilterBar({
    super.key,
    this.hintText,
    this.onSearchChanged,
    this.onFilterPressed,
    this.activeFilterCount = 0,
    this.controller,
    this.showFilterButton = true,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late TextEditingController _controller;
  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 400),
  );
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    _debouncer.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    // Debounce search callback
    if (widget.onSearchChanged != null) {
      _debouncer.call(() {
        widget.onSearchChanged!(_controller.text);
      });
    }
  }

  void _clearSearch() {
    _controller.clear();
    if (widget.onSearchChanged != null) {
      widget.onSearchChanged!('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDarkMode ? Colors.grey[500] : Colors.grey[600];
    final fillColor = isDarkMode ? Colors.grey[900] : Colors.grey[100];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.plusJakartaSans(
                color: isDarkMode ? Colors.white : kTextPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Search...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: hintColor,
                  fontSize: 16,
                ),
                prefixIcon: Icon(Icons.search, color: hintColor, size: 24),
                suffixIcon: _hasText
                    ? IconButton(
                        icon: Icon(Icons.clear, color: hintColor, size: 20),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999.0),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999.0),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999.0),
                  borderSide: const BorderSide(
                    color: kPrimaryColor,
                    width: 2.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ),
          if (widget.showFilterButton) ...[
            const SizedBox(width: 8),
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(999.0),
                    border: Border.all(
                      color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: widget.activeFilterCount > 0
                          ? kPrimaryColor
                          : hintColor,
                    ),
                    onPressed: widget.onFilterPressed,
                    tooltip: 'Filters',
                  ),
                ),
                if (widget.activeFilterCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        widget.activeFilterCount > 9
                            ? '9+'
                            : widget.activeFilterCount.toString(),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
