import '../../../core/usecases/usecase.dart';
import '../../repositories/service_repository.dart';

/// Caso de uso para eliminar un servicio
class DeleteServiceUseCase implements UseCase<void, String> {
  final ServiceRepository repository;

  DeleteServiceUseCase(this.repository);

  @override
  Future<void> call(String serviceId) async {
    if (serviceId.isEmpty) {
      throw ArgumentError('El ID del servicio no puede estar vacío');
    }
    
    return await repository.deleteService(serviceId);
  }
}