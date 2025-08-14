import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../core/utils/location_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/service_model.dart';
import '../models/review_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/review_entity.dart';

class FirestoreService {
  static FirebaseFirestore? _firestore;

  // Constructor que inicializa Firestore automáticamente
  FirestoreService() {
    _initializeFirestore();
  }

  static void _initializeFirestore() {
    if (_firestore == null) {
      try {
        _firestore = FirebaseFirestore.instance;
        developer.log('✅ Firestore inicializado correctamente');
      } catch (e) {
        developer.log('⚠️ Error al inicializar Firestore: $e');
        rethrow;
      }
    }
  }

  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('Firestore no inicializado');
    }
    return _firestore!;
  }

  // === USUARIOS ===

  /// Crear o actualizar usuario en Firestore
  Future<void> createOrUpdateUser(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      await firestore
          .collection('users')
          .doc(user.id)
          .set(userModel.toJson(), SetOptions(merge: true));
      
      developer.log('✅ Usuario guardado en Firestore: ${user.email}');
    } catch (e) {
      developer.log('⚠️ Error al guardar usuario en Firestore: $e');
      rethrow;
    }
  }

  /// Obtener usuario por ID
  Future<UserEntity?> getUserById(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        developer.log('📄 Usuario no encontrado en Firestore: $userId');
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id; // Asegurar que el ID esté incluido
      
      final userModel = UserModel.fromJson(data);
      developer.log('✅ Usuario obtenido de Firestore: ${userModel.email}');
      
      return userModel;
    } catch (e) {
      developer.log('⚠️ Error al obtener usuario de Firestore: $e');
      rethrow;
    }
  }

  /// Obtener usuario por email
  Future<UserEntity?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        developer.log('📄 Usuario no encontrado por email: $email');
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      
      final userModel = UserModel.fromJson(data);
      developer.log('✅ Usuario encontrado por email: ${userModel.email}');
      
      return userModel;
    } catch (e) {
      developer.log('⚠️ Error al obtener usuario por email: $e');
      rethrow;
    }
  }

  /// Crear usuario desde Firebase User
  Future<UserEntity> createUserFromFirebaseUser(User firebaseUser) async {
    try {
      final userEntity = UserEntity(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        phoneNumber: firebaseUser.phoneNumber,
        bio: null, // Nuevo usuario, biografía vacía
        location: null, // Nuevo usuario, ubicación vacía
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await createOrUpdateUser(userEntity);
      developer.log('✅ Usuario creado desde Firebase User: ${userEntity.email}');
      
      return userEntity;
    } catch (e) {
      developer.log('⚠️ Error al crear usuario desde Firebase User: $e');
      rethrow;
    }
  }

  /// Eliminar usuario
  Future<void> deleteUser(String userId) async {
    try {
      await firestore.collection('users').doc(userId).delete();
      developer.log('✅ Usuario eliminado de Firestore: $userId');
    } catch (e) {
      developer.log('⚠️ Error al eliminar usuario: $e');
      rethrow;
    }
  }

  /// Obtener todos los usuarios
  Future<List<UserEntity>> getAllUsers() async {
    try {
      final querySnapshot = await firestore.collection('users').get();
      
      final users = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromJson(data) as UserEntity;
      }).toList();
      
      developer.log('✅ ${users.length} usuarios obtenidos de Firestore');
      return users;
    } catch (e) {
      developer.log('⚠️ Error al obtener todos los usuarios: $e');
      rethrow;
    }
  }

  // === SERVICIOS ===

  /// Crear o actualizar servicio en Firestore
  Future<void> createOrUpdateService(ServiceEntity service) async {
    try {
      final serviceModel = ServiceModel.fromEntity(service);
      await firestore
          .collection('services')
          .doc(service.id)
          .set(serviceModel.toJson(), SetOptions(merge: true));
      
      developer.log('✅ Servicio guardado en Firestore: ${service.title}');
    } catch (e) {
      developer.log('⚠️ Error al guardar servicio en Firestore: $e');
      rethrow;
    }
  }

  /// Obtener servicio por ID
  Future<ServiceEntity?> getServiceById(String serviceId) async {
    try {
      final doc = await firestore.collection('services').doc(serviceId).get();
      
      if (!doc.exists) {
        developer.log('📄 Servicio no encontrado en Firestore: $serviceId');
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      
      final serviceModel = ServiceModel.fromJson(data);
      developer.log('✅ Servicio obtenido de Firestore: ${serviceModel.title}');
      
      return serviceModel;
    } catch (e) {
      developer.log('⚠️ Error al obtener servicio de Firestore: $e');
      rethrow;
    }
  }

  /// Obtener servicios por usuario
  Future<List<ServiceEntity>> getServicesByUserId(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection('services')
          .where('providerId', isEqualTo: userId)
          .get();

      final services = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ServiceModel.fromJson(data) as ServiceEntity;
      }).toList();
      
      // Ordenar en memoria por fecha de creación (más recientes primero)
      services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      developer.log('✅ ${services.length} servicios obtenidos para usuario: $userId');
      return services;
    } catch (e) {
      developer.log('⚠️ Error al obtener servicios por usuario: $e');
      rethrow;
    }
  }

  /// Obtener todos los servicios
  Future<List<ServiceEntity>> getAllServices() async {
    try {
      final querySnapshot = await firestore
          .collection('services')
          .orderBy('createdAt', descending: true)
          .get();
      
      final services = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ServiceModel.fromJson(data) as ServiceEntity;
      }).toList();
      
      developer.log('✅ ${services.length} servicios obtenidos de Firestore');
      return services;
    } catch (e) {
      developer.log('⚠️ Error al obtener todos los servicios: $e');
      rethrow;
    }
  }

  /// Obtener servicios disponibles (activos)
  Future<List<ServiceEntity>> getAvailableServices() async {
    try {
      final querySnapshot = await firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();

      final services = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ServiceModel.fromJson(data) as ServiceEntity;
      }).toList();
      
      // Ordenar en memoria por fecha de creación (más recientes primero)
      services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      developer.log('✅ ${services.length} servicios activos obtenidos');
      return services;
    } catch (e) {
      developer.log('⚠️ Error al obtener servicios disponibles: $e');
      rethrow;
    }
  }

  /// Buscar servicios por criterios
  Future<List<ServiceEntity>> searchServices({
    String? query,
    String? category,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
    String? priceType,
    double? minRating,
    String? sortBy,
    double? radiusKm,
    double? userLatitude,
    double? userLongitude,
    int limit = 20,
  }) async {
    try {
      Query firestoreQuery = firestore.collection('services');

      if (category != null && category.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('category', isEqualTo: category);
      }

      // Si llegan múltiples categorías, obtener por categoría simple (siempre y cuando exista índice)
      // y luego filtrar en memoria por el conjunto completo

      if (minPrice != null) {
        firestoreQuery = firestoreQuery.where('price', isGreaterThanOrEqualTo: minPrice);
      }

      if (maxPrice != null) {
        firestoreQuery = firestoreQuery.where('price', isLessThanOrEqualTo: maxPrice);
      }

      if (priceType != null && priceType.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('priceType', isEqualTo: priceType);
      }

      // Aplicar limit primero, sin orderBy para evitar índices compuestos
      final querySnapshot = await firestoreQuery
          .limit(limit)
          .get();

      var services = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ServiceModel.fromJson(data) as ServiceEntity;
      }).toList();

      // Filtro en memoria para múltiples categorías (cualquiera de ellas)
      if (categories != null && categories.isNotEmpty) {
        final categorySet = categories.toSet();
        services = services.where((s) => categorySet.contains(s.category)).toList();
      }
      
      // Filtrar por rating mínimo en memoria
      if (minRating != null && minRating > 0) {
        services = services.where((s) => s.rating >= minRating).toList();
      }

      // Si hay radio y posición del usuario, filtrar por distancia
      if (radiusKm != null && radiusKm > 0 && userLatitude != null && userLongitude != null) {
        services = services.where((s) {
          final loc = s.location;
          if (loc == null) return false;
          final lat = (loc['latitude'] ?? loc['lat'])?.toDouble();
          final lon = (loc['longitude'] ?? loc['lng'] ?? loc['lon'])?.toDouble();
          if (lat == null || lon == null) return false;
          final distance = LocationUtils.calculateDistance(userLatitude, userLongitude, lat, lon);
          return distance <= radiusKm;
        }).toList();
      }

      // Ordenamientos soportados: newest (default), price asc/desc, rating, distance
      switch (sortBy) {
        case 'priceLowToHigh':
          services.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'priceHighToLow':
          services.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'rating':
          services.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'distance':
          if (userLatitude != null && userLongitude != null) {
            services.sort((a, b) {
              double dA = 1e9;
              double dB = 1e9;
              if (a.location != null) {
                final la = (a.location!['latitude'] ?? a.location!['lat'])?.toDouble();
                final lo = (a.location!['longitude'] ?? a.location!['lng'] ?? a.location!['lon'])?.toDouble();
                if (la != null && lo != null) {
                  dA = LocationUtils.calculateDistance(userLatitude, userLongitude, la, lo);
                }
              }
              if (b.location != null) {
                final lb = (b.location!['latitude'] ?? b.location!['lat'])?.toDouble();
                final lob = (b.location!['longitude'] ?? b.location!['lng'] ?? b.location!['lon'])?.toDouble();
                if (lb != null && lob != null) {
                  dB = LocationUtils.calculateDistance(userLatitude, userLongitude, lb, lob);
                }
              }
              return dA.compareTo(dB);
            });
          }
          break;
        case 'newest':
        default:
          services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      
      developer.log('✅ ${services.length} servicios encontrados con filtros');
      return services;
    } catch (e) {
      developer.log('⚠️ Error en búsqueda de servicios: $e');
      rethrow;
    }
  }

  /// Eliminar servicio
  Future<void> deleteService(String serviceId) async {
    try {
      developer.log('🗑️ Iniciando eliminación del servicio: $serviceId');
      
      // Verificar que el usuario esté autenticado
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      developer.log('👤 Usuario autenticado: ${currentUser.uid}');
      
      // Verificar que el servicio existe antes de eliminar
      final serviceDoc = await firestore.collection('services').doc(serviceId).get();
      if (!serviceDoc.exists) {
        throw Exception('Servicio no encontrado');
      }
      
      developer.log('📄 Servicio encontrado, propietario: ${serviceDoc.data()?['providerId']}');
      
      await firestore.collection('services').doc(serviceId).delete();
      developer.log('✅ Servicio eliminado de Firestore: $serviceId');
    } catch (e) {
      developer.log('⚠️ Error al eliminar servicio: $e');
      rethrow;
    }
  }

  /// Stream de cambios en servicios del usuario
  Stream<List<ServiceEntity>> watchUserServices(String userId) {
    try {
      return firestore
          .collection('services')
          .where('providerId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        final services = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ServiceModel.fromJson(data) as ServiceEntity;
        }).toList();
        
        // Ordenar en memoria por fecha de creación (más recientes primero)
        services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return services;
      });
    } catch (e) {
      developer.log('⚠️ Error en stream de servicios del usuario: $e');
      rethrow;
    }
  }

  /// Stream de cambios en todos los servicios
  Stream<List<ServiceEntity>> watchAllServices() {
    try {
      return firestore
          .collection('services')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ServiceModel.fromJson(data) as ServiceEntity;
        }).toList();
      });
    } catch (e) {
      developer.log('⚠️ Error en stream de todos los servicios: $e');
      rethrow;
    }
  }

  // === MÉTODOS PARA COMPATIBILIDAD CON SERVICE_REPOSITORY ===

  /// Crear servicio (alias para createOrUpdateService que devuelve el ID)
  Future<String> createService(ServiceEntity service) async {
    try {
      // Generar un ID único si no tiene uno
      final serviceId = service.id.isEmpty 
          ? firestore.collection('services').doc().id 
          : service.id;
      
      // Crear una nueva entidad con el ID asignado
      final serviceWithId = ServiceEntity(
        id: serviceId,
        title: service.title,
        description: service.description,
        category: service.category,
        price: service.price,
        priceType: service.priceType,
        providerId: service.providerId,
        providerName: service.providerName,
        providerPhotoUrl: service.providerPhotoUrl,
        whatsappNumber: service.whatsappNumber,
        instagram: service.instagram,
        xProfile: service.xProfile,
        tiktok: service.tiktok,
        callPhones: service.callPhones,
        mainImage: service.mainImage,
        images: service.images,
        tags: service.tags,
        features: service.features,
        isActive: service.isActive,
        createdAt: service.createdAt,
        updatedAt: DateTime.now(),
        rating: service.rating,
        reviewCount: service.reviewCount,
        address: service.address,
        location: service.location,

        availableDays: service.availableDays,
        timeRange: service.timeRange,
      );

      await createOrUpdateService(serviceWithId);
      developer.log('✅ Servicio creado con ID: $serviceId');
      return serviceId;
    } catch (e) {
      developer.log('⚠️ Error al crear servicio: $e');
      rethrow;
    }
  }

  /// Actualizar servicio (alias para createOrUpdateService)
  Future<void> updateService(ServiceEntity service) async {
    try {
      final updatedService = ServiceEntity(
        id: service.id,
        title: service.title,
        description: service.description,
        category: service.category,
        price: service.price,
        priceType: service.priceType,
        providerId: service.providerId,
        providerName: service.providerName,
        providerPhotoUrl: service.providerPhotoUrl,
        whatsappNumber: service.whatsappNumber,
        instagram: service.instagram,
        xProfile: service.xProfile,
        tiktok: service.tiktok,
        callPhones: service.callPhones,
        mainImage: service.mainImage,
        images: service.images,
        tags: service.tags,
        features: service.features,
        isActive: service.isActive,
        createdAt: service.createdAt,
        updatedAt: DateTime.now(),
        rating: service.rating,
        reviewCount: service.reviewCount,
        address: service.address,
        location: service.location,

        availableDays: service.availableDays,
        timeRange: service.timeRange,
      );

      await createOrUpdateService(updatedService);
      developer.log('✅ Servicio actualizado: ${service.id}');
    } catch (e) {
      developer.log('⚠️ Error al actualizar servicio: $e');
      rethrow;
    }
  }

  /// Obtener servicios por proveedor (alias para getServicesByUserId)
  Future<List<ServiceEntity>> getServicesByProvider(String providerId) async {
    try {
      return await getServicesByUserId(providerId);
    } catch (e) {
      developer.log('⚠️ Error al obtener servicios por proveedor: $e');
      rethrow;
    }
  }

  // === RESEÑAS ===

  /// Crear una nueva reseña
  Future<String> createReview(ReviewEntity review) async {
    try {
      developer.log('📝 Creando reseña para servicio: ${review.serviceId}');
      
      final reviewModel = ReviewModel.fromEntity(review);
      
      // Usar el userId como ID del documento para garantizar una reseña por usuario
      final docRef = firestore
          .collection('services')
          .doc(review.serviceId)
          .collection('reviews')
          .doc(review.userId);
      
      await docRef.set(reviewModel.toJson());
      
      developer.log('✅ Reseña creada con ID: ${review.userId}');
      return review.userId;
    } catch (e) {
      developer.log('⚠️ Error al crear reseña: $e');
      rethrow;
    }
  }

  /// Obtener reseñas de un servicio específico
  Future<List<ReviewEntity>> getServiceReviews(String serviceId, {int limit = 20}) async {
    try {
      developer.log('📖 Obteniendo reseñas del servicio: $serviceId');
      
      final querySnapshot = await firestore
          .collection('services')
          .doc(serviceId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc).toEntity())
          .toList();
      
      developer.log('✅ ${reviews.length} reseñas encontradas');
      return reviews;
    } catch (e) {
      developer.log('⚠️ Error al obtener reseñas: $e');
      return []; // Retornar lista vacía en caso de error
    }
  }

  /// Obtener reseña específica por ID
  Future<ReviewEntity?> getReviewById(String reviewId) async {
    try {
      // Nota: Esto requiere conocer el serviceId. Para simplificar, usaremos una consulta
      final querySnapshot = await firestore
          .collectionGroup('reviews')
          .where(FieldPath.documentId, isEqualTo: reviewId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return ReviewModel.fromFirestore(querySnapshot.docs.first).toEntity();
    } catch (e) {
      developer.log('⚠️ Error al obtener reseña por ID: $e');
      return null;
    }
  }

  /// Actualizar una reseña existente
  Future<void> updateReview(ReviewEntity review) async {
    try {
      developer.log('📝 Actualizando reseña: ${review.id}');
      
      final reviewModel = ReviewModel.fromEntity(review);
      await firestore
          .collection('services')
          .doc(review.serviceId)
          .collection('reviews')
          .doc(review.id)
          .update(reviewModel.toJson());
      
      developer.log('✅ Reseña actualizada');
    } catch (e) {
      developer.log('⚠️ Error al actualizar reseña: $e');
      rethrow;
    }
  }

  /// Eliminar una reseña
  Future<void> deleteReview(String reviewId) async {
    try {
      // Eliminar de todas las subcolecciones reviews
      final querySnapshot = await firestore
          .collectionGroup('reviews')
          .where(FieldPath.documentId, isEqualTo: reviewId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
        developer.log('✅ Reseña eliminada');
      }
    } catch (e) {
      developer.log('⚠️ Error al eliminar reseña: $e');
      rethrow;
    }
  }

  /// Verificar si un usuario ya reseñó un servicio
  Future<bool> hasUserReviewedService(String userId, String serviceId) async {
    try {
      final docSnapshot = await firestore
          .collection('services')
          .doc(serviceId)
          .collection('reviews')
          .doc(userId)
          .get();
      
      return docSnapshot.exists;
    } catch (e) {
      developer.log('⚠️ Error al verificar reseña existente: $e');
      return false;
    }
  }

  /// Obtener la reseña específica de un usuario para un servicio
  Future<ReviewEntity?> getUserReviewForService(String serviceId, String userId) async {
    try {
      final docSnapshot = await firestore
          .collection('services')
          .doc(serviceId)
          .collection('reviews')
          .doc(userId)
          .get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      return ReviewModel.fromFirestore(docSnapshot).toEntity();
    } catch (e) {
      developer.log('⚠️ Error al obtener reseña del usuario: $e');
      return null;
    }
  }

  /// Obtener estadísticas de reseñas de un servicio
  Future<Map<String, dynamic>> getServiceReviewStats(String serviceId) async {
    try {
      final querySnapshot = await firestore
          .collection('services')
          .doc(serviceId)
          .collection('reviews')
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': {
            '5': 0,
            '4': 0,
            '3': 0,
            '2': 0,
            '1': 0,
          },
        };
      }
      
      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc).toEntity())
          .toList();
      
      final totalRating = reviews.fold<double>(
        0.0,
        (accumulator, review) => accumulator + review.rating,
      );
      
      final averageRating = totalRating / reviews.length;
      
      final ratingDistribution = <String, int>{
        '5': 0,
        '4': 0,
        '3': 0,
        '2': 0,
        '1': 0,
      };
      
      for (final review in reviews) {
        final rating = review.rating.round().toString();
        ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
      }
      
      return {
        'averageRating': averageRating,
        'totalReviews': reviews.length,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      developer.log('⚠️ Error al obtener estadísticas de reseñas: $e');
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': {
          '5': 0,
          '4': 0,
          '3': 0,
          '2': 0,
          '1': 0,
        },
      };
    }
  }
}