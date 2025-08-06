import 'package:equatable/equatable.dart';

class FavoriteEntity extends Equatable {
  final String id;
  final String userId;
  final String serviceId;
  final DateTime createdAt;

  const FavoriteEntity({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        serviceId,
        createdAt,
      ];

  FavoriteEntity copyWith({
    String? id,
    String? userId,
    String? serviceId,
    DateTime? createdAt,
  }) {
    return FavoriteEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}