import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.photoUrl,
    super.phoneNumber,
    required super.userType,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.bio,
    required super.skills,
    required super.rating,
    required super.reviewCount,
    super.address,
    super.location,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      photoUrl: json['photoUrl'],
      phoneNumber: json['phoneNumber'],
      userType: UserType.values.firstWhere(
        (e) => e.name == json['userType'],
        orElse: () => UserType.client,
      ),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt']),
      bio: json['bio'],
      skills: List<String>.from(json['skills'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      address: json['address'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'userType': userType.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'bio': bio,
      'skills': skills,
      'rating': rating,
      'reviewCount': reviewCount,
      'address': address,
      'location': location,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      photoUrl: entity.photoUrl,
      phoneNumber: entity.phoneNumber,
      userType: entity.userType,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      bio: entity.bio,
      skills: entity.skills,
      rating: entity.rating,
      reviewCount: entity.reviewCount,
      address: entity.address,
      location: entity.location,
    );
  }

  @override
  UserModel copyWith({
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
    return UserModel(
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