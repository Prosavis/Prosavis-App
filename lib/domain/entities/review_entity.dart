import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final String id;
  final String serviceId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating; // 1.0 to 5.0
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReviewEntity({
    required this.id,
    required this.serviceId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        serviceId,
        userId,
        userName,
        userPhotoUrl,
        rating,
        comment,
        createdAt,
        updatedAt,
      ];

  ReviewEntity copyWith({
    String? id,
    String? serviceId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewEntity(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}