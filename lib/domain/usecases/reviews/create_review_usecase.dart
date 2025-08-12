
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
    
    // Las estadísticas del servicio (rating/promedio y reviewCount)
    // ahora se actualizan en el servidor mediante Cloud Functions
    
    return reviewId;
  }
  
}