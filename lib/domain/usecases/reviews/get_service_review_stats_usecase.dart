import '../../repositories/review_repository.dart';
import '../../../core/usecases/usecase.dart';

/// UseCase para obtener estadísticas agregadas de reseñas de un servicio
class GetServiceReviewStatsUseCase
    implements UseCase<Map<String, dynamic>, String> {
  final ReviewRepository repository;

  GetServiceReviewStatsUseCase(this.repository);

  @override
  Future<Map<String, dynamic>> call(String serviceId) async {
    return await repository.getServiceReviewStats(serviceId);
  }
}


