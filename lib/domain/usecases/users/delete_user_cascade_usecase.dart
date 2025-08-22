import '../../../core/usecases/usecase.dart';
import '../../repositories/user_repository.dart';

/// Caso de uso para eliminar un usuario y todos sus datos asociados (eliminación en cascada)
/// 
/// Esta eliminación incluye:
/// - El documento del usuario en Firestore
/// - Su imagen de perfil en Firebase Storage
/// - Todos sus servicios (con sus imágenes)
/// - Todos sus favoritos
/// - Todas sus reseñas
class DeleteUserCascadeUseCase implements UseCase<void, String> {
  final UserRepository repository;

  DeleteUserCascadeUseCase(this.repository);

  @override
  Future<void> call(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('El ID del usuario no puede estar vacío');
    }
    
    // El repositorio se encarga de la eliminación en cascada
    return await repository.deleteUser(userId);
  }
}
