import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/favorite_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../models/favorite_model.dart';
import '../models/service_model.dart';

/// Cache simple en memoria por instancia para minimizar lecturas repetidas
final Map<String, ServiceEntity> _favoriteServicesCache = {};

class FavoriteRepositoryImpl implements FavoriteRepository {
  final FirebaseFirestore _firestore;

  FavoriteRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> addToFavorites({
    required String userId,
    required String serviceId,
  }) async {
    try {
      // Verificar si ya existe
      final existingQuery = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('serviceId', isEqualTo: serviceId)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        return existingQuery.docs.first.id;
      }

      // Crear nuevo favorito
      final favorite = FavoriteModel.createNew(
        userId: userId,
        serviceId: serviceId,
      );

      final docRef = await _firestore
          .collection('favorites')
          .add(favorite.toJson());

      return docRef.id;
    } catch (e) {
      throw Exception('Error al agregar a favoritos: $e');
    }
  }

  @override
  Future<void> removeFromFavorites({
    required String userId,
    required String serviceId,
  }) async {
    try {
      final query = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('serviceId', isEqualTo: serviceId)
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Error al quitar de favoritos: $e');
    }
  }

  @override
  Future<bool> isFavorite({
    required String userId,
    required String serviceId,
  }) async {
    try {
      final query = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('serviceId', isEqualTo: serviceId)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<FavoriteEntity>> getUserFavorites(String userId) async {
    try {
      final query = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return FavoriteModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener favoritos: $e');
    }
  }

  @override
  Future<List<ServiceEntity>> getUserFavoriteServices(String userId) async {
    try {
      // Obtener favoritos del usuario
      final favorites = await getUserFavorites(userId);
      
      if (favorites.isEmpty) {
        return [];
      }

      // Obtener IDs de servicios favoritos
      final serviceIds = favorites.map((f) => f.serviceId).toList();

      // Obtener servicios en lotes (Firestore tiene límite de 10 en whereIn)
      // Realizamos las lecturas en paralelo para reducir la latencia total.
      final List<Future<QuerySnapshot<Map<String, dynamic>>>> queryFutures = [];
      for (int i = 0; i < serviceIds.length; i += 10) {
        final batch = serviceIds.skip(i).take(10).toList();
        queryFutures.add(
          _firestore
              .collection('services')
              .where(FieldPath.documentId, whereIn: batch)
              .where('isActive', isEqualTo: true)
              .get(),
        );
      }

      final queryResults = await Future.wait(queryFutures);
      final List<ServiceEntity> services = queryResults
          .expand((query) => query.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return ServiceModel.fromJson(data);
              }))
          .toList();

      // Ordenar por fecha de favorito (más reciente primero) usando un mapa O(1)
      final Map<String, DateTime> serviceIdToCreatedAt = {
        for (final f in favorites) f.serviceId: f.createdAt,
      };
      services.sort((a, b) {
        final aDate = serviceIdToCreatedAt[a.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = serviceIdToCreatedAt[b.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return services;
    } catch (e) {
      throw Exception('Error al obtener servicios favoritos: $e');
    }
  }

  @override
  Future<void> cleanupInvalidFavorites(String userId) async {
    try {
      // Obtener todos los favoritos del usuario
      final favorites = await getUserFavorites(userId);
      
      if (favorites.isEmpty) return;

      // Verificar qué servicios siguen existiendo y activos
      final serviceIds = favorites.map((f) => f.serviceId).toList();
      final List<String> validServiceIds = [];

      // Verificar en lotes
      for (int i = 0; i < serviceIds.length; i += 10) {
        final batch = serviceIds.skip(i).take(10).toList();
        
        final query = await _firestore
            .collection('services')
            .where(FieldPath.documentId, whereIn: batch)
            .where('isActive', isEqualTo: true)
            .get();

        validServiceIds.addAll(query.docs.map((doc) => doc.id));
      }

      // Eliminar favoritos de servicios que ya no existen o están inactivos
      final favoritesToRemove = favorites
          .where((f) => !validServiceIds.contains(f.serviceId))
          .toList();

      for (final favorite in favoritesToRemove) {
        await removeFromFavorites(
          userId: userId,
          serviceId: favorite.serviceId,
        );
      }
    } catch (e) {
      // Error silencioso en limpieza automática
      // Error silencioso en limpieza automática - usando logging framework en producción
    }
  }

  @override
  Future<int> getFavoritesCount(String userId) async {
    try {
      final query = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      return query.docs.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Stream<List<FavoriteEntity>> watchUserFavorites(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return FavoriteModel.fromJson(data);
            }).toList());
  }

  @override
  Stream<List<ServiceEntity>> watchUserFavoriteServices(String userId) async* {
    await for (final favorites in watchUserFavorites(userId)) {
      if (favorites.isEmpty) {
        yield [];
        continue;
      }

      // IDs y fechas (para ordenar)
      final Map<String, DateTime> serviceIdToCreatedAt = {
        for (final f in favorites) f.serviceId: f.createdAt,
      };

      // Determinar qué servicios faltan en cache
      final List<String> needed = favorites
          .map((f) => f.serviceId)
          .where((id) => !_favoriteServicesCache.containsKey(id))
          .toList();

      if (needed.isNotEmpty) {
        final List<Future<QuerySnapshot<Map<String, dynamic>>>> queryFutures = [];
        for (int i = 0; i < needed.length; i += 10) {
          final batch = needed.skip(i).take(10).toList();
          queryFutures.add(_firestore
              .collection('services')
              .where(FieldPath.documentId, whereIn: batch)
              .where('isActive', isEqualTo: true)
              .get());
        }
        final results = await Future.wait(queryFutures);
        for (final query in results) {
          for (final doc in query.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            _favoriteServicesCache[doc.id] = ServiceModel.fromJson(data);
          }
        }
      }

      // Construir lista ordenada por createdAt desc y filtrar solo activos presentes
      final services = favorites
          .map((f) => _favoriteServicesCache[f.serviceId])
          .whereType<ServiceEntity>()
          .toList();

      services.sort((a, b) {
        final aDate = serviceIdToCreatedAt[a.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = serviceIdToCreatedAt[b.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      yield services;
    }
  }
}