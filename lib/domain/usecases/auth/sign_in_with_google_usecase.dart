import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/usecases/usecase.dart';

class SignInWithGoogleUseCase implements UseCase<UserEntity?, NoParams> {
  final AuthRepository repository;

  SignInWithGoogleUseCase(this.repository);

  @override
  Future<UserEntity?> call(NoParams params) async {
    return await repository.signInWithGoogle();
  }
} 