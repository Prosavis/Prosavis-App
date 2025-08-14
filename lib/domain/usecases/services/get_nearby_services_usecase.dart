import '../../entities/service_entity.dart';
import '../../repositories/service_repository.dart';
import '../../../core/usecases/usecase.dart';

class GetNearbyServicesUseCase implements UseCase<List<ServiceEntity>, GetNearbyServicesParams> {
  final ServiceRepository repository;

  GetNearbyServicesUseCase(this.repository);

  @override
  Future<List<ServiceEntity>> call(GetNearbyServicesParams params) async {
    return await repository.searchServices(
      limit: params.limit,
      radiusKm: params.radiusKm,
      userLatitude: params.userLatitude,
      userLongitude: params.userLongitude,
      sortBy: 'distance',
    );
  }
}

class GetNearbyServicesParams {
  final int limit;
  final double? radiusKm;
  final double? userLatitude;
  final double? userLongitude;

  const GetNearbyServicesParams({
    this.limit = 3,
    this.radiusKm,
    this.userLatitude,
    this.userLongitude,
  });
}