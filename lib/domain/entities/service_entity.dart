import 'package:equatable/equatable.dart';

class ServiceEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final double price;
  final String priceType; // 'fixed', 'hourly', 'negotiable'
  final String providerId;
  final String providerName;
  final String? providerPhotoUrl;
  final List<String> images;
  final List<String> tags;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double rating;
  final int reviewCount;
  final String? address;
  final Map<String, dynamic>? location;
  final int availabilityRadius; // en km
  final List<String> availableDays;
  final String? timeRange; // "09:00-17:00"

  const ServiceEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.priceType,
    required this.providerId,
    required this.providerName,
    this.providerPhotoUrl,
    required this.images,
    required this.tags,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.rating,
    required this.reviewCount,
    this.address,
    this.location,
    required this.availabilityRadius,
    required this.availableDays,
    this.timeRange,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        price,
        priceType,
        providerId,
        providerName,
        providerPhotoUrl,
        images,
        tags,
        isActive,
        createdAt,
        updatedAt,
        rating,
        reviewCount,
        address,
        location,
        availabilityRadius,
        availableDays,
        timeRange,
      ];

  ServiceEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? price,
    String? priceType,
    String? providerId,
    String? providerName,
    String? providerPhotoUrl,
    List<String>? images,
    List<String>? tags,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating,
    int? reviewCount,
    String? address,
    Map<String, dynamic>? location,
    int? availabilityRadius,
    List<String>? availableDays,
    String? timeRange,
  }) {
    return ServiceEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerPhotoUrl: providerPhotoUrl ?? this.providerPhotoUrl,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      address: address ?? this.address,
      location: location ?? this.location,
      availabilityRadius: availabilityRadius ?? this.availabilityRadius,
      availableDays: availableDays ?? this.availableDays,
      timeRange: timeRange ?? this.timeRange,
    );
  }
} 