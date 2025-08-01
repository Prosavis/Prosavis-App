import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class UpdateProfilePhoto extends ProfileEvent {
  final File imageFile;

  const UpdateProfilePhoto(this.imageFile);

  @override
  List<Object> get props => [imageFile];
}

class RemoveProfilePhoto extends ProfileEvent {}

class LoadProfile extends ProfileEvent {}