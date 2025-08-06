import 'package:flutter/foundation.dart';

import '../../entities/review_entity.dart';
import '../../repositories/review_repository.dart';
import '../../repositories/service_repository.dart';
import '../../../core/usecases/usecase.dart';

/// UseCase para crear una nueva reseña
class CreateReviewUseCase implements UseCase<String, ReviewEntity> {
  final ReviewRepository reviewRepository;
  final ServiceRepository serviceRepository;

  CreateReviewUseCase(this.reviewRepository, this.serviceRepository);

  @override
  Future<String> call(ReviewEntity review) async {
    // Verificar que el usuario no haya reseñado ya este servicio
    final hasReviewed = await reviewRepository.hasUserReviewedService(
      review.userId,
      review.serviceId,
    );
    
    if (hasReviewed) {
      throw Exception('Ya has reseñado este servicio');
    }
    
    // Crear la reseña
    final reviewId = await reviewRepository.createReview(review);
    
    // Actualizar las estadísticas del servicio
    await _updateServiceReviewStats(review.serviceId);
    
    return reviewId;
  }

  /// Actualiza las estadísticas de reseñas del servicio
  Future<void> _updateServiceReviewStats(String serviceId) async {
    try {
      // Obtener el servicio actual
      final service = await serviceRepository.getServiceById(serviceId);
      if (service == null) {
        throw Exception('Servicio no encontrado');
      }

      // Obtener las estadísticas actualizadas de reseñas
      final stats = await reviewRepository.getServiceReviewStats(serviceId);
      
      // Crear una copia del servicio con las estadísticas actualizadas
      final updatedService = service.copyWith(
        rating: stats['averageRating']?.toDouble() ?? 0.0,
        reviewCount: stats['totalReviews'] ?? 0,
        updatedAt: DateTime.now(),
      );

      // Actualizar el servicio en la base de datos
      await serviceRepository.updateService(updatedService);
    } catch (e) {
      // Log del error pero no interrumpir el flujo principal
      debugPrint('Error al actualizar estadísticas del servicio: $e');
    }
  }
}