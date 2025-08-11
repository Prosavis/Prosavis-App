import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Administrador de cache personalizado para controlar el tamaño y periodo de validez
final CacheManager _customCacheManager = CacheManager(
  Config(
    'optimizedImageCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 100,
  ),
);

/// Widget optimizado para mostrar imágenes con cache y manejo de errores
/// Previene reconstrucciones innecesarias y mejora el rendimiento
class OptimizedImage extends StatefulWidget {
  final String? imageUrl;
  final String? localPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final double cacheWidth;
  final double cacheHeight;

  const OptimizedImage({
    super.key,
    this.imageUrl,
    this.localPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.cacheWidth = 400,
    this.cacheHeight = 400,
  });

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Mantener estado para evitar reconstrucciones

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por AutomaticKeepAliveClientMixin

    Widget imageWidget = _buildImageWidget();
    
    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: imageWidget,
    );
  }

  Widget _buildImageWidget() {
    // Prioridad: URL de red > archivo local > placeholder
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      if (widget.imageUrl!.startsWith('http')) {
        return _buildNetworkImage();
      } else {
        return _buildFileImage(widget.imageUrl!);
      }
    } else if (widget.localPath != null && widget.localPath!.isNotEmpty) {
      return _buildFileImage(widget.localPath!);
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildNetworkImage() {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
      cacheManager: _customCacheManager,
      memCacheWidth: widget.cacheWidth.toInt(),
      memCacheHeight: widget.cacheHeight.toInt(),
    );
  }

  Widget _buildFileImage(String path) {
    return Image.file(
      File(path),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: widget.cacheWidth.toInt(),
      cacheHeight: widget.cacheHeight.toInt(),
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ?? 
      Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: const Icon(
          Icons.image,
          color: Colors.grey,
        ),
      );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ?? 
      Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: const Icon(
          Icons.broken_image,
          color: Colors.grey,
        ),
      );
  }
}