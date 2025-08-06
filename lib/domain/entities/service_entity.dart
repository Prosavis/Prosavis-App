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
  final String? mainImage; // Imagen principal del servicio
  final List<String> images; // Galería de trabajos
  final List<String> tags;
  final List<String> features; // Características/incluye del servicio
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double rating;
  final int reviewCount;
  final String? address;
  final Map<String, dynamic>? location;

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
    this.mainImage,
    required this.images,
    required this.tags,
    required this.features,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.rating,
    required this.reviewCount,
    this.address,
    this.location,

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
        mainImage,
        images,
        tags,
        features,
        isActive,
        createdAt,
        updatedAt,
        rating,
        reviewCount,
        address,
        location,

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
    String? mainImage,
    List<String>? images,
    List<String>? tags,
    List<String>? features,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating,
    int? reviewCount,
    String? address,
    Map<String, dynamic>? location,

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
      mainImage: mainImage ?? this.mainImage,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      address: address ?? this.address,
      location: location ?? this.location,

      availableDays: availableDays ?? this.availableDays,
      timeRange: timeRange ?? this.timeRange,
    );
  }
} 