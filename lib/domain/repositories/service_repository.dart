import '../entities/service_entity.dart';

abstract class ServiceRepository {
  /// Crear un nuevo servicio
  Future<String> createService(ServiceEntity service);
  
  /// Obtener servicio por ID
  Future<ServiceEntity?> getServiceById(String serviceId);
  
  /// Buscar servicios con filtros
  Future<List<ServiceEntity>> searchServices({
    String? query,
    String? category,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
    String? priceType,
    double? minRating,
    String? sortBy,
    double? radiusKm,
    double? userLatitude,
    double? userLongitude,
    int limit = 20,
  });
  
  /// Obtener servicios de un proveedor específico
  Future<List<ServiceEntity>> getServicesByProvider(String providerId);
  
  /// Actualizar servicio existente
  Future<void> updateService(ServiceEntity service);
  
  /// Eliminar servicio (soft delete)
  Future<void> deleteService(String serviceId);
}