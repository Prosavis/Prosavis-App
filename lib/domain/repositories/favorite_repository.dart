import '../entities/favorite_entity.dart';
import '../entities/service_entity.dart';

abstract class FavoriteRepository {
  /// Agregar un servicio a favoritos
  Future<String> addToFavorites({
    required String userId,
    required String serviceId,
  });

  /// Quitar un servicio de favoritos
  Future<void> removeFromFavorites({
    required String userId,
    required String serviceId,
  });

  /// Verificar si un servicio está en favoritos
  Future<bool> isFavorite({
    required String userId,
    required String serviceId,
  });

  /// Obtener todos los favoritos de un usuario
  Future<List<FavoriteEntity>> getUserFavorites(String userId);

  /// Obtener servicios favoritos con detalles completos
  /// Solo devuelve servicios que existen y están activos
  Future<List<ServiceEntity>> getUserFavoriteServices(String userId);

  /// Limpiar favoritos de servicios eliminados/inactivos
  Future<void> cleanupInvalidFavorites(String userId);

  /// Obtener cantidad de favoritos de un usuario
  Future<int> getFavoritesCount(String userId);

  /// Suscripción en tiempo real a los favoritos del usuario (documentos)
  Stream<List<FavoriteEntity>> watchUserFavorites(String userId);

  /// Suscripción en tiempo real a los servicios favoritos del usuario
  /// Devuelve únicamente servicios existentes y activos, ordenados por `createdAt` desc
  Stream<List<ServiceEntity>> watchUserFavoriteServices(String userId);
}