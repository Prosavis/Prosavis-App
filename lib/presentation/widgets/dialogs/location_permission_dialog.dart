import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/themes/app_theme.dart';
import '../../../core/utils/location_utils.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionDialog extends StatefulWidget {
  const LocationPermissionDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // No permitir cerrar tocando fuera
      builder: (context) => const LocationPermissionDialog(),
    );
  }

  @override
  State<LocationPermissionDialog> createState() => _LocationPermissionDialogState();
}

class _LocationPermissionDialogState extends State<LocationPermissionDialog> {
  bool _isLoading = false;
  String _statusMessage = 'Verifica y configura tu ubicación para encontrar servicios cercanos.';
  bool _hasLocationPermission = false;
  bool _isLocationServiceEnabled = false;
  String? _currentAddress;
  
  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Verificando permisos de ubicación...';
    });

    try {
      // Verificar si el servicio de ubicación está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      // Verificar permisos
      final permission = await Geolocator.checkPermission();
      final hasPermission = permission == LocationPermission.always || 
                           permission == LocationPermission.whileInUse;

      setState(() {
        _isLocationServiceEnabled = serviceEnabled;
        _hasLocationPermission = hasPermission;
        _isLoading = false;
        
        if (!_isLocationServiceEnabled) {
          _statusMessage = 'El servicio de ubicación está desactivado. Por favor, actívalo en la configuración.';
        } else if (!_hasLocationPermission) {
          _statusMessage = 'Se requieren permisos de ubicación para continuar.';
        } else {
          _statusMessage = 'Verificando ubicación actual...';
          _verifyLocationAccess();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error al verificar el estado de ubicación';
      });
    }
  }

  Future<void> _verifyLocationAccess() async {
    try {
      setState(() {
        _statusMessage = 'Obteniendo ubicación actual...';
      });

      final location = await LocationUtils.getCurrentUserLocation();
      if (location != null) {
        // Intentar obtener la dirección
        try {
          final address = await LocationUtils.getCurrentAddress();
          setState(() {
            _currentAddress = address;
            _statusMessage = address != null 
              ? 'Ubicación obtenida correctamente'
              : 'Ubicación obtenida (sin dirección disponible)';
          });
        } catch (e) {
          setState(() {
            _currentAddress = 'Lat: ${location['latitude']?.toStringAsFixed(4)}, Lng: ${location['longitude']?.toStringAsFixed(4)}';
            _statusMessage = 'Ubicación obtenida (coordenadas)';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'No se pudo obtener la ubicación actual';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al obtener la ubicación actual';
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Solicitando permisos de ubicación...';
    });

    try {
      final permission = await Geolocator.requestPermission();
      final granted = permission == LocationPermission.always || 
                     permission == LocationPermission.whileInUse;

      setState(() {
        _hasLocationPermission = granted;
        _isLoading = false;
        
        if (permission == LocationPermission.deniedForever) {
          _statusMessage = 'Los permisos de ubicación han sido denegados permanentemente.\nDebe habilitarlos manualmente en configuración.';
        } else if (!granted) {
          _statusMessage = 'Los permisos de ubicación fueron denegados';
        } else {
          _statusMessage = 'Permisos otorgados. Verificando ubicación...';
          _verifyLocationAccess();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error al solicitar permisos de ubicación';
      });
    }
  }

  Future<void> _openLocationSettings() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Abriendo configuración de ubicación...';
    });

    final opened = await LocationUtils.openLocationSettings();
    
    setState(() {
      _isLoading = false;
      _statusMessage = opened 
        ? 'Configure la ubicación y presione "Verificar de Nuevo"'
        : 'No se pudo abrir la configuración de ubicación';
    });
  }

  Future<void> _openAppSettings() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Abriendo configuración de la aplicación...';
    });

    final opened = await LocationUtils.openAppSettings();
    
    setState(() {
      _isLoading = false;
      _statusMessage = opened 
        ? 'Habilite los permisos de ubicación y presione "Verificar de Nuevo"'
        : 'No se pudo abrir la configuración de la aplicación';
    });
  }

  void _closeDialog() {
    if (mounted) {
      Navigator.of(context).pop(_currentAddress != null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Icono de ubicación
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  _hasLocationPermission && _isLocationServiceEnabled
                      ? Symbols.location_on
                      : Symbols.location_off,
                  size: 40,
                  color: _hasLocationPermission && _isLocationServiceEnabled
                      ? Colors.green[600]
                      : Colors.orange[600],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Título
              Text(
                'Configuración de Ubicación',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Estado actual
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    if (_isLoading) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              if (!_isLocationServiceEnabled) ...[
                _buildActionButton(
                  onPressed: _isLoading ? null : _openLocationSettings,
                  icon: Symbols.settings_applications,
                  text: 'Activar Ubicación',
                  isPrimary: true,
                ),
                const SizedBox(height: 12),
              ],
              
              if (!_hasLocationPermission && _isLocationServiceEnabled) ...[
                _buildActionButton(
                  onPressed: _isLoading ? null : _requestLocationPermission,
                  icon: Symbols.location_on,
                  text: 'Permitir Ubicación',
                  isPrimary: true,
                ),
                const SizedBox(height: 12),
              ],
              
              // Botón de configuración manual
              _buildActionButton(
                onPressed: _isLoading ? null : _openAppSettings,
                icon: Symbols.settings,
                text: 'Configuración Manual',
                isPrimary: false,
              ),
              
              const SizedBox(height: 12),
              
              // Botón de verificar de nuevo
              _buildActionButton(
                onPressed: _isLoading ? null : _checkLocationStatus,
                icon: Symbols.refresh,
                text: 'Verificar de Nuevo',
                isPrimary: false,
              ),
              
              const SizedBox(height: 16),
              
              // Mostrar dirección obtenida si existe
              if (_currentAddress != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ubicación Actual:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentAddress!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Botón de cerrar
              _buildActionButton(
                onPressed: _closeDialog,
                icon: Symbols.close,
                text: 'Cerrar',
                isPrimary: false,
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String text,
    required bool isPrimary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary 
            ? Colors.white 
            : Colors.white.withValues(alpha: 0.2),
          foregroundColor: isPrimary 
            ? AppTheme.primaryColor 
            : Colors.white,
          elevation: isPrimary ? 6 : 2,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: isPrimary 
              ? BorderSide.none 
              : BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
          ),
        ),
      ),
    );
  }
}
