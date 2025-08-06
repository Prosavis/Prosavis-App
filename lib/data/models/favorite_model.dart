import '../../domain/entities/favorite_entity.dart';

class FavoriteModel extends FavoriteEntity {
  const FavoriteModel({
    required super.id,
    required super.userId,
    required super.serviceId,
    required super.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      serviceId: json['serviceId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'serviceId': serviceId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FavoriteModel.fromEntity(FavoriteEntity entity) {
    return FavoriteModel(
      id: entity.id,
      userId: entity.userId,
      serviceId: entity.serviceId,
      createdAt: entity.createdAt,
    );
  }

  factory FavoriteModel.createNew({
    required String userId,
    required String serviceId,
  }) {
    final now = DateTime.now();
    return FavoriteModel(
      id: '', // Se asignará por Firestore
      userId: userId,
      serviceId: serviceId,
      createdAt: now,
    );
  }

  FavoriteModel copyWithModel({
    String? id,
    String? userId,
    String? serviceId,
    DateTime? createdAt,
  }) {
    return FavoriteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}