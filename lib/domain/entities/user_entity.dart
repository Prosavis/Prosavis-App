import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? phoneNumber;
  final UserType userType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? bio;
  final List<String> skills;
  final double rating;
  final int reviewCount;
  final String? address;
  final Map<String, dynamic>? location; // lat, lng

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.phoneNumber,
    required this.userType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.bio,
    required this.skills,
    required this.rating,
    required this.reviewCount,
    this.address,
    this.location,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        photoUrl,
        phoneNumber,
        userType,
        isActive,
        createdAt,
        updatedAt,
        bio,
        skills,
        rating,
        reviewCount,
        address,
        location,
      ];

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? phoneNumber,
    UserType? userType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bio,
    List<String>? skills,
    double? rating,
    int? reviewCount,
    String? address,
    Map<String, dynamic>? location,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      address: address ?? this.address,
      location: location ?? this.location,
    );
  }
}

enum UserType { client, provider, both } 