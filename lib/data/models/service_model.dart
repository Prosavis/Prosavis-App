import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/service_entity.dart';

class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.price,
    required super.priceType,
    required super.providerId,
    required super.providerName,
    super.providerPhotoUrl,
    required super.images,
    required super.tags,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required super.rating,
    required super.reviewCount,
    super.address,
    super.location,
    required super.availabilityRadius,
    required super.availableDays,
    super.timeRange,
  });

  /// Crear ServiceModel desde ServiceEntity
  factory ServiceModel.fromEntity(ServiceEntity entity) {
    return ServiceModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      price: entity.price,
      priceType: entity.priceType,
      providerId: entity.providerId,
      providerName: entity.providerName,
      providerPhotoUrl: entity.providerPhotoUrl,
      images: entity.images,
      tags: entity.tags,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      rating: entity.rating,
      reviewCount: entity.reviewCount,
      address: entity.address,
      location: entity.location,
      availabilityRadius: entity.availabilityRadius,
      availableDays: entity.availableDays,
      timeRange: entity.timeRange,
    );
  }

  /// Crear ServiceModel desde JSON (Firestore)
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      priceType: json['priceType'] ?? 'fixed',
      providerId: json['providerId'] ?? '',
      providerName: json['providerName'] ?? '',
      providerPhotoUrl: json['providerPhotoUrl'],
      images: List<String>.from(json['images'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: (json['reviewCount'] ?? 0).toInt(),
      address: json['address'],
      location: json['location'] != null ? Map<String, dynamic>.from(json['location']) : null,
      availabilityRadius: (json['availabilityRadius'] ?? 10).toInt(),
      availableDays: List<String>.from(json['availableDays'] ?? []),
      timeRange: json['timeRange'],
    );
  }

  /// Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'priceType': priceType,
      'providerId': providerId,
      'providerName': providerName,
      'providerPhotoUrl': providerPhotoUrl,
      'images': images,
      'tags': tags,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rating': rating,
      'reviewCount': reviewCount,
      'address': address,
      'location': location,
      'availabilityRadius': availabilityRadius,
      'availableDays': availableDays,
      'timeRange': timeRange,
    };
  }

  /// Crear ServiceModel para nuevo servicio
  factory ServiceModel.createNew({
    required String title,
    required String description,
    required String category,
    required double price,
    required String priceType,
    required String providerId,
    required String providerName,
    String? providerPhotoUrl,
    List<String> images = const [],
    List<String> tags = const [],
    String? address,
    Map<String, dynamic>? location,
    int availabilityRadius = 10,
    required List<String> availableDays,
    String? timeRange,
  }) {
    final now = DateTime.now();
    return ServiceModel(
      id: '', // Se asignará al guardar en Firestore
      title: title,
      description: description,
      category: category,
      price: price,
      priceType: priceType,
      providerId: providerId,
      providerName: providerName,
      providerPhotoUrl: providerPhotoUrl,
      images: images,
      tags: tags,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      rating: 0.0,
      reviewCount: 0,
      address: address,
      location: location,
      availabilityRadius: availabilityRadius,
      availableDays: availableDays,
      timeRange: timeRange,
    );
  }

  /// Utility para parsear DateTime desde Firestore
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    
    return DateTime.now();
  }

  /// Crear copia con campos actualizados
  ServiceModel copyWithModel({
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
    return ServiceModel(
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