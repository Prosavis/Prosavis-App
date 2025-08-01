import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';
import '../models/service_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/service_entity.dart';

class FirestoreService {
  static FirebaseFirestore? _firestore;
  static bool _isDevelopmentMode = false;
  static final Map<String, UserModel> _mockUsers = {};
  static final Map<String, ServiceModel> _mockServices = {};

  // Constructor que inicializa Firestore automáticamente
  FirestoreService() {
    _initializeFirestore();
  }

  static void _initializeFirestore() {
    if (!_isDevelopmentMode && _firestore == null) {
      try {
        _firestore = FirebaseFirestore.instance;
        developer.log('✅ Firestore inicializado correctamente');
      } catch (e) {
        developer.log('⚠️ Error al inicializar Firestore: $e');
        _isDevelopmentMode = true;
      }
    }
  }

  static void setDevelopmentMode(bool isDev) {
    _isDevelopmentMode = isDev;
    if (!isDev) {
      _initializeFirestore();
    }
  }

  static FirebaseFirestore? get firestore => _isDevelopmentMode ? null : _firestore;

  // === USUARIOS ===

  /// Crear o actualizar usuario en Firestore
  Future<void> createOrUpdateUser(UserEntity user) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Guardando usuario mock');
      _mockUsers[user.id] = UserModel.fromEntity(user);
      return;
    }

    try {
      if (_firestore == null) {
        throw Exception('Firestore no inicializado');
      }

      final userModel = UserModel.fromEntity(user);
      await _firestore!
          .collection('users')
          .doc(user.id)
          .set(userModel.toJson(), SetOptions(merge: true));
      
      developer.log('✅ Usuario guardado en Firestore: ${user.email}');
    } catch (e) {
      developer.log('⚠️ Error al guardar usuario en Firestore: $e');
      // Fallback a modo desarrollo
      _isDevelopmentMode = true;
      _mockUsers[user.id] = UserModel.fromEntity(user);
    }
  }

  /// Obtener usuario por ID
  Future<UserEntity?> getUserById(String userId) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Obteniendo usuario mock');
      return _mockUsers[userId];
    }

    try {
      if (_firestore == null) {
        throw Exception('Firestore no inicializado');
      }

      final doc = await _firestore!.collection('users').doc(userId).get();
      
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
      // Fallback a modo desarrollo
      _isDevelopmentMode = true;
      return _mockUsers[userId];
    }
  }

  /// Obtener usuario por email
  Future<UserEntity?> getUserByEmail(String email) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Buscando usuario mock por email');
      try {
        return _mockUsers.values.firstWhere((user) => user.email == email);
      } catch (e) {
        return null;
      }
    }

    try {
      if (_firestore == null) {
        throw Exception('Firestore no inicializado');
      }

      final querySnapshot = await _firestore!
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        developer.log('📄 Usuario no encontrado por email en Firestore: $email');
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id; // Asegurar que el ID esté incluido

      final userModel = UserModel.fromJson(data);
      developer.log('✅ Usuario encontrado por email en Firestore: ${userModel.email}');
      
      return userModel;
    } catch (e) {
      developer.log('⚠️ Error al buscar usuario por email en Firestore: $e');
      // Fallback a modo desarrollo
      _isDevelopmentMode = true;
      try {
        return _mockUsers.values.firstWhere((user) => user.email == email);
      } catch (e) {
        return null;
      }
    }
  }

  /// Crear usuario desde FirebaseUser
  Future<UserEntity> createUserFromFirebaseUser(User firebaseUser) async {
    final now = DateTime.now();
    
    final userEntity = UserEntity(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Usuario',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
      phoneNumber: firebaseUser.phoneNumber,
      createdAt: now,
      updatedAt: now,
    );

    await createOrUpdateUser(userEntity);
    return userEntity;
  }

  /// Eliminar usuario
  Future<void> deleteUser(String userId) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Eliminando usuario mock');
      _mockUsers.remove(userId);
      return;
    }

    try {
      if (_firestore == null) {
        throw Exception('Firestore no inicializado');
      }

      await _firestore!.collection('users').doc(userId).delete();
      developer.log('✅ Usuario eliminado de Firestore: $userId');
    } catch (e) {
      developer.log('⚠️ Error al eliminar usuario de Firestore: $e');
      // Fallback a modo desarrollo
      _isDevelopmentMode = true;
      _mockUsers.remove(userId);
    }
  }

  // === SERVICIOS ===

  /// Crear servicio en Firestore
  Future<String> createService(ServiceEntity service) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Guardando servicio mock');
      final serviceId = 'service_${DateTime.now().millisecondsSinceEpoch}';
      final serviceModel = ServiceModel.fromEntity(service).copyWithModel(id: serviceId);
      _mockServices[serviceId] = serviceModel;
      return serviceId;
    }

    try {
      if (_firestore == null) {
        throw Exception('Firestore no inicializado');
      }

      final serviceModel = ServiceModel.fromEntity(service);
      final docRef = await _firestore!
          .collection('services')
          .add(serviceModel.toJson());
      
      // Actualizar el documento con su ID
      await docRef.update({'id': docRef.id});
      
      developer.log('✅ Servicio guardado en Firestore: ${service.title}');
      return docRef.id;
    } catch (e) {
      developer.log('⚠️ Error al guardar servicio en Firestore: $e');
      // Fallback a modo desarrollo
      _isDevelopmentMode = true;
      final serviceId = 'service_${DateTime.now().millisecondsSinceEpoch}';
      final serviceModel = ServiceModel.fromEntity(service).copyWithModel(id: serviceId);
      _mockServices[serviceId] = serviceModel;
      return serviceId;
    }
  }

  /// Obtener servicio por ID
  Future<ServiceEntity?> getServiceById(String serviceId) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Obteniendo servicio mock');
      return _mockServices[serviceId];
    }

    try {
      if (_firestore == null) {
        throw Exception('Firestore no inicializado');
      }

      final doc = await _firestore!.collection('services').doc(serviceId).get();
      
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
      _isDevelopmentMode = true;
      return _mockServices[serviceId];
    }
  }

  /// Buscar servicios por query de texto
  Future<List<ServiceEntity>> searchServices({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? priceType,
    int limit = 20,
  }) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Buscando servicios mock');
      var services = _mockServices.values.where((service) => service.isActive);
      
      if (query != null && query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        services = services.where((service) =>
          service.title.toLowerCase().contains(queryLower) ||
          service.description.toLowerCase().contains(queryLower) ||
          service.category.toLowerCase().contains(queryLower) ||
          service.tags.any((tag) => tag.toLowerCase().contains(queryLower))
        );
      }
      
      if (category != null && category.isNotEmpty) {
        services = services.where((service) => service.category == category);
      }
      
      if (minPrice != null) {
        services = services.where((service) => service.price >= minPrice);
      }
      
      if (maxPrice != null) {
        services = services.where((service) => service.price <= maxPrice);
      }
      
      if (priceType != null) {
        services = services.where((service) => service.priceType == priceType);
      }
      
      return services.take(limit).toList();
    }

    try {
      if (_firestore == null) {
        throw Exception('Firestore no inicializado');
      }

      Query<Map<String, dynamic>> queryRef = _firestore!.collection('services');
      
      // Filtrar por activos
      queryRef = queryRef.where('isActive', isEqualTo: true);
      
      // Filtrar por categoría si se especifica
      if (category != null && category.isNotEmpty) {
        queryRef = queryRef.where('category', isEqualTo: category);
      }
      
      // Filtrar por tipo de precio si se especifica
      if (priceType != null) {
        queryRef = queryRef.where('priceType', isEqualTo: priceType);
      }
      
      // Filtrar por rango de precios
      if (minPrice != null) {
        queryRef = queryRef.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      
      if (maxPrice != null) {
        queryRef = queryRef.where('price', isLessThanOrEqualTo: maxPrice);
      }
      
      // Aplicar límite
      queryRef = queryRef.limit(limit);
      
      final querySnapshot = await queryRef.get();
      
      final List<ServiceEntity> services = [];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        
        final serviceModel = ServiceModel.fromJson(data);
        
        // Filtrar por texto si se especifica (se hace en cliente para mejor flexibilidad)
        if (query != null && query.isNotEmpty) {
          final queryLower = query.toLowerCase();
          if (serviceModel.title.toLowerCase().contains(queryLower) ||
              serviceModel.description.toLowerCase().contains(queryLower) ||
              serviceModel.category.toLowerCase().contains(queryLower) ||
              serviceModel.tags.any((tag) => tag.toLowerCase().contains(queryLower))) {
            services.add(serviceModel);
          }
        } else {
          services.add(serviceModel);
        }
      }
      
      developer.log('✅ Encontrados ${services.length} servicios en Firestore');
      return services;
    } catch (e) {
      developer.log('⚠️ Error al buscar servicios en Firestore: $e');
      _isDevelopmentMode = true;
      return searchServices(
        query: query,
        category: category,
        minPrice: minPrice,
        maxPrice: maxPrice,
        priceType: priceType,
        limit: limit,
      );
    }
  }

  /// Obtener servicios por proveedor
  Future<List<ServiceEntity>> getServicesByProvider(String providerId) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Obteniendo servicios del proveedor mock');
      return _mockServices.values
          .where((service) => service.providerId == providerId)
          .toList();
    }

    try {
      if (_firestore == null) {
        throw Exception('Firestore no inicializado');
      }

      final querySnapshot = await _firestore!
          .collection('services')
          .where('providerId', isEqualTo: providerId)
          .get();

      final List<ServiceEntity> services = [];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        services.add(ServiceModel.fromJson(data));
      }
      
      developer.log('✅ Encontrados ${services.length} servicios del proveedor en Firestore');
      return services;
    } catch (e) {
      developer.log('⚠️ Error al obtener servicios del proveedor de Firestore: $e');
      _isDevelopmentMode = true;
      return _mockServices.values
          .where((service) => service.providerId == providerId)
          .toList();
    }
  }

  /// Actualizar servicio
  Future<void> updateService(ServiceEntity service) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Actualizando servicio mock');
      _mockServices[service.id] = ServiceModel.fromEntity(service);
      return;
    }

    try {
      if (_firestore == null) {
        throw Exception('Firestore no inicializado');
      }

      final serviceModel = ServiceModel.fromEntity(service);
      await _firestore!
          .collection('services')
          .doc(service.id)
          .update(serviceModel.toJson());
      
      developer.log('✅ Servicio actualizado en Firestore: ${service.title}');
    } catch (e) {
      developer.log('⚠️ Error al actualizar servicio en Firestore: $e');
      _isDevelopmentMode = true;
      _mockServices[service.id] = ServiceModel.fromEntity(service);
    }
  }

  /// Eliminar servicio (soft delete)
  Future<void> deleteService(String serviceId) async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Eliminando servicio mock');
      _mockServices.remove(serviceId);
      return;
    }

    try {
      if (_firestore == null) {
        throw Exception('Firestore no inicializado');
      }

      await _firestore!.collection('services').doc(serviceId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
      
      developer.log('✅ Servicio eliminado de Firestore: $serviceId');
    } catch (e) {
      developer.log('⚠️ Error al eliminar servicio de Firestore: $e');
      _isDevelopmentMode = true;
      _mockServices.remove(serviceId);
    }
  }

  // === UTILIDADES ===

  /// Verificar conectividad con Firestore
  Future<bool> testConnection() async {
    if (_isDevelopmentMode) {
      developer.log('🔧 Modo desarrollo: Simulando conexión exitosa');
      return true;
    }

    try {
      if (_firestore == null) {
        return false;
      }

      // Intentar hacer una consulta simple
      await _firestore!.collection('_test').limit(1).get();
      developer.log('✅ Conexión con Firestore exitosa');
      return true;
    } catch (e) {
      developer.log('⚠️ Error de conectividad con Firestore: $e');
      return false;
    }
  }

  /// Limpiar datos de desarrollo
  static void clearMockData() {
    _mockUsers.clear();
    _mockServices.clear();
    developer.log('🔧 Datos mock limpiados');
  }

  // === GETTERS ===
  static bool get isDevelopmentMode => _isDevelopmentMode;
  static Map<String, UserModel> get mockUsers => Map.from(_mockUsers);
  static Map<String, ServiceModel> get mockServices => Map.from(_mockServices);
}