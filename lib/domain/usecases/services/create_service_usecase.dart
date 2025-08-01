import '../../entities/service_entity.dart';
import '../../repositories/service_repository.dart';
import '../../../core/usecases/usecase.dart';

class CreateServiceUseCase implements UseCase<String, CreateServiceParams> {
  final ServiceRepository repository;

  CreateServiceUseCase(this.repository);

  @override
  Future<String> call(CreateServiceParams params) async {
    return await repository.createService(params.service);
  }
}

class CreateServiceParams {
  final ServiceEntity service;

  const CreateServiceParams({required this.service});
}