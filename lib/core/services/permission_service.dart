import 'dart:async';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';

/// Servicio centralizado para manejo de permisos
/// Evita solicitudes múltiples simultáneas y maneja la cola de permisos
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Completer<LocationPermission>? _locationPermissionCompleter;
  LocationPermission? _cachedLocationPermission;
  DateTime? _lastPermissionCheck;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Obtiene permisos de ubicación de forma serializada
  /// Evita múltiples solicitudes concurrentes y cachea el resultado
  Future<LocationPermission> ensureLocationPermission() async {
    developer.Timeline.startSync('ensure_location_permission');
    
    try {
      // Si ya hay una solicitud en curso, esperar a que termine
      if (_locationPermissionCompleter != null) {
        developer.log('🔄 Esperando solicitud de permisos existente...');
        return await _locationPermissionCompleter!.future;
      }

      // Verificar cache válido
      if (_cachedLocationPermission != null && 
          _lastPermissionCheck != null &&
          DateTime.now().difference(_lastPermissionCheck!) < _cacheValidDuration) {
        developer.log('⚡ Permisos de ubicación desde cache: $_cachedLocationPermission');
        return _cachedLocationPermission!;
      }

      // Crear nuevo completer para esta solicitud
      _locationPermissionCompleter = Completer<LocationPermission>();

      developer.log('🔍 Verificando estado de permisos de ubicación...');

      // Verificar si el servicio de ubicación está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('❌ Servicio de ubicación deshabilitado');
        const result = LocationPermission.denied;
        _cachePermissionResult(result);
        return result;
      }

      // Verificar permisos actuales
      LocationPermission permission = await Geolocator.checkPermission();
      
      // Si ya tenemos permisos, retornar inmediatamente
      if (permission == LocationPermission.always || 
          permission == LocationPermission.whileInUse) {
        developer.log('✅ Permisos de ubicación ya otorgados: $permission');
        _cachePermissionResult(permission);
        return permission;
      }

      // Solo solicitar si están denegados (no permanentemente)
      if (permission == LocationPermission.denied) {
        developer.log('📱 Solicitando permisos de ubicación...');
        permission = await Geolocator.requestPermission();
      }

      _cachePermissionResult(permission);
      return permission;
    } catch (e) {
      developer.log('⚠️ Error al obtener permisos de ubicación: $e');
      const result = LocationPermission.denied;
      _cachePermissionResult(result);
      return result;
    } finally {
      developer.Timeline.finishSync();
    }
  }

  /// Verifica permisos sin solicitarlos
  Future<LocationPermission> checkLocationPermission() async {
    try {
      // Usar cache si está disponible y válido
      if (_cachedLocationPermission != null && 
          _lastPermissionCheck != null &&
          DateTime.now().difference(_lastPermissionCheck!) < _cacheValidDuration) {
        return _cachedLocationPermission!;
      }

      final permission = await Geolocator.checkPermission();
      _cachePermissionResult(permission);
      return permission;
    } catch (e) {
      developer.log('⚠️ Error al verificar permisos: $e');
      return LocationPermission.denied;
    }
  }

  /// Verifica si tenemos permisos válidos de ubicación
  Future<bool> hasLocationPermission() async {
    final permission = await checkLocationPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Cachea el resultado de permisos
  void _cachePermissionResult(LocationPermission permission) {
    _cachedLocationPermission = permission;
    _lastPermissionCheck = DateTime.now();
    
    // Completar la solicitud pendiente si existe
    if (_locationPermissionCompleter != null && !_locationPermissionCompleter!.isCompleted) {
      _locationPermissionCompleter!.complete(permission);
    }
    
    // Limpiar el completer
    _locationPermissionCompleter = null;
    
    developer.log('📝 Permisos cacheados: $permission');
  }

  /// Limpia el cache de permisos (útil cuando el usuario cambia configuración)
  void clearPermissionCache() {
    _cachedLocationPermission = null;
    _lastPermissionCheck = null;
    developer.log('🧹 Cache de permisos limpiado');
  }

  /// Verifica si el servicio de ubicación está habilitado
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      developer.log('⚠️ Error al verificar servicio de ubicación: $e');
      return false;
    }
  }

  /// Abre configuración de ubicación del dispositivo
  Future<bool> openLocationSettings() async {
    try {
      final opened = await Geolocator.openLocationSettings();
      if (opened) {
        // Limpiar cache porque el usuario puede haber cambiado configuración
        clearPermissionCache();
      }
      return opened;
    } catch (e) {
      developer.log('⚠️ Error al abrir configuración de ubicación: $e');
      return false;
    }
  }

  /// Abre configuración de la aplicación
  Future<bool> openAppSettings() async {
    try {
      final opened = await Geolocator.openAppSettings();
      if (opened) {
        // Limpiar cache porque el usuario puede haber cambiado configuración
        clearPermissionCache();
      }
      return opened;
    } catch (e) {
      developer.log('⚠️ Error al abrir configuración de la app: $e');
      return false;
    }
  }
}
