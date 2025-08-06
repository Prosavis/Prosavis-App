import '../../../core/usecases/usecase.dart';
import '../../repositories/favorite_repository.dart';

class AddToFavoritesUseCase implements UseCase<String, AddToFavoritesParams> {
  final FavoriteRepository repository;

  AddToFavoritesUseCase(this.repository);

  @override
  Future<String> call(AddToFavoritesParams params) async {
    return await repository.addToFavorites(
      userId: params.userId,
      serviceId: params.serviceId,
    );
  }
}

class AddToFavoritesParams {
  final String userId;
  final String serviceId;

  AddToFavoritesParams({
    required this.userId,
    required this.serviceId,
  });
}