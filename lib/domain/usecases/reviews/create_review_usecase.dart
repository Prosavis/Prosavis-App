import '../../entities/review_entity.dart';
import '../../repositories/review_repository.dart';
import '../../../core/usecases/usecase.dart';

/// UseCase para crear una nueva reseña
class CreateReviewUseCase implements UseCase<String, ReviewEntity> {
  final ReviewRepository repository;

  CreateReviewUseCase(this.repository);

  @override
  Future<String> call(ReviewEntity review) async {
    // Verificar que el usuario no haya reseñado ya este servicio
    final hasReviewed = await repository.hasUserReviewedService(
      review.userId,
      review.serviceId,
    );
    
    if (hasReviewed) {
      throw Exception('Ya has reseñado este servicio');
    }
    
    return await repository.createReview(review);
  }
}