import 'package:equatable/equatable.dart';
import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/usecases/usecase.dart';

class SignUpWithEmailUseCase implements UseCase<UserEntity?, SignUpWithEmailParams> {
  final AuthRepository repository;

  SignUpWithEmailUseCase(this.repository);

  @override
  Future<UserEntity?> call(SignUpWithEmailParams params) async {
    return await repository.signUpWithEmail(params.email, params.password, params.name);
  }
}

class SignUpWithEmailParams extends Equatable {
  final String email;
  final String password;
  final String name;

  const SignUpWithEmailParams({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object> get props => [email, password, name];
}