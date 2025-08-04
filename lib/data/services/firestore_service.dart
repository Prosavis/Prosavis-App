import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';
import '../models/service_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/service_entity.dart';

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
        name: firebaseUser.displayName ?? 'Usuario',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        phoneNumber: firebaseUser.phoneNumber,
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
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final services = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ServiceModel.fromJson(data) as ServiceEntity;
      }).toList();
      
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

  /// Obtener servicios disponibles (no asignados)
  Future<List<ServiceEntity>> getAvailableServices() async {
    try {
      final querySnapshot = await firestore
          .collection('services')
          .where('isAssigned', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final services = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ServiceModel.fromJson(data) as ServiceEntity;
      }).toList();
      
      developer.log('✅ ${services.length} servicios disponibles obtenidos');
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
    String? location,
    double? minPrice,
    double? maxPrice,
    String? priceType,
    int limit = 20,
  }) async {
    try {
      Query firestoreQuery = firestore.collection('services');

      if (category != null && category.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('category', isEqualTo: category);
      }

      if (location != null && location.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('location', isEqualTo: location);
      }

      if (minPrice != null) {
        firestoreQuery = firestoreQuery.where('price', isGreaterThanOrEqualTo: minPrice);
      }

      if (maxPrice != null) {
        firestoreQuery = firestoreQuery.where('price', isLessThanOrEqualTo: maxPrice);
      }

      if (priceType != null && priceType.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('priceType', isEqualTo: priceType);
      }

      final querySnapshot = await firestoreQuery
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final services = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ServiceModel.fromJson(data) as ServiceEntity;
      }).toList();
      
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
          .where('userId', isEqualTo: userId)
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
        images: service.images,
        tags: service.tags,
        isActive: service.isActive,
        createdAt: service.createdAt,
        updatedAt: DateTime.now(),
        rating: service.rating,
        reviewCount: service.reviewCount,
        address: service.address,
        location: service.location,
        availabilityRadius: service.availabilityRadius,
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
        images: service.images,
        tags: service.tags,
        isActive: service.isActive,
        createdAt: service.createdAt,
        updatedAt: DateTime.now(),
        rating: service.rating,
        reviewCount: service.reviewCount,
        address: service.address,
        location: service.location,
        availabilityRadius: service.availabilityRadius,
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
}