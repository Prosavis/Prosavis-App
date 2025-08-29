import 'package:equatable/equatable.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial del LocationBloc
class LocationInitial extends LocationState {}

/// Estado cuando se está detectando/obteniendo la ubicación
class LocationLoading extends LocationState {}

/// Estado cuando la ubicación se ha obtenido exitosamente
class LocationLoaded extends LocationState {
  final String address;
  final double latitude;
  final double longitude;
  final DateTime detectedAt;
  final bool isFromCache;

  const LocationLoaded({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.detectedAt,
    this.isFromCache = false,
  });

  @override
  List<Object> get props => [address, latitude, longitude, detectedAt, isFromCache];

  /// Método para verificar si la ubicación es reciente (menos de 5 minutos)
  bool get isRecent {
    final now = DateTime.now();
    return now.difference(detectedAt).inMinutes < 5;
  }

  /// Método para obtener las coordenadas como Map (compatible con LocationUtils)
  Map<String, double> get coordinates => {
    'latitude': latitude,
    'longitude': longitude,
  };

  LocationLoaded copyWith({
    String? address,
    double? latitude,
    double? longitude,
    DateTime? detectedAt,
    bool? isFromCache,
  }) {
    return LocationLoaded(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      detectedAt: detectedAt ?? this.detectedAt,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

/// Estado cuando hay un error al obtener la ubicación
class LocationError extends LocationState {
  final String message;
  final LocationErrorType errorType;

  const LocationError({
    required this.message,
    this.errorType = LocationErrorType.unknown,
  });

  @override
  List<Object> get props => [message, errorType];
}

/// Tipos de errores de ubicación
enum LocationErrorType {
  permissionDenied,
  serviceDisabled,
  timeout,
  network,
  unknown,
}
