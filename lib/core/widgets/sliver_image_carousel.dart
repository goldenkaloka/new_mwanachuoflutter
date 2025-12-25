import 'package:flutter/material.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';

/// Sliver widget for displaying an image carousel with parallax effect
/// Uses SliverToBoxAdapter instead of SliverAppBar to avoid gesture conflicts
class SliverImageCarousel extends StatefulWidget {
  final List<String> images;
  final double expandedHeight;
  final VoidCallback? onImageTap;
  final String? heroTagPrefix;

  const SliverImageCarousel({
    super.key,
    required this.images,
    this.expandedHeight = 400,
    this.onImageTap,
    this.heroTagPrefix,
  });

  @override
  State<SliverImageCarousel> createState() => _SliverImageCarouselState();
}

class _SliverImageCarouselState extends State<SliverImageCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isNotEmpty ? widget.images : [''];

    return SliverToBoxAdapter(
      child: SizedBox(
        height: widget.expandedHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image carousel - PageView that can properly handle horizontal swipes
            // PageScrollPhysics is optimized for PageView horizontal scrolling
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              physics: const PageScrollPhysics(), // Optimized for PageView
              scrollDirection: Axis.horizontal,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: widget.onImageTap,
                  child: Hero(
                    tag: index == 0 && widget.heroTagPrefix != null
                        ? widget.heroTagPrefix!
                        : 'carousel_${widget.heroTagPrefix ?? 'image'}_$index',
                    child: NetworkImageWithFallback(
                      imageUrl: images[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
            // Gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
            // Page indicators
            if (images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
