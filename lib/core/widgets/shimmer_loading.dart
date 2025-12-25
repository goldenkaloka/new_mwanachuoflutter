import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';

/// A base shimmer loading widget with consistent styling
///
/// Provides a skeleton loader with shimmer animation effect.
///
/// Example:
/// ```dart
/// ShimmerLoading(
///   width: double.infinity,
///   height: 160,
/// )
/// ```
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      highlightColor: isDarkMode
          ? const Color(0xFF3A3A3A)
          : const Color(0xFFF5F5F5),
      period: kAnimationSlow,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(kRadiusMd),
        ),
      ),
    );
  }
}

/// Product card skeleton loader
///
/// A shimmer placeholder for product cards while loading.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image skeleton
        const AspectRatio(
          aspectRatio: 0.7,
          child: ShimmerLoading(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.all(Radius.circular(kRadiusSm)),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title skeleton
              const ShimmerLoading(width: double.infinity, height: 12),
              const SizedBox(height: 2),
              // Price skeleton
              ShimmerLoading(
                width: 60,
                height: 12,
                borderRadius: BorderRadius.circular(kRadiusSm),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Service card skeleton loader
///
/// A shimmer placeholder for service cards while loading.
class ServiceCardSkeleton extends StatelessWidget {
  const ServiceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          const ShimmerLoading(width: 90, height: 90),
          const SizedBox(width: kSpacingMd),

          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                const ShimmerLoading(width: double.infinity, height: 16),
                const SizedBox(height: kSpacingSm),
                // Category skeleton
                ShimmerLoading(
                  width: 100,
                  height: 14,
                  borderRadius: BorderRadius.circular(kRadiusSm),
                ),
                const SizedBox(height: kSpacingSm),
                // Price skeleton
                ShimmerLoading(
                  width: 120,
                  height: 16,
                  borderRadius: BorderRadius.circular(kRadiusSm),
                ),
                const SizedBox(height: kSpacingSm),
                // Provider info skeleton
                Row(
                  children: [
                    ShimmerLoading(
                      width: 80,
                      height: 14,
                      borderRadius: BorderRadius.circular(kRadiusSm),
                    ),
                    const SizedBox(width: kSpacingMd),
                    ShimmerLoading(
                      width: 80,
                      height: 14,
                      borderRadius: BorderRadius.circular(kRadiusSm),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// List item skeleton loader
///
/// A shimmer placeholder for list items while loading.
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingLg,
        vertical: kSpacingMd,
      ),
      child: Row(
        children: [
          // Avatar skeleton
          ShimmerLoading(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(kRadiusFull),
          ),
          const SizedBox(width: kSpacingMd),

          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                const ShimmerLoading(width: double.infinity, height: 16),
                const SizedBox(height: kSpacingSm),
                // Subtitle skeleton
                ShimmerLoading(
                  width: 150,
                  height: 14,
                  borderRadius: BorderRadius.circular(kRadiusSm),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of product card skeletons
///
/// Displays multiple product card skeletons in a grid layout.
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const ProductGridSkeleton({
    super.key,
    this.itemCount = 9,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
      itemCount: itemCount,
      padding: const EdgeInsets.all(0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => const ProductCardSkeleton(),
    );
  }
}

/// List of skeletons
///
/// Displays multiple skeleton items in a list layout.
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int)? itemBuilder;

  const ListSkeleton({super.key, this.itemCount = 5, this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: itemBuilder ?? (context, index) => const ListItemSkeleton(),
    );
  }
}

/// Profile header skeleton
///
/// A shimmer placeholder for profile headers.
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar skeleton
        ShimmerLoading(
          width: 100,
          height: 100,
          borderRadius: BorderRadius.circular(kRadiusFull),
        ),
        const SizedBox(height: kSpacingLg),

        // Name skeleton
        ShimmerLoading(
          width: 200,
          height: 24,
          borderRadius: BorderRadius.circular(kRadiusSm),
        ),
        const SizedBox(height: kSpacingSm),

        // Email skeleton
        ShimmerLoading(
          width: 150,
          height: 16,
          borderRadius: BorderRadius.circular(kRadiusSm),
        ),
        const SizedBox(height: kSpacingLg),

        // Stats skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ShimmerLoading(
              width: 80,
              height: 40,
              borderRadius: BorderRadius.circular(kRadiusSm),
            ),
            ShimmerLoading(
              width: 80,
              height: 40,
              borderRadius: BorderRadius.circular(kRadiusSm),
            ),
            ShimmerLoading(
              width: 80,
              height: 40,
              borderRadius: BorderRadius.circular(kRadiusSm),
            ),
          ],
        ),
      ],
    );
  }
}

/// Detail page skeleton
///
/// A shimmer placeholder for detail pages (product, service, accommodation).
class DetailPageSkeleton extends StatelessWidget {
  const DetailPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image carousel skeleton
          const ShimmerLoading(width: double.infinity, height: 300),
          const SizedBox(height: kSpacingLg),

          // Title skeleton
          const ShimmerLoading(width: double.infinity, height: 24),
          const SizedBox(height: kSpacingMd),

          // Price skeleton
          ShimmerLoading(
            width: 150,
            height: 28,
            borderRadius: BorderRadius.circular(kRadiusSm),
          ),
          const SizedBox(height: kSpacingLg),

          // Description skeleton
          Column(
            children: List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: kSpacingSm),
                child: ShimmerLoading(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(kRadiusSm),
                ),
              ),
            ),
          ),
          const SizedBox(height: kSpacingLg),

          // Features skeleton
          Row(
            children: [
              ShimmerLoading(
                width: 100,
                height: 32,
                borderRadius: BorderRadius.circular(kRadiusFull),
              ),
              const SizedBox(width: kSpacingMd),
              ShimmerLoading(
                width: 100,
                height: 32,
                borderRadius: BorderRadius.circular(kRadiusFull),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chat conversation skeleton
///
/// A shimmer placeholder for conversation lists.
class ConversationSkeleton extends StatelessWidget {
  const ConversationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingLg,
        vertical: kSpacingMd,
      ),
      child: Row(
        children: [
          // Avatar
          ShimmerLoading(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(kRadiusFull),
          ),
          const SizedBox(width: kSpacingMd),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                const ShimmerLoading(width: double.infinity, height: 16),
                const SizedBox(height: kSpacingXs),
                // Message preview
                ShimmerLoading(
                  width: 200,
                  height: 14,
                  borderRadius: BorderRadius.circular(kRadiusSm),
                ),
              ],
            ),
          ),

          // Time & badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShimmerLoading(
                width: 40,
                height: 12,
                borderRadius: BorderRadius.circular(kRadiusSm),
              ),
              const SizedBox(height: kSpacingXs),
              ShimmerLoading(
                width: 20,
                height: 20,
                borderRadius: BorderRadius.circular(kRadiusFull),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dashboard skeleton loader
///
/// A shimmer placeholder for the seller dashboard.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const ShimmerLoading(width: 150, height: 24),
          const SizedBox(height: kSpacingMd),

          // Recent Activity Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ShimmerLoading(
                        width: 40,
                        height: 40,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerLoading(width: 120, height: 16),
                            SizedBox(height: 4),
                            ShimmerLoading(width: 180, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: kSpacingLg),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoading(width: 120, height: 20),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    3,
                    (index) => const Column(
                      children: [
                        ShimmerLoading(width: 40, height: 28),
                        SizedBox(height: 8),
                        ShimmerLoading(width: 60, height: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const ShimmerLoading(width: double.infinity, height: 48),
              ],
            ),
          ),

          const SizedBox(height: kSpacingLg),

          // Quick Actions Row
          Row(
            children: [
              Expanded(
                child: ShimmerLoading(
                  width: double.infinity,
                  height: 60,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShimmerLoading(
                  width: double.infinity,
                  height: 60,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ShimmerLoading(
                  width: double.infinity,
                  height: 60,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShimmerLoading(
                  width: double.infinity,
                  height: 60,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full Profile Page Skeleton
class ProfilePageSkeleton extends StatelessWidget {
  const ProfilePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: kSpacingMd),
      child: Column(
        children: [
          const SizedBox(height: 48), // Top padding
          // Profile Header Part
          Center(
            child: Column(
              children: [
                ShimmerLoading(
                  width: 120,
                  height: 120,
                  borderRadius: BorderRadius.circular(kRadiusFull),
                ),
                const SizedBox(height: kSpacingLg),
                ShimmerLoading(
                  width: 200,
                  height: 24,
                  borderRadius: BorderRadius.circular(kRadiusSm),
                ),
                const SizedBox(height: kSpacingSm),
                ShimmerLoading(
                  width: 150,
                  height: 16,
                  borderRadius: BorderRadius.circular(kRadiusSm),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Menu Items
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      ShimmerLoading(
                        width: 40,
                        height: 40,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: ShimmerLoading(
                          width: double.infinity,
                          height: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ShimmerLoading(
                        width: 24,
                        height: 24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Logout Button
          ShimmerLoading(
            width: double.infinity,
            height: 48,
            borderRadius: BorderRadius.circular(24),
          ),
        ],
      ),
    );
  }
}
