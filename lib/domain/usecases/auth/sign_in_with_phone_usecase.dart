import 'package:equatable/equatable.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/usecases/usecase.dart';

class SignInWithPhoneUseCase implements UseCase<String, SignInWithPhoneParams> {
  final AuthRepository repository;

  SignInWithPhoneUseCase(this.repository);

  @override
  Future<String> call(SignInWithPhoneParams params) async {
    return await repository.signInWithPhone(params.phoneNumber);
  }
}

class SignInWithPhoneParams extends Equatable {
  final String phoneNumber;

  const SignInWithPhoneParams({required this.phoneNumber});

  @override
  List<Object> get props => [phoneNumber];
}