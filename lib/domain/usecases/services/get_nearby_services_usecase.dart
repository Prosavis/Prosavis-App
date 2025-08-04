import '../../entities/service_entity.dart';
import '../../repositories/service_repository.dart';
import '../../../core/usecases/usecase.dart';

class GetNearbyServicesUseCase implements UseCase<List<ServiceEntity>, GetNearbyServicesParams> {
  final ServiceRepository repository;

  GetNearbyServicesUseCase(this.repository);

  @override
  Future<List<ServiceEntity>> call(GetNearbyServicesParams params) async {
    // Por ahora obtenemos servicios limitados, en el futuro se puede filtrar por ubicación
    return await repository.searchServices(
      limit: params.limit,
    );
  }
}

class GetNearbyServicesParams {
  final int limit;

  const GetNearbyServicesParams({
    this.limit = 3,
  });
}