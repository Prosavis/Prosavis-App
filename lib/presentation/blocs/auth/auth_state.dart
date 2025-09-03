import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  final bool isRecentLogin;

  const AuthAuthenticated(this.user, {this.isRecentLogin = false});

  @override
  List<Object> get props => [user, isRecentLogin];
}

class AuthUnauthenticated extends AuthState {}

class AuthPhoneCodeSent extends AuthState {
  final String verificationId;
  final String phoneNumber;

  const AuthPhoneCodeSent({
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [verificationId, phoneNumber];
}

class AuthPasswordResetSent extends AuthState {
  final String email;

  const AuthPasswordResetSent({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthError extends AuthState {
  final String message;
  final String? errorCode;
  final bool isSignUp;

  const AuthError(this.message, {this.errorCode, this.isSignUp = false});

  @override
  List<Object?> get props => [message, errorCode, isSignUp];
} 