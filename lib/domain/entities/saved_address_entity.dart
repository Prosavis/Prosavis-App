import 'package:equatable/equatable.dart';

/// Representa una dirección guardada por el usuario (Casa, Trabajo, etc.)
class SavedAddressEntity extends Equatable {
  final String id;
  final String userId;
  final String label; // Ej: Casa, Trabajo, Novi@
  final String addressLine; // Dirección legible completa
  final double latitude;
  final double longitude;
  final String? details; // Apto, interior, referencias
  final String? buildingName; // Nombre del edificio o condominio
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedAddressEntity({
    required this.id,
    required this.userId,
    required this.label,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
    this.details,
    this.buildingName,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  SavedAddressEntity copyWith({
    String? id,
    String? userId,
    String? label,
    String? addressLine,
    double? latitude,
    double? longitude,
    String? details,
    String? buildingName,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedAddressEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      addressLine: addressLine ?? this.addressLine,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      details: details ?? this.details,
      buildingName: buildingName ?? this.buildingName,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        label,
        addressLine,
        latitude,
        longitude,
        details,
        buildingName,
        isDefault,
        createdAt,
        updatedAt,
      ];
}


