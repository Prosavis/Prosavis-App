import '../../../core/usecases/usecase.dart';
import '../../entities/service_entity.dart';
import '../../repositories/favorite_repository.dart';

class GetUserFavoritesUseCase implements UseCase<List<ServiceEntity>, String> {
  final FavoriteRepository repository;

  GetUserFavoritesUseCase(this.repository);

  @override
  Future<List<ServiceEntity>> call(String userId) async {
    // Primero limpiar favoritos inválidos
    await repository.cleanupInvalidFavorites(userId);
    
    // Luego obtener servicios favoritos válidos
    return await repository.getUserFavoriteServices(userId);
  }
}

/// Versión reactiva: emite actualizaciones en tiempo real
class WatchUserFavoritesUseCase {
  final FavoriteRepository repository;

  WatchUserFavoritesUseCase(this.repository);

  Stream<List<ServiceEntity>> call(String userId) {
    return repository.watchUserFavoriteServices(userId);
  }
}