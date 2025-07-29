import 'package:flutter/material.dart';
import '../../../core/constants/brand_constants.dart';

/// Widget reutilizable para mostrar el logo de Prosavis
/// Permite diferentes variaciones y tamaños del logo
class ProsavisLogo extends StatelessWidget {
  /// Altura del logo
  final double? height;
  
  /// Ancho del logo
  final double? width;
  
  /// Tipo de logo a mostrar
  final ProsavisLogoType type;
  
  /// Si debe adaptar automáticamente al tema
  final bool adaptive;
  
  /// Ajuste de la imagen
  final BoxFit fit;

  const ProsavisLogo({
    super.key,
    this.height,
    this.width,
    this.type = ProsavisLogoType.color,
    this.adaptive = true,
    this.fit = BoxFit.contain,
  });

  /// Constructor para logo pequeño (32px)
  const ProsavisLogo.small({
    super.key,
    this.type = ProsavisLogoType.color,
    this.adaptive = true,
    this.fit = BoxFit.contain,
  }) : height = 32.0, width = null;

  /// Constructor para logo mediano (48px)
  const ProsavisLogo.medium({
    super.key,
    this.type = ProsavisLogoType.color,
    this.adaptive = true,
    this.fit = BoxFit.contain,
  }) : height = 48.0, width = null;

  /// Constructor para logo grande (80px)
  const ProsavisLogo.large({
    super.key,
    this.type = ProsavisLogoType.color,
    this.adaptive = true,
    this.fit = BoxFit.contain,
  }) : height = 80.0, width = null;

  /// Constructor para logo extra grande (120px)
  const ProsavisLogo.extraLarge({
    super.key,
    this.type = ProsavisLogoType.color,
    this.adaptive = true,
    this.fit = BoxFit.contain,
  }) : height = 120.0, width = null;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final logoPath = _getLogoPath(brightness);

    return Image.asset(
      logoPath,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback en caso de error al cargar la imagen
        return Container(
          height: height ?? 48,
          width: width,
          decoration: BoxDecoration(
            color: BrandConstants.primaryColor,
            borderRadius: BorderRadius.circular(BrandConstants.radiusMd),
          ),
          child: const Icon(
            Icons.business,
            color: BrandConstants.textLight,
          ),
        );
      },
    );
  }

  /// Obtiene la ruta del logo según el tipo y tema
  String _getLogoPath(Brightness brightness) {
    if (adaptive && type == ProsavisLogoType.color) {
      return BrandConstants.getLogoForTheme(brightness);
    }

    switch (type) {
      case ProsavisLogoType.color:
        return BrandConstants.logoColor;
      case ProsavisLogoType.grayscale:
        return BrandConstants.logoGrayscale;
      case ProsavisLogoType.grayscaleInverted:
        return BrandConstants.logoGrayscaleInverted;
      case ProsavisLogoType.noBackground:
        return BrandConstants.logoNoBackground;
    }
  }
}

/// Tipos de logo disponibles
enum ProsavisLogoType {
  /// Logo en color completo
  color,
  
  /// Logo en escala de grises
  grayscale,
  
  /// Logo en escala de grises invertido
  grayscaleInverted,
  
  /// Logo sin fondo
  noBackground,
}

/// Widget que combina el logo con el nombre de la marca
class ProsavisBrand extends StatelessWidget {
  /// Altura del logo
  final double? logoHeight;
  
  /// Tamaño del texto
  final double? textSize;
  
  /// Tipo de logo
  final ProsavisLogoType logoType;
  
  /// Si debe ser horizontal o vertical
  final Axis direction;
  
  /// Espaciado entre logo y texto
  final double spacing;
  
  /// Si debe adaptar al tema
  final bool adaptive;

  const ProsavisBrand({
    super.key,
    this.logoHeight,
    this.textSize,
    this.logoType = ProsavisLogoType.color,
    this.direction = Axis.horizontal,
    this.spacing = BrandConstants.spaceMd,
    this.adaptive = true,
  });

  /// Constructor para marca compacta
  const ProsavisBrand.compact({
    super.key,
    this.logoType = ProsavisLogoType.color,
    this.direction = Axis.horizontal,
    this.adaptive = true,
  }) : logoHeight = 32.0, textSize = 18.0, spacing = BrandConstants.spaceSm;

  /// Constructor para marca estándar
  const ProsavisBrand.standard({
    super.key,
    this.logoType = ProsavisLogoType.color,
    this.direction = Axis.horizontal,
    this.adaptive = true,
  }) : logoHeight = 48.0, textSize = 24.0, spacing = BrandConstants.spaceMd;

  /// Constructor para marca prominente
  const ProsavisBrand.prominent({
    super.key,
    this.logoType = ProsavisLogoType.color,
    this.direction = Axis.vertical,
    this.adaptive = true,
  }) : logoHeight = 80.0, textSize = 32.0, spacing = BrandConstants.spaceLg;

  @override
  Widget build(BuildContext context) {
    final logo = ProsavisLogo(
      height: logoHeight ?? 48.0,
      type: logoType,
      adaptive: adaptive,
    );

    final brandText = Text(
      'Prosavis',
      style: BrandConstants.headlineMedium.copyWith(
        fontSize: textSize ?? 24.0,
        color: adaptive ? null : BrandConstants.textPrimary,
      ),
    );

    if (direction == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          logo,
          SizedBox(width: spacing),
          brandText,
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          logo,
          SizedBox(height: spacing),
          brandText,
        ],
      );
    }
  }
} 