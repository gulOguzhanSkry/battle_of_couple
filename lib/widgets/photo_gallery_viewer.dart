import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/constants/app_strings.dart';

/// Fotoğraf galerisi görüntüleyici - Swipe ile gezinme
class PhotoGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? title;

  const PhotoGalleryViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.title,
  });

  /// Galeriyi modal olarak açar
  static void show(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String? title,
  }) {
    if (imageUrls.isEmpty) return;
    
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return PhotoGalleryViewer(
            imageUrls: imageUrls,
            initialIndex: initialIndex,
            title: title,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<PhotoGalleryViewer> createState() => _PhotoGalleryViewerState();
}

class _PhotoGalleryViewerState extends State<PhotoGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Fotoğraf PageView
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        widget.imageUrls[index],
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                              color: AppTheme.primaryColor,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.broken_image_rounded,
                                    size: 64, color: Colors.white54),
                                const SizedBox(height: 8),
                                Text(AppStrings.photoLoadFailed,
                                    style: const TextStyle(color: Colors.white54)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            // Üst bar - Başlık ve Kapat butonu
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 8),
                    if (widget.title != null)
                      Expanded(
                        child: Text(
                          widget.title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const Spacer(),
                    // Fotoğraf sayısı
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Alt sayfa göstergeleri
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.imageUrls.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? AppTheme.primaryColor
                            : Colors.white54,
                        borderRadius: BorderRadius.circular(4),
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

/// Fotoğraf thumbnail'ı - Kart içinde kullanılır
class PhotoThumbnail extends StatelessWidget {
  final List<String> imageUrls;
  final double height;
  final BorderRadius? borderRadius;

  const PhotoThumbnail({
    super.key,
    required this.imageUrls,
    this.height = 120,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return _buildPlaceholder();
    }

    return GestureDetector(
      onTap: () => PhotoGalleryViewer.show(context, imageUrls: imageUrls),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            child: Image.network(
              imageUrls.first,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: height,
                  color: AppTheme.backgroundColor,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
            ),
          ),
          // Fotoğraf sayısı badge
          if (imageUrls.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.image_rounded,
          size: 48,
          color: AppTheme.textLightColor,
        ),
      ),
    );
  }
}
