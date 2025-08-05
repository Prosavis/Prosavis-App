import '../../entities/service_entity.dart';
import '../../repositories/service_repository.dart';
import '../../../core/usecases/usecase.dart';

/// UseCase para obtener un servicio específico por su ID
class GetServiceByIdUseCase implements UseCase<ServiceEntity?, String> {
  final ServiceRepository repository;

  GetServiceByIdUseCase(this.repository);

  @override
  Future<ServiceEntity?> call(String serviceId) async {
    return await repository.getServiceById(serviceId);
  }
}