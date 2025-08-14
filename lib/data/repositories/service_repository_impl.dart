import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/service_repository.dart';
import '../services/firestore_service.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final FirestoreService _firestoreService;

  ServiceRepositoryImpl(this._firestoreService);

  @override
  Future<String> createService(ServiceEntity service) async {
    return await _firestoreService.createService(service);
  }

  @override
  Future<ServiceEntity?> getServiceById(String serviceId) async {
    return await _firestoreService.getServiceById(serviceId);
  }

  @override
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
  }) async {
    return await _firestoreService.searchServices(
      query: query,
      category: category,
      categories: categories,
      minPrice: minPrice,
      maxPrice: maxPrice,
      priceType: priceType,
      minRating: minRating,
      sortBy: sortBy,
      radiusKm: radiusKm,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      limit: limit,
    );
  }

  @override
  Future<List<ServiceEntity>> getServicesByProvider(String providerId) async {
    return await _firestoreService.getServicesByProvider(providerId);
  }

  @override
  Future<void> updateService(ServiceEntity service) async {
    return await _firestoreService.updateService(service);
  }

  @override
  Future<void> deleteService(String serviceId) async {
    return await _firestoreService.deleteService(serviceId);
  }
}