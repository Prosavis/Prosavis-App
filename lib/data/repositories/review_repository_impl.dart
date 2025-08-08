import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';
import '../services/firestore_service.dart';

/// Implementación real del repositorio de reseñas conectado a Firestore
class ReviewRepositoryImpl implements ReviewRepository {
  final FirestoreService _firestoreService;

  ReviewRepositoryImpl(this._firestoreService);

  @override
  Future<String> createReview(ReviewEntity review) async {
    return await _firestoreService.createReview(review);
  }

  @override
  Future<List<ReviewEntity>> getServiceReviews(String serviceId, {int limit = 20}) async {
    return await _firestoreService.getServiceReviews(serviceId, limit: limit);
  }

  @override
  Future<ReviewEntity?> getReviewById(String reviewId) async {
    return await _firestoreService.getReviewById(reviewId);
  }

  @override
  Future<void> updateReview(ReviewEntity review) async {
    await _firestoreService.updateReview(review);
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await _firestoreService.deleteReview(reviewId);
  }

  @override
  Future<bool> hasUserReviewedService(String userId, String serviceId) async {
    return await _firestoreService.hasUserReviewedService(userId, serviceId);
  }

  @override
  Future<Map<String, dynamic>> getServiceReviewStats(String serviceId) async {
    return await _firestoreService.getServiceReviewStats(serviceId);
  }

  @override
  Future<ReviewEntity?> getUserReviewForService(String serviceId, String userId) async {
    return await _firestoreService.getUserReviewForService(serviceId, userId);
  }
}