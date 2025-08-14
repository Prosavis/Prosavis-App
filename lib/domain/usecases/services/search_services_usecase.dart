import '../../entities/service_entity.dart';
import '../../repositories/service_repository.dart';
import '../../../core/usecases/usecase.dart';

class SearchServicesUseCase implements UseCase<List<ServiceEntity>, SearchServicesParams> {
  final ServiceRepository repository;

  SearchServicesUseCase(this.repository);

  @override
  Future<List<ServiceEntity>> call(SearchServicesParams params) async {
    return await repository.searchServices(
      query: params.query,
      category: params.category,
      categories: params.categories,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      priceType: params.priceType,
      minRating: params.minRating,
      sortBy: params.sortBy,
      radiusKm: params.radiusKm,
      userLatitude: params.userLatitude,
      userLongitude: params.userLongitude,
      limit: params.limit,
    );
  }
}

class SearchServicesParams {
  final String? query;
  final String? category;
  final List<String>? categories;
  final double? minPrice;
  final double? maxPrice;
  final String? priceType;
  final double? minRating;
  final String? sortBy;
  final double? radiusKm;
  final double? userLatitude;
  final double? userLongitude;
  final int limit;

  const SearchServicesParams({
    this.query,
    this.category,
    this.categories,
    this.minPrice,
    this.maxPrice,
    this.priceType,
    this.minRating,
    this.sortBy,
    this.radiusKm,
    this.userLatitude,
    this.userLongitude,
    this.limit = 20,
  });
}