import 'package:equatable/equatable.dart';

class FavoriteEntity extends Equatable {
  final String id;
  final String userId;
  final String serviceId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FavoriteEntity({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        serviceId,
        createdAt,
        updatedAt,
      ];

  FavoriteEntity copyWith({
    String? id,
    String? userId,
    String? serviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FavoriteEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}