import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_entity.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserEntity user;

  const ProfileLoaded(this.user);

  @override
  List<Object> get props => [user];
}

class ProfileUpdating extends ProfileState {}

class ProfilePhotoUpdated extends ProfileState {
  final String photoUrl;

  const ProfilePhotoUpdated(this.photoUrl);

  @override
  List<Object> get props => [photoUrl];
}

class ProfilePhotoRemoved extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object> get props => [message];
}