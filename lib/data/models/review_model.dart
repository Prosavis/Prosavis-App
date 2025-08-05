import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/review_entity.dart';

class ReviewModel {
  final String id;
  final String serviceId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReviewModel({
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

  /// Crear ReviewModel desde ReviewEntity
  factory ReviewModel.fromEntity(ReviewEntity entity) {
    return ReviewModel(
      id: entity.id,
      serviceId: entity.serviceId,
      userId: entity.userId,
      userName: entity.userName,
      userPhotoUrl: entity.userPhotoUrl,
      rating: entity.rating,
      comment: entity.comment,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Crear ReviewModel desde Firestore Document
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ReviewModel(
      id: doc.id,
      serviceId: data['serviceId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convertir a ReviewEntity
  ReviewEntity toEntity() {
    return ReviewEntity(
      id: id,
      serviceId: serviceId,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}