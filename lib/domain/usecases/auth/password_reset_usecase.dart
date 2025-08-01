import 'package:equatable/equatable.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/usecases/usecase.dart';

class PasswordResetUseCase implements UseCase<void, PasswordResetParams> {
  final AuthRepository repository;

  PasswordResetUseCase(this.repository);

  @override
  Future<void> call(PasswordResetParams params) async {
    return await repository.sendPasswordResetEmail(params.email);
  }
}

class PasswordResetParams extends Equatable {
  final String email;

  const PasswordResetParams({required this.email});

  @override
  List<Object> get props => [email];
}