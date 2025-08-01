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
    double? minPrice,
    double? maxPrice,
    String? priceType,
    int limit = 20,
  }) async {
    return await _firestoreService.searchServices(
      query: query,
      category: category,
      minPrice: minPrice,
      maxPrice: maxPrice,
      priceType: priceType,
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