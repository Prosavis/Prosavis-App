import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/favorite_entity.dart';

class FavoriteModel extends FavoriteEntity {
  const FavoriteModel({
    required super.id,
    required super.userId,
    required super.serviceId,
    required super.createdAt,
    super.updatedAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      serviceId: json['serviceId'] ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? _parseDateTime(json['updatedAt']) : null,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      'userId': userId,
      'serviceId': serviceId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    if (updatedAt != null) {
      map['updatedAt'] = Timestamp.fromDate(updatedAt!);
    }
    return map;
  }

  factory FavoriteModel.fromEntity(FavoriteEntity entity) {
    return FavoriteModel(
      id: entity.id,
      userId: entity.userId,
      serviceId: entity.serviceId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
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
      updatedAt: null, // No se necesita en creación
    );
  }

  FavoriteModel copyWithModel({
    String? id,
    String? userId,
    String? serviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FavoriteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}