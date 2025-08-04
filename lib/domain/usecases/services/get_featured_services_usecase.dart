import '../../entities/service_entity.dart';
import '../../repositories/service_repository.dart';
import '../../../core/usecases/usecase.dart';

class GetFeaturedServicesUseCase implements UseCase<List<ServiceEntity>, GetFeaturedServicesParams> {
  final ServiceRepository repository;

  GetFeaturedServicesUseCase(this.repository);

  @override
  Future<List<ServiceEntity>> call(GetFeaturedServicesParams params) async {
    // Obtener servicios con alta calificación para mostrar como destacados
    return await repository.searchServices(
      limit: params.limit,
    );
  }
}

class GetFeaturedServicesParams {
  final int limit;

  const GetFeaturedServicesParams({
    this.limit = 5,
  });
}