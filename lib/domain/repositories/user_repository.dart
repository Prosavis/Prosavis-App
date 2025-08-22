import '../entities/user_entity.dart';

abstract class UserRepository {
  /// Obtener usuario por ID
  Future<UserEntity?> getUserById(String userId);
  
  /// Obtener usuario por email
  Future<UserEntity?> getUserByEmail(String email);
  
  /// Crear o actualizar un usuario
  Future<void> createOrUpdateUser(UserEntity user);
  
  /// Obtener todos los usuarios
  Future<List<UserEntity>> getAllUsers();
  
  /// Eliminar usuario y todos sus datos asociados (eliminación en cascada)
  /// Esta operación incluye:
  /// - El documento del usuario en Firestore
  /// - Su imagen de perfil en Firebase Storage
  /// - Todos sus servicios (con sus imágenes)
  /// - Todos sus favoritos
  /// - Todas sus reseñas
  Future<void> deleteUser(String userId);
}
