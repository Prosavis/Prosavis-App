import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../core/utils/location_utils.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  /// Cache interno para evitar múltiples detecciones simultáneas
  bool _isDetecting = false;

  LocationBloc() : super(LocationInitial()) {
    on<DetectLocationEvent>(_onDetectLocation);
    on<RefreshLocationEvent>(_onRefreshLocation);
    on<ClearLocationEvent>(_onClearLocation);
    on<SetManualLocationEvent>(_onSetManualLocation);
  }

  /// Maneja la detección automática de ubicación
  Future<void> _onDetectLocation(
    DetectLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    if (_isDetecting) {
      developer.log('🔄 Ya hay una detección en progreso, ignorando nueva solicitud', name: 'LocationBloc');
      return;
    }

    _isDetecting = true;
    emit(LocationLoading());

    try {
      developer.log('🔍 Iniciando detección de ubicación centralizada...', name: 'LocationBloc');

      // Verificar primero si hay ubicación en cache válida
      final cachedLocation = await LocationUtils.getCachedUserLocation();
      
      if (cachedLocation != null) {
        developer.log('💾 Ubicación encontrada en cache', name: 'LocationBloc');
        
        // Intentar obtener dirección desde cache/geocoding
        try {
          final address = await LocationUtils.getCurrentAddress();
          if (address != null) {
            final now = DateTime.now();
            emit(LocationLoaded(
              address: address,
              latitude: cachedLocation['latitude']!,
              longitude: cachedLocation['longitude']!,
              detectedAt: now,
              isFromCache: true,
            ));
            _isDetecting = false;
            return;
          }
        } catch (e) {
          developer.log('⚠️ Error obteniendo dirección desde cache: $e', name: 'LocationBloc');
        }
      }

      // Si no hay cache válido, obtener ubicación fresca
      developer.log('📍 Obteniendo ubicación GPS fresca...', name: 'LocationBloc');
      final locationDetails = await LocationUtils.getCurrentLocationDetails();
      
      if (locationDetails != null) {
        final address = locationDetails['address'] as String?;
        final latitude = locationDetails['latitude'] as double;
        final longitude = locationDetails['longitude'] as double;
        
        if (address != null && address.isNotEmpty) {
          final now = DateTime.now();
          emit(LocationLoaded(
            address: address,
            latitude: latitude,
            longitude: longitude,
            detectedAt: now,
            isFromCache: false,
          ));
          
          developer.log('✅ Ubicación detectada y centralizada: $address', name: 'LocationBloc');
        } else {
          // Fallback: usar coordenadas si no hay dirección
          final lat = latitude.toStringAsFixed(4);
          final lng = longitude.toStringAsFixed(4);
          final now = DateTime.now();
          
          emit(LocationLoaded(
            address: 'Lat: $lat, Lng: $lng',
            latitude: latitude,
            longitude: longitude,
            detectedAt: now,
            isFromCache: false,
          ));
          
          developer.log('✅ Ubicación detectada (solo coordenadas): $lat, $lng', name: 'LocationBloc');
        }
      } else {
        emit(const LocationError(
          message: 'No se pudo obtener la ubicación. Verifica que el GPS esté habilitado y los permisos estén concedidos.',
          errorType: LocationErrorType.unknown,
        ));
      }
    } catch (e) {
      developer.log('❌ Error en detección de ubicación: $e', name: 'LocationBloc');
      
      // Determinar tipo de error
      LocationErrorType errorType = LocationErrorType.unknown;
      String message = 'Error desconocido al obtener ubicación';
      
      if (e.toString().contains('permission') || e.toString().contains('denied')) {
        errorType = LocationErrorType.permissionDenied;
        message = 'Permisos de ubicación denegados. Ve a configuración para habilitarlos.';
      } else if (e.toString().contains('service') || e.toString().contains('disabled')) {
        errorType = LocationErrorType.serviceDisabled;
        message = 'Servicio de ubicación deshabilitado. Habilita el GPS en configuración.';
      } else if (e.toString().contains('timeout')) {
        errorType = LocationErrorType.timeout;
        message = 'Tiempo agotado al obtener ubicación. Inténtalo de nuevo.';
      }
      
      emit(LocationError(message: message, errorType: errorType));
    } finally {
      _isDetecting = false;
    }
  }

  /// Maneja la actualización/refresco de ubicación (fuerza nueva detección)
  Future<void> _onRefreshLocation(
    RefreshLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    // Limpiar cache antes de detectar nueva ubicación
    LocationUtils.clearLocationCache();
    add(DetectLocationEvent());
  }

  /// Maneja la limpieza de ubicación
  Future<void> _onClearLocation(
    ClearLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    developer.log('🧹 Limpiando ubicación centralizada', name: 'LocationBloc');
    LocationUtils.clearLocationCache();
    emit(LocationInitial());
  }

  /// Maneja la configuración manual de ubicación
  Future<void> _onSetManualLocation(
    SetManualLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    developer.log('📍 Configurando ubicación manual: ${event.address}', name: 'LocationBloc');
    
    // Actualizar cache con la ubicación manual
    final locationMap = {
      'latitude': event.latitude,
      'longitude': event.longitude,
    };
    LocationUtils.updateLocationCache(locationMap);
    
    final now = DateTime.now();
    emit(LocationLoaded(
      address: event.address,
      latitude: event.latitude,
      longitude: event.longitude,
      detectedAt: now,
      isFromCache: false,
    ));
  }

  /// Método de conveniencia para obtener la ubicación actual desde el estado
  Map<String, double>? get currentCoordinates {
    if (state is LocationLoaded) {
      final loadedState = state as LocationLoaded;
      return loadedState.coordinates;
    }
    return null;
  }

  /// Método de conveniencia para obtener la dirección actual
  String? get currentAddress {
    if (state is LocationLoaded) {
      return (state as LocationLoaded).address;
    }
    return null;
  }

  /// Método de conveniencia para verificar si hay ubicación disponible
  bool get hasLocation => state is LocationLoaded;

  /// Método de conveniencia para verificar si está cargando
  bool get isLoading => state is LocationLoading;
}
