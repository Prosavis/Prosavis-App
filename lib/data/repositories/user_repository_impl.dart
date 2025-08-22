import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../services/firestore_service.dart';

class UserRepositoryImpl implements UserRepository {
  final FirestoreService _firestoreService;

  UserRepositoryImpl(this._firestoreService);

  @override
  Future<UserEntity?> getUserById(String userId) async {
    return await _firestoreService.getUserById(userId);
  }

  @override
  Future<UserEntity?> getUserByEmail(String email) async {
    return await _firestoreService.getUserByEmail(email);
  }

  @override
  Future<void> createOrUpdateUser(UserEntity user) async {
    return await _firestoreService.createOrUpdateUser(user);
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    return await _firestoreService.getAllUsers();
  }

  @override
  Future<void> deleteUser(String userId) async {
    // Este método ya implementa eliminación en cascada en FirestoreService
    return await _firestoreService.deleteUser(userId);
  }
}
