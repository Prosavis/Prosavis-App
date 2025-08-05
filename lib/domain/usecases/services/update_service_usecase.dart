import '../../entities/service_entity.dart';
import '../../repositories/service_repository.dart';
import '../../../core/usecases/usecase.dart';

/// UseCase para actualizar un servicio existente
class UpdateServiceUseCase implements UseCase<void, ServiceEntity> {
  final ServiceRepository repository;

  UpdateServiceUseCase(this.repository);

  @override
  Future<void> call(ServiceEntity service) async {
    await repository.updateService(service);
  }
}