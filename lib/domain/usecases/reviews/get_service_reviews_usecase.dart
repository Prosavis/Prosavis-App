import '../../entities/review_entity.dart';
import '../../repositories/review_repository.dart';
import '../../../core/usecases/usecase.dart';

class GetServiceReviewsParams {
  final String serviceId;
  final int limit;

  const GetServiceReviewsParams({
    required this.serviceId,
    this.limit = 20,
  });
}

/// UseCase para obtener reseñas de un servicio específico
class GetServiceReviewsUseCase implements UseCase<List<ReviewEntity>, GetServiceReviewsParams> {
  final ReviewRepository repository;

  GetServiceReviewsUseCase(this.repository);

  @override
  Future<List<ReviewEntity>> call(GetServiceReviewsParams params) async {
    return await repository.getServiceReviews(
      params.serviceId,
      limit: params.limit,
    );
  }
}