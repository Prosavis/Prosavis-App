import '../../domain/entities/saved_address_entity.dart';

class SavedAddressModel extends SavedAddressEntity {
  const SavedAddressModel({
    required super.id,
    required super.userId,
    required super.label,
    required super.addressLine,
    required super.latitude,
    required super.longitude,
    super.details,
    super.buildingName,
    super.isDefault = false,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SavedAddressModel.fromJson(Map<String, dynamic> json) {
    return SavedAddressModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      label: json['label'] ?? '',
      addressLine: json['addressLine'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      details: json['details'],
      buildingName: json['buildingName'],
      isDefault: json['isDefault'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'label': label,
      'addressLine': addressLine,
      'latitude': latitude,
      'longitude': longitude,
      'details': details,
      'buildingName': buildingName,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SavedAddressModel.fromEntity(SavedAddressEntity entity) {
    return SavedAddressModel(
      id: entity.id,
      userId: entity.userId,
      label: entity.label,
      addressLine: entity.addressLine,
      latitude: entity.latitude,
      longitude: entity.longitude,
      details: entity.details,
      buildingName: entity.buildingName,
      isDefault: entity.isDefault,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}


