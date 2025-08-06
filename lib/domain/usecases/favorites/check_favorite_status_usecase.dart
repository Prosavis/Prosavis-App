import '../../../core/usecases/usecase.dart';
import '../../repositories/favorite_repository.dart';

class CheckFavoriteStatusUseCase implements UseCase<bool, CheckFavoriteStatusParams> {
  final FavoriteRepository repository;

  CheckFavoriteStatusUseCase(this.repository);

  @override
  Future<bool> call(CheckFavoriteStatusParams params) async {
    return await repository.isFavorite(
      userId: params.userId,
      serviceId: params.serviceId,
    );
  }
}

class CheckFavoriteStatusParams {
  final String userId;
  final String serviceId;

  CheckFavoriteStatusParams({
    required this.userId,
    required this.serviceId,
  });
}