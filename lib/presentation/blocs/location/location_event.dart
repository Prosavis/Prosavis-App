import 'package:equatable/equatable.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para solicitar detección automática de ubicación
class DetectLocationEvent extends LocationEvent {}

/// Evento para refrescar/actualizar la ubicación actual
class RefreshLocationEvent extends LocationEvent {}

/// Evento para limpiar la ubicación actual
class ClearLocationEvent extends LocationEvent {}

/// Evento para configurar manualmente una ubicación
class SetManualLocationEvent extends LocationEvent {
  final String address;
  final double latitude;
  final double longitude;

  const SetManualLocationEvent({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object> get props => [address, latitude, longitude];
}
