import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_cubit.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_state.dart';
import 'package:mwanachuo/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:intl/intl.dart';

class CreatePromotionScreen extends StatefulWidget {
  const CreatePromotionScreen({super.key});

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _termsController = TextEditingController();
  final _targetUrlController = TextEditingController();
  final _externalLinkController = TextEditingController();
  final _buttonTextController = TextEditingController();
  final _priorityController = TextEditingController(text: '0');
  DateTime? _startDate;
  DateTime? _endDate;
  File? _selectedImage;
  File? _selectedVideo;
  String _selectedType = 'banner';

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _termsController.dispose();
    _targetUrlController.dispose();
    _externalLinkController.dispose();
    _buttonTextController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    return BlocConsumer<PromotionCubit, PromotionState>(
      listener: (context, state) {
        if (state is PromotionError) {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to create promotion: ${state.message}',
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (state is PromotionCreated) {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Promotion created successfully!',
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: kPrimaryColor,
              duration: const Duration(seconds: 2),
            ),
          );

          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: isDarkMode
              ? kBackgroundColorDark
              : kBackgroundColorLight,
          body: ResponsiveBuilder(
            builder: (context, screenSize) {
              return Column(
                children: [
                  _buildTopAppBar(
                    context,
                    primaryTextColor,
                    secondaryTextColor,
                    screenSize,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: ResponsiveContainer(
                        child: Padding(
                          padding: EdgeInsets.all(
                            ResponsiveBreakpoints.responsiveHorizontalPadding(
                              context,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 24.0),
                                _buildTypeSelector(
                                  primaryTextColor,
                                  borderColor,
                                ),
                                const SizedBox(height: 24.0),
                                if (_selectedType == 'banner')
                                  _buildMediaUpload(
                                    label: 'Upload Promotion Banner',
                                    info: 'Tap to select an image',
                                    icon: Icons.add_photo_alternate,
                                    selectedFile: _selectedImage,
                                    onPick: _pickImage,
                                    onRemove: () =>
                                        setState(() => _selectedImage = null),
                                    primaryTextColor: primaryTextColor,
                                    secondaryTextColor: secondaryTextColor,
                                    borderColor: borderColor,
                                  )
                                else
                                  _buildMediaUpload(
                                    label: 'Upload Promotion Video',
                                    info: 'Maximum 45 seconds',
                                    icon: Icons.videocam,
                                    selectedFile: _selectedVideo,
                                    onPick: _pickVideo,
                                    onRemove: () =>
                                        setState(() => _selectedVideo = null),
                                    primaryTextColor: primaryTextColor,
                                    secondaryTextColor: secondaryTextColor,
                                    borderColor: borderColor,
                                  ),
                                const SizedBox(height: 24.0),
                                TextFormField(
                                  controller: _titleController,
                                  decoration: _buildInputDecoration(
                                    'Promotion Title',
                                    'e.g., Back to School Sale',
                                    borderColor,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a title';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20.0),
                                TextFormField(
                                  controller: _subtitleController,
                                  decoration: _buildInputDecoration(
                                    'Subtitle',
                                    'e.g., Up to 50% off on selected items',
                                    borderColor,
                                  ),
                                ),
                                const SizedBox(height: 20.0),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 4,
                                  decoration: _buildInputDecoration(
                                    'Description',
                                    'Describe your promotion...',
                                    borderColor,
                                  ),
                                ),
                                const SizedBox(height: 20.0),
                                TextFormField(
                                  controller: _termsController,
                                  maxLines: 5,
                                  decoration: _buildInputDecoration(
                                    'Terms & Conditions (one per line)',
                                    'Enter each term on a new line...',
                                    borderColor,
                                  ),
                                ),
                                const SizedBox(height: 20.0),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _targetUrlController,
                                        decoration: _buildInputDecoration(
                                          'Internal Target (Optional)',
                                          'e.g., /all-products',
                                          borderColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _externalLinkController,
                                        decoration: _buildInputDecoration(
                                          'External Link (Optional)',
                                          'https://...',
                                          borderColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        controller: _buttonTextController,
                                        decoration: _buildInputDecoration(
                                          'Button Text',
                                          'e.g., Visit',
                                          borderColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20.0),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _priorityController,
                                        keyboardType: TextInputType.number,
                                        decoration: _buildInputDecoration(
                                          'Priority',
                                          '0-100',
                                          borderColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDateField(
                                        context,
                                        'Start Date',
                                        _startDate,
                                        () => _selectDate(context, true),
                                        borderColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDateField(
                                        context,
                                        'End Date',
                                        _endDate,
                                        () => _selectDate(context, false),
                                        borderColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32.0),
                                _buildSummarySection(
                                  primaryTextColor,
                                  screenSize,
                                ),
                                const SizedBox(height: 100.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildSubmitButton(context, primaryTextColor, screenSize),
                ],
              );
            },
          ),
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(
    String label,
    String hint,
    Color borderColor,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: borderColor),
      ),
    );
  }

  Widget _buildTypeSelector(Color primaryTextColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeOption('banner', 'Banner Image', Icons.image),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTypeOption('video', 'Short Video', Icons.videocam),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(String type, String label, IconData icon) {
    bool isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(
    BuildContext context,
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        screenSize == ScreenSize.expanded ? 24.0 : 48.0,
        horizontalPadding,
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 8.0,
          medium: 12.0,
          expanded: 16.0,
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.grey[200]!,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            iconSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 24.0,
              medium: 26.0,
              expanded: 28.0,
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'Create Promotion',
              style: GoogleFonts.inter(
                color: primaryTextColor,
                fontSize: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 18.0,
                  medium: 20.0,
                  expanded: 22.0,
                ),
                fontWeight: FontWeight.bold,
                letterSpacing: -0.015,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final isDesktop =
          !kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

      if (isDesktop) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          dialogTitle: 'Select promotion banner image',
        );

        if (result != null && result.files.single.path != null) {
          if (!mounted) return;
          setState(() {
            _selectedImage = File(result.files.single.path!);
          });
        }
      } else {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        final List<AssetEntity>? result = await AssetPicker.pickAssets(
          context,
          pickerConfig: AssetPickerConfig(
            maxAssets: 1,
            requestType: RequestType.image,
            textDelegate: const EnglishAssetPickerTextDelegate(),
            pickerTheme: ThemeData(
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
              primaryColor: kPrimaryColor,
              scaffoldBackgroundColor: isDarkMode
                  ? kBackgroundColorDark
                  : Colors.white,
              appBarTheme: AppBarTheme(
                backgroundColor: isDarkMode
                    ? kBackgroundColorDark
                    : Colors.white,
                foregroundColor: isDarkMode ? Colors.white : Colors.black,
                elevation: 0,
                iconTheme: IconThemeData(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: kPrimaryColor,
                brightness: isDarkMode ? Brightness.dark : Brightness.light,
              ),
            ),
          ),
        );

        if (!mounted) return;
        if (result != null && result.isNotEmpty) {
          final File? file = await result.first.file;
          if (file != null && mounted) {
            setState(() {
              _selectedImage = file;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final isDesktop =
          !kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

      if (isDesktop) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          allowMultiple: false,
          dialogTitle: 'Select promotion video (Max 45s)',
        );

        if (result != null && result.files.single.path != null) {
          if (!mounted) return;
          setState(() {
            _selectedVideo = File(result.files.single.path!);
          });
        }
      } else {
        final List<AssetEntity>? result = await AssetPicker.pickAssets(
          context,
          pickerConfig: const AssetPickerConfig(
            maxAssets: 1,
            requestType: RequestType.video,
            textDelegate: EnglishAssetPickerTextDelegate(),
          ),
        );

        if (!mounted) return;

        if (result != null && result.isNotEmpty) {
          if (result.first.duration > 45) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video must be 45 seconds or less'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          final File? file = await result.first.file;
          if (file != null && mounted) {
            setState(() {
              _selectedVideo = file;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMediaUpload({
    required String label,
    required String info,
    required IconData icon,
    required File? selectedFile,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: 2.0,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: selectedFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_selectedType == 'banner')
                      Image.file(selectedFile, fit: BoxFit.cover)
                    else
                      Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.video_file,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                path.basename(selectedFile.path),
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: onRemove,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 48.0, color: secondaryTextColor),
                    const SizedBox(height: 12.0),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        color: primaryTextColor,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      info,
                      style: GoogleFonts.plusJakartaSans(
                        color: secondaryTextColor,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? date,
    VoidCallback onTap,
    Color borderColor,
  ) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: borderColor),
          ),
        ),
        child: Text(
          date != null
              ? '${date.day}/${date.month}/${date.year}'
              : 'Select date',
          style: GoogleFonts.plusJakartaSans(fontSize: 14.0),
        ),
      ),
    );
  }

  Widget _buildSummarySection(Color primaryTextColor, ScreenSize screenSize) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        if (_startDate == null || _endDate == null) {
          return const SizedBox.shrink();
        }

        final duration = _endDate!.difference(_startDate!).inDays + 1;
        final authState = context.read<AuthBloc>().state;
        final isAdmin =
            authState is Authenticated && authState.user.role.value == 'admin';

        final totalCost = isAdmin
            ? 0.0
            : duration * DatabaseConstants.promotionPricePerDay;
        double? currentBalance;

        if (state is WalletLoaded) {
          currentBalance = state.wallet.balance;
        }

        final currencyFormatter = NumberFormat.currency(
          symbol: 'TZS ',
          decimalDigits: 0,
        );

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(51),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Promotion Summary',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              _buildSummaryRow('Duration', '$duration days', primaryTextColor),
              const SizedBox(height: 8.0),
              _buildSummaryRow(
                'Price per day',
                isAdmin
                    ? 'Free (Admin)'
                    : currencyFormatter.format(
                        DatabaseConstants.promotionPricePerDay,
                      ),
                primaryTextColor,
              ),
              const Divider(height: 24.0),
              _buildSummaryRow(
                'Total Cost',
                currencyFormatter.format(totalCost),
                primaryTextColor,
                isTotal: true,
              ),
              if (!isAdmin && currentBalance != null) ...[
                const SizedBox(height: 16.0),
                _buildSummaryRow(
                  'Your Balance',
                  currencyFormatter.format(currentBalance),
                  currentBalance < totalCost ? Colors.red : Colors.green,
                ),
                if (currentBalance < totalCost)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Insufficient balance. Please top up your wallet.',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    Color textColor, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor.withAlpha(178),
            fontSize: isTotal ? 16.0 : 14.0,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: isTotal ? 16.0 : 14.0,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    Color primaryTextColor,
    ScreenSize screenSize,
  ) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, walletState) {
        final duration = (_startDate != null && _endDate != null)
            ? _endDate!.difference(_startDate!).inDays + 1
            : 0;
        final totalCost =
            (duration > 0 ? duration : 0) *
            DatabaseConstants.promotionPricePerDay;
        bool hasSufficientBalance = true;

        if (walletState is WalletLoaded) {
          hasSufficientBalance = walletState.wallet.balance >= totalCost;
        }

        return Container(
          padding: EdgeInsets.all(
            ResponsiveBreakpoints.responsiveHorizontalPadding(context),
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]!
                    : Colors.grey[200]!,
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48.0,
                  child: ElevatedButton(
                    onPressed: () async {
                      final authState = context.read<AuthBloc>().state;
                      final isAdmin =
                          authState is Authenticated &&
                          authState.user.role.value == 'admin';

                      if (!hasSufficientBalance && !isAdmin) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Insufficient balance to create promotion',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (_formKey.currentState!.validate()) {
                        if (_selectedImage == null && _selectedVideo == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select an image or video'),
                            ),
                          );
                          return;
                        }

                        if (_startDate == null || _endDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select both start and end dates',
                              ),
                            ),
                          );
                          return;
                        }

                        String? userId;
                        if (authState is Authenticated) {
                          userId = authState.user.id;
                        }

                        // Show confirmation
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Promotion'),
                            content: Text(
                              isAdmin
                                  ? 'Admins can create promotions for free.'
                                  : 'A fee of ${NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0).format(totalCost)} will be deducted from your wallet.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Confirm & Create'),
                              ),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        // Show loading indicator
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(
                              color: kPrimaryColor,
                            ),
                          ),
                        );

                        if (!context.mounted) return;
                        await context.read<PromotionCubit>().createNewPromotion(
                          title: _titleController.text.trim(),
                          subtitle: _subtitleController.text.trim(),
                          description: _descriptionController.text.trim(),
                          startDate: _startDate!,
                          endDate: _endDate!,
                          image: _selectedImage,
                          video: _selectedVideo,
                          type: _selectedType,
                          priority: int.tryParse(_priorityController.text) ?? 0,
                          buttonText:
                              _buttonTextController.text.trim().isNotEmpty
                              ? _buttonTextController.text.trim()
                              : 'Visit',
                          targetUrl: _targetUrlController.text.trim(),
                          externalLink: _externalLinkController.text.trim(),
                          userId: userId,
                          terms: _termsController.text.trim().isNotEmpty
                              ? _termsController.text
                                    .trim()
                                    .split('\n')
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList()
                              : null,
                        );

                        if (context.mounted && Navigator.canPop(context)) {
                          Navigator.pop(context); // Close loading indicator
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[400],
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      elevation: 0,
                    ),
                    child: BlocBuilder<PromotionCubit, PromotionState>(
                      builder: (context, state) {
                        if (state is PromotionsLoading) {
                          return const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          );
                        }
                        return const Text(
                          'Create Promotion',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
