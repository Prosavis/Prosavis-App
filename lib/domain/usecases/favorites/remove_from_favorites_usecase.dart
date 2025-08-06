import '../../../core/usecases/usecase.dart';
import '../../repositories/favorite_repository.dart';

class RemoveFromFavoritesUseCase implements UseCase<void, RemoveFromFavoritesParams> {
  final FavoriteRepository repository;

  RemoveFromFavoritesUseCase(this.repository);

  @override
  Future<void> call(RemoveFromFavoritesParams params) async {
    return await repository.removeFromFavorites(
      userId: params.userId,
      serviceId: params.serviceId,
    );
  }
}

class RemoveFromFavoritesParams {
  final String userId;
  final String serviceId;

  RemoveFromFavoritesParams({
    required this.userId,
    required this.serviceId,
  });
}