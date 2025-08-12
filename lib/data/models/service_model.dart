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
    super.whatsappNumber,
    super.instagram,
    super.xProfile,
    super.tiktok,
    super.callPhones = const [],
    super.mainImage,
    required super.images,
    required super.tags,
    required super.features,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required super.rating,
    required super.reviewCount,
    super.address,
    super.location,

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
      whatsappNumber: entity.whatsappNumber,
      instagram: entity.instagram,
      xProfile: entity.xProfile,
      tiktok: entity.tiktok,
      callPhones: entity.callPhones,
      mainImage: entity.mainImage,
      images: entity.images,
      tags: entity.tags,
      features: entity.features,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      rating: entity.rating,
      reviewCount: entity.reviewCount,
      address: entity.address,
      location: entity.location,

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
      whatsappNumber: json['whatsappNumber'],
      instagram: json['instagram'],
      xProfile: json['xProfile'],
      tiktok: json['tiktok'],
      callPhones: List<String>.from(json['callPhones'] ?? const []),
      mainImage: json['mainImage'],
      images: List<String>.from(json['images'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      features: List<String>.from(json['features'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: (json['reviewCount'] ?? 0).toInt(),
      address: json['address'],
      location: json['location'] != null ? Map<String, dynamic>.from(json['location']) : null,

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
      'whatsappNumber': whatsappNumber,
      'instagram': instagram,
      'xProfile': xProfile,
      'tiktok': tiktok,
      'callPhones': callPhones,
      'mainImage': mainImage,
      'images': images,
      'tags': tags,
      'features': features,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rating': rating,
      'reviewCount': reviewCount,
      'address': address,
      'location': location,

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
    String? whatsappNumber,
    String? instagram,
    String? xProfile,
    String? tiktok,
    List<String> callPhones = const [],
    String? mainImage,
    List<String> images = const [],
    List<String> tags = const [],
    List<String> features = const [],
    String? address,
    Map<String, dynamic>? location,

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
      whatsappNumber: whatsappNumber,
      instagram: instagram,
      xProfile: xProfile,
      tiktok: tiktok,
      callPhones: callPhones,
      mainImage: mainImage,
      images: images,
      tags: tags,
      features: features,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      rating: 0.0,
      reviewCount: 0,
      address: address,
      location: location,

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
    String? whatsappNumber,
    String? instagram,
    String? xProfile,
    String? tiktok,
    List<String>? callPhones,
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
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      instagram: instagram ?? this.instagram,
      xProfile: xProfile ?? this.xProfile,
      tiktok: tiktok ?? this.tiktok,
      callPhones: callPhones ?? this.callPhones,
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