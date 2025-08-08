import '../../entities/review_entity.dart';
import '../../repositories/review_repository.dart';
import '../../../core/usecases/usecase.dart';

class CheckUserReviewParams {
  final String serviceId;
  final String userId;

  const CheckUserReviewParams({
    required this.serviceId,
    required this.userId,
  });
}

/// UseCase para verificar si un usuario ya tiene una reseña para un servicio específico
class CheckUserReviewUseCase implements UseCase<ReviewEntity?, CheckUserReviewParams> {
  final ReviewRepository repository;

  CheckUserReviewUseCase(this.repository);

  @override
  Future<ReviewEntity?> call(CheckUserReviewParams params) async {
    return await repository.getUserReviewForService(
      params.serviceId,
      params.userId,
    );
  }
}
