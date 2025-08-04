import 'package:flutter/material.dart';
import 'dart:io';

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
    return Image.network(
      widget.imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: widget.cacheWidth.toInt(),
      cacheHeight: widget.cacheHeight.toInt(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget();
      },
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