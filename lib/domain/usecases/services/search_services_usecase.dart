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
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      priceType: params.priceType,
      limit: params.limit,
    );
  }
}

class SearchServicesParams {
  final String? query;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final String? priceType;
  final int limit;

  const SearchServicesParams({
    this.query,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.priceType,
    this.limit = 20,
  });
}