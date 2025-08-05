import '../../entities/service_entity.dart';
import '../../repositories/service_repository.dart';
import '../../../core/usecases/usecase.dart';

/// UseCase para obtener todos los servicios creados por un usuario específico
class GetUserServicesUseCase implements UseCase<List<ServiceEntity>, String> {
  final ServiceRepository repository;

  GetUserServicesUseCase(this.repository);

  @override
  Future<List<ServiceEntity>> call(String userId) async {
    return await repository.getServicesByProvider(userId);
  }
}