import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
  final String? bio;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phoneNumber,
    this.bio,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        photoUrl,
        phoneNumber,
        bio,
        location,
        createdAt,
        updatedAt,
      ];

  /// Verifica si el perfil está completo para ofrecer servicios
  bool get isProfileComplete {
    return name.isNotEmpty &&
           email.isNotEmpty &&
           phoneNumber != null && phoneNumber!.isNotEmpty &&
           bio != null && bio!.isNotEmpty &&
           location != null && location!.isNotEmpty;
  }
} 