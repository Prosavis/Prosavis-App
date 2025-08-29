import '../../../core/usecases/usecase.dart';
import '../../repositories/auth_repository.dart';

/// Parámetros para eliminar cuenta de usuario
class DeleteAccountParams {
  final String userId;

  const DeleteAccountParams({
    required this.userId,
  });
}

/// Use case para eliminar completamente la cuenta de un usuario
class DeleteAccountUseCase implements UseCase<void, DeleteAccountParams> {
  final AuthRepository _authRepository;

  const DeleteAccountUseCase(this._authRepository);

  @override
  Future<void> call(DeleteAccountParams params) async {
    return await _authRepository.deleteAccount(params.userId);
  }
}
