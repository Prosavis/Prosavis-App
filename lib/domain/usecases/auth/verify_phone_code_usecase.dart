import 'package:equatable/equatable.dart';
import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/usecases/usecase.dart';

class VerifyPhoneCodeUseCase implements UseCase<UserEntity?, VerifyPhoneCodeParams> {
  final AuthRepository repository;

  VerifyPhoneCodeUseCase(this.repository);

  @override
  Future<UserEntity?> call(VerifyPhoneCodeParams params) async {
    return await repository.verifyPhoneCode(params.verificationId, params.smsCode);
  }
}

class VerifyPhoneCodeParams extends Equatable {
  final String verificationId;
  final String smsCode;

  const VerifyPhoneCodeParams({
    required this.verificationId,
    required this.smsCode,
  });

  @override
  List<Object> get props => [verificationId, smsCode];
}