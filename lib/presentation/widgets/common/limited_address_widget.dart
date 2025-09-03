import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/location_utils.dart';
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_state.dart';

/// Widget que muestra la dirección con espacio limitado y efecto de scroll automático
class LimitedAddressWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final double maxWidth;
  final String anonymousText;

  const LimitedAddressWidget({
    super.key,
    this.onTap,
    required this.maxWidth,
    this.anonymousText = 'Toca para agregar ubicación',
  });

  @override
  State<LimitedAddressWidget> createState() => _LimitedAddressWidgetState();
}

class _LimitedAddressWidgetState extends State<LimitedAddressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scrollController;
  late Animation<double> _scrollAnimation;
  final GlobalKey _textKey = GlobalKey();
  double _textWidth = 0;
  bool _needsScroll = false;

  @override
  void initState() {
    super.initState();
    
    _scrollController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    
    _scrollAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scrollController,
      curve: Curves.linear,
    ));
    
    // Verificar el ancho del texto después de que se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTextWidth();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkTextWidth() {
    final RenderBox? renderBox = _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final double textWidth = renderBox.size.width;
      setState(() {
        _textWidth = textWidth;
        _needsScroll = textWidth > widget.maxWidth;
      });
      
      if (_needsScroll) {
        _startScrollAnimation();
      }
    }
  }

  void _startScrollAnimation() {
    if (_needsScroll && mounted) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _scrollController.forward().then((_) {
            if (mounted) {
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) {
                  _scrollController.reset();
                  _startScrollAnimation();
                }
              });
            }
          });
        }
      });
    }
  }

  String _getLocationText(LocationState locationState) {
    if (locationState is LocationLoading) {
      return 'Detectando ubicación...';
    } else if (locationState is LocationLoaded) {
      return LocationUtils.normalizeAddress(locationState.address);
    } else {
      return widget.anonymousText;
    }
  }

  IconData _getLocationIcon(LocationState locationState) {
    if (locationState is LocationLoading) {
      return Symbols.my_location;
    } else if (locationState is LocationLoaded) {
      return Symbols.location_on;
    } else {
      return Symbols.location_off;
    }
  }

  Color _getLocationIconColor(LocationState locationState, BuildContext context) {
    if (locationState is LocationLoading) {
      return AppTheme.accentColor;
    } else {
      return AppTheme.getTextSecondary(context);
    }
  }

  FontStyle? _getLocationTextStyle(LocationState locationState) {
    if (locationState is LocationLoading) {
      return FontStyle.italic;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, locationState) {
          final String locationText = _getLocationText(locationState);
          
          return SizedBox(
            width: widget.maxWidth,
            height: 20,
            child: Row(
              children: [
                Icon(
                  _getLocationIcon(locationState),
                  size: 12,
                  color: _getLocationIconColor(locationState, context),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: _scrollAnimation,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            // Texto que se puede desplazar
                            Positioned(
                              left: _needsScroll 
                                ? -(_textWidth - widget.maxWidth + 20) * _scrollAnimation.value
                                : 0,
                              child: Text(
                                locationText,
                                key: _textKey,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontStyle: _getLocationTextStyle(locationState),
                                  fontSize: 11,
                                  color: AppTheme.getTextSecondary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
