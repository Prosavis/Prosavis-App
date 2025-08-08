import '../entities/review_entity.dart';

abstract class ReviewRepository {
  /// Crear una nueva reseña
  Future<String> createReview(ReviewEntity review);
  
  /// Obtener reseñas de un servicio específico
  Future<List<ReviewEntity>> getServiceReviews(String serviceId, {int limit = 20});
  
  /// Obtener reseña específica por ID
  Future<ReviewEntity?> getReviewById(String reviewId);
  
  /// Actualizar una reseña existente
  Future<void> updateReview(ReviewEntity review);
  
  /// Eliminar una reseña
  Future<void> deleteReview(String reviewId);
  
  /// Verificar si un usuario ya reseñó un servicio
  Future<bool> hasUserReviewedService(String userId, String serviceId);
  
  /// Obtener la reseña específica de un usuario para un servicio
  Future<ReviewEntity?> getUserReviewForService(String serviceId, String userId);
  
  /// Obtener estadísticas de reseñas de un servicio
  Future<Map<String, dynamic>> getServiceReviewStats(String serviceId);
}