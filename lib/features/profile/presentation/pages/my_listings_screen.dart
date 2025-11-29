import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_bloc.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_event.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_state.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_bloc.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_event.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_state.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_bloc.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_event.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_state.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_entity.dart';
import 'package:mwanachuo/features/accommodations/presentation/pages/edit_accommodation_screen.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';
import 'package:mwanachuo/features/products/presentation/pages/edit_product_screen.dart';
import 'package:mwanachuo/features/services/domain/entities/service_entity.dart';
import 'package:mwanachuo/features/services/presentation/pages/edit_service_screen.dart';
import 'package:mwanachuo/config/supabase_config.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              sl<ProductBloc>()..add(const LoadProductsEvent(limit: 100)),
        ),
        BlocProvider(
          create: (context) =>
              sl<ServiceBloc>()..add(const LoadServicesEvent(limit: 100)),
        ),
        BlocProvider(
          create: (context) =>
              sl<AccommodationBloc>()
                ..add(const LoadAccommodationsEvent(limit: 100)),
        ),
      ],
      child: const _MyListingsView(),
    );
  }
}

class _MyListingsView extends StatefulWidget {
  const _MyListingsView();

  @override
  State<_MyListingsView> createState() => _MyListingsViewState();
}

class _MyListingsViewState extends State<_MyListingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Listings',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kPrimaryColor,
          labelColor: kPrimaryColor,
          unselectedLabelColor: secondaryTextColor,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Services'),
            Tab(text: 'Accommodations'),
          ],
        ),
      ),
      backgroundColor: isDarkMode
          ? kBackgroundColorDark
          : kBackgroundColorLight,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(isDarkMode, primaryTextColor, secondaryTextColor),
          _buildServicesTab(isDarkMode, primaryTextColor, secondaryTextColor),
          _buildAccommodationsTab(
            isDarkMode,
            primaryTextColor,
            secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          );
        }

        if (state is ProductError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: secondaryTextColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<ProductBloc>().add(
                      const LoadProductsEvent(limit: 100),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: kBackgroundColorDark,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is ProductsLoaded) {
          final currentUserId =
              SupabaseConfig.client.auth.currentUser?.id ?? '';
          final myProducts = state.products
              .where((p) => p.sellerId == currentUserId)
              .toList();

          if (myProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products listed yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start selling by posting your first product',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/post-product'),
                    icon: const Icon(Icons.add),
                    label: const Text('Post Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: kBackgroundColorDark,
                    ),
                  ),
                ],
              ),
            );
          }

          return BlocListener<ProductBloc, ProductState>(
            listener: (context, state) {
              if (state is ProductDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted successfully!'),
                    backgroundColor: kPrimaryColor,
                  ),
                );
                // Reload products
                context.read<ProductBloc>().add(
                  const LoadProductsEvent(limit: 100),
                );
              } else if (state is ProductError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myProducts.length,
              itemBuilder: (context, index) {
                final product = myProducts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/product-details',
                          arguments: product.id,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: NetworkImageWithFallback(
                            imageUrl: product.images.isNotEmpty
                                ? product.images.first
                                : '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          product.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'TZS ${product.price.toStringAsFixed(2)} • ${product.category}',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: product.isActive
                                    ? kPrimaryColor.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.isActive ? 'Active' : 'Inactive',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: product.isActive
                                      ? kPrimaryColor
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 12,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${product.viewCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        _buildEditProductScreen(product),
                                  ),
                                );
                                if (result == true) {
                                  // Reload products if edit was successful
                                  if (context.mounted) {
                                    context.read<ProductBloc>().add(
                                      const LoadProductsEvent(limit: 100),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(
                                foregroundColor: kPrimaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _showDeleteProductConfirmation(
                                context,
                                product.id,
                                product.title,
                              ),
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildServicesTab(
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return BlocBuilder<ServiceBloc, ServiceState>(
      builder: (context, state) {
        if (state is ServicesLoading) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          );
        }

        if (state is ServiceError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: secondaryTextColor),
                ),
              ],
            ),
          );
        }

        if (state is ServicesLoaded) {
          final currentUserId =
              SupabaseConfig.client.auth.currentUser?.id ?? '';
          final myServices = state.services
              .where((s) => s.providerId == currentUserId)
              .toList();

          if (myServices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.build_outlined,
                    size: 64,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No services listed yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Offer your services to other students',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/create-service'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: kBackgroundColorDark,
                    ),
                  ),
                ],
              ),
            );
          }

          return BlocListener<ServiceBloc, ServiceState>(
            listener: (context, state) {
              if (state is ServiceDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Service deleted successfully!'),
                    backgroundColor: kPrimaryColor,
                  ),
                );
                // Reload services
                context.read<ServiceBloc>().add(
                  const LoadServicesEvent(limit: 100),
                );
              } else if (state is ServiceError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myServices.length,
              itemBuilder: (context, index) {
                final service = myServices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/service-details',
                          arguments: service.id,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: NetworkImageWithFallback(
                            imageUrl: service.images.isNotEmpty
                                ? service.images.first
                                : '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          service.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'TZS ${service.price.toStringAsFixed(2)}/${service.priceType}',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: service.isActive
                                    ? kPrimaryColor.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                service.isActive ? 'Active' : 'Inactive',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: service.isActive
                                      ? kPrimaryColor
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 12,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${service.viewCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        _buildEditServiceScreen(service),
                                  ),
                                );
                                if (result == true) {
                                  // Reload services if edit was successful
                                  if (context.mounted) {
                                    context.read<ServiceBloc>().add(
                                      const LoadServicesEvent(limit: 100),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(
                                foregroundColor: kPrimaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _showDeleteServiceConfirmation(
                                context,
                                service.id,
                                service.title,
                              ),
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAccommodationsTab(
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return BlocBuilder<AccommodationBloc, AccommodationState>(
      builder: (context, state) {
        if (state is AccommodationsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          );
        }

        if (state is AccommodationError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: secondaryTextColor),
                ),
              ],
            ),
          );
        }

        if (state is AccommodationsLoaded) {
          final currentUserId =
              SupabaseConfig.client.auth.currentUser?.id ?? '';
          final myAccommodations = state.accommodations
              .where((a) => a.ownerId == currentUserId)
              .toList();

          if (myAccommodations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 64,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No accommodations listed yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'List student housing to help others',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/create-accommodation'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Accommodation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: kBackgroundColorDark,
                    ),
                  ),
                ],
              ),
            );
          }

          return BlocListener<AccommodationBloc, AccommodationState>(
            listener: (context, state) {
              if (state is AccommodationDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Accommodation deleted successfully!'),
                    backgroundColor: kPrimaryColor,
                  ),
                );
                // Reload accommodations
                context.read<AccommodationBloc>().add(
                  const LoadAccommodationsEvent(limit: 100),
                );
              } else if (state is AccommodationError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myAccommodations.length,
              itemBuilder: (context, index) {
                final accommodation = myAccommodations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/accommodation-details',
                          arguments: accommodation.id,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: NetworkImageWithFallback(
                            imageUrl: accommodation.images.isNotEmpty
                                ? accommodation.images.first
                                : '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          accommodation.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'TZS ${accommodation.price.toStringAsFixed(2)}/${accommodation.priceType} • ${accommodation.roomType}',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accommodation.isActive
                                    ? kPrimaryColor.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                accommodation.isActive ? 'Active' : 'Inactive',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: accommodation.isActive
                                      ? kPrimaryColor
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 12,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${accommodation.viewCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        _buildEditAccommodationScreen(
                                          accommodation,
                                        ),
                                  ),
                                );
                                if (result == true) {
                                  // Reload accommodations if edit was successful
                                  if (context.mounted) {
                                    context.read<AccommodationBloc>().add(
                                      const LoadAccommodationsEvent(limit: 100),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(
                                foregroundColor: kPrimaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _showDeleteConfirmation(
                                context,
                                accommodation.id,
                                accommodation.name,
                              ),
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEditAccommodationScreen(AccommodationEntity accommodation) {
    return EditAccommodationScreen(accommodation: accommodation);
  }

  Widget _buildEditProductScreen(ProductEntity product) {
    return EditProductScreen(product: product);
  }

  Widget _buildEditServiceScreen(ServiceEntity service) {
    return EditServiceScreen(service: service);
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String accommodationId,
    String accommodationName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Accommodation'),
        content: Text(
          'Are you sure you want to delete "$accommodationName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AccommodationBloc>().add(
                DeleteAccommodationEvent(accommodationId: accommodationId),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteProductConfirmation(
    BuildContext context,
    String productId,
    String productTitle,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "$productTitle"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ProductBloc>().add(
                DeleteProductEvent(productId: productId),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteServiceConfirmation(
    BuildContext context,
    String serviceId,
    String serviceTitle,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text(
          'Are you sure you want to delete "$serviceTitle"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ServiceBloc>().add(
                DeleteServiceEvent(serviceId: serviceId),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
