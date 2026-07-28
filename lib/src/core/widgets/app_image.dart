import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gokul_shree_app/src/core/theme/app_theme.dart';

/// Lightweight image loading helper
/// Uses cached images to reduce data usage and improve performance
class AppImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const AppImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    // Handle base64 images
    if (imageUrl!.startsWith('data:image')) {
      return _buildBase64Image();
    }

    // Handle network images with caching
    if (imageUrl!.startsWith('http')) {
      return _buildCachedNetworkImage();
    }

    // Fallback to placeholder
    return _buildPlaceholder();
  }

  Widget _buildCachedNetworkImage() {
    final image = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildPlaceholder(),
      // Use memory cache for faster loading
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      // Fade in animation
      fadeInDuration: const Duration(milliseconds: 300),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _buildBase64Image() {
    try {
      final base64String = imageUrl!.split(',').last;
      return Image.memory(
        Uri.parse('data:image/png;base64,$base64String').data!.contentAsBytes(),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } catch (e) {
      return _buildPlaceholder();
    }
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppTheme.primaryColor,
          size: 48,
        ),
      ),
    );
  }
}

/// Category-specific icons and colors for courses
class CourseImageHelper {
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'diploma':
        return Icons.computer;
      case 'vocational':
        return Icons.build_outlined;
      case 'university':
        return Icons.school_outlined;
      case 'yoga':
        return Icons.self_improvement;
      default:
        return Icons.book_outlined;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'diploma':
        return Colors.blue;
      case 'vocational':
        return Colors.orange;
      case 'university':
        return Colors.purple;
      case 'yoga':
        return Colors.green;
      default:
        return AppTheme.primaryColor;
    }
  }

  static LinearGradient getCategoryGradient(String category) {
    final color = getCategoryColor(category);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
    );
  }
}

/// Course card image with category fallback
class CourseImage extends StatelessWidget {
  final String? imageUrl;
  final String category;
  final double height;
  final BorderRadius? borderRadius;

  const CourseImage({
    super.key,
    this.imageUrl,
    required this.category,
    this.height = 120,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // If we have a valid image URL, use cached network image
    if (imageUrl != null && imageUrl!.startsWith('http')) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildCategoryPlaceholder(),
          errorWidget: (context, url, error) => _buildCategoryPlaceholder(),
        ),
      );
    }

    // Use category-based placeholder
    return _buildCategoryPlaceholder();
  }

  Widget _buildCategoryPlaceholder() {
    final icon = CourseImageHelper.getCategoryIcon(category);
    final gradient = CourseImageHelper.getCategoryGradient(category);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(gradient: gradient, borderRadius: borderRadius),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 48),
          const SizedBox(height: 8),
          Text(
            category,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
