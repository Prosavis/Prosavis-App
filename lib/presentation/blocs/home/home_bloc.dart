import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../domain/usecases/reviews/get_service_review_stats_usecase.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../data/services/firestore_service.dart';
import 'home_event.dart';
import 'home_state.dart';
import '../../../core/utils/location_utils.dart';
import '../location/location_bloc.dart';
import '../location/location_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetServiceReviewStatsUseCase _getServiceReviewStatsUseCase;
  final FirestoreService _firestoreService;
  final LocationBloc _locationBloc;

  HomeBloc({
    required GetServiceReviewStatsUseCase getServiceReviewStatsUseCase,
    required FirestoreService firestoreService,
    required LocationBloc locationBloc,
  }) : _getServiceReviewStatsUseCase = getServiceReviewStatsUseCase,
       _firestoreService = firestoreService,
       _locationBloc = locationBloc,
       super(HomeInitial()) {
    on<LoadHomeServices>(_onLoadHomeServices);
    on<RefreshHomeServices>(_onRefreshHomeServices);
  }

  Future<void> _onLoadHomeServices(
    LoadHomeServices event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    await _loadServices(emit);
  }

  Future<void> _onRefreshHomeServices(
    RefreshHomeServices event,
    Emitter<HomeState> emit,
  ) async {
    await _loadServices(emit);
  }

  Future<void> _loadServices(Emitter<HomeState> emit) async {
    try {
      developer.Timeline.startSync('home_load_services');
      
      // Obtener ubicación del usuario desde LocationBloc centralizado
      double? lat;
      double? lng;
      final locationState = _locationBloc.state;
      if (locationState is LocationLoaded) {
        lat = locationState.latitude;
        lng = locationState.longitude;
        developer.log('📍 Usando ubicación del LocationBloc: ${locationState.address}', name: 'HomeBloc');
      } else {
        // Fallback: intentar obtener desde cache si LocationBloc no tiene ubicación
        final userLocation = await LocationUtils.getCachedUserLocation();
        if (userLocation != null) {
          lat = userLocation['latitude'];
          lng = userLocation['longitude'];
          developer.log('📍 Usando ubicación desde cache como fallback', name: 'HomeBloc');
        } else {
          developer.log('⚠️ No hay ubicación disponible para servicios cercanos', name: 'HomeBloc');
        }
      }

      // Variables para almacenar resultados
      List<ServiceEntity> currentFeatured = [];
      List<ServiceEntity> currentNearby = [];
      
      // ESTRATEGIA CACHE-FIRST: Usar nuevos métodos optimizados
      await Future.wait([
        // Servicios destacados con cache-first
        _firestoreService.getFeaturedServicesWithCache(
          limit: 5,
          onData: (services, fromCache) async {
            developer.log(fromCache ? '⚡ Destacados del cache' : '🌐 Destacados de la red');
            
            // Optimizar estadísticas solo para datos frescos
            if (!fromCache) {
              services = await _optimizeServiceStats(services);
            }
            
            currentFeatured = services;
            emit(HomeLoaded(
              featuredServices: currentFeatured,
              nearbyServices: currentNearby,
              isFromCache: fromCache,
            ));
          },
        ),
        
        // Servicios cercanos con cache-first
        _firestoreService.getNearbyServicesWithCache(
          userLatitude: lat,
          userLongitude: lng,
          radiusKm: 15.0,
          limit: 6,
          onData: (services, fromCache) async {
            developer.log(fromCache ? '⚡ Cercanos del cache' : '🌐 Cercanos de la red');
            
            // Optimizar estadísticas solo para datos frescos
            if (!fromCache) {
              services = await _optimizeServiceStats(services);
            }
            
            currentNearby = services;
            emit(HomeLoaded(
              featuredServices: currentFeatured,
              nearbyServices: currentNearby,
              isFromCache: fromCache,
            ));
          },
        ),
      ]);

      developer.log('✅ Servicios optimizados cargados: ${currentFeatured.length} destacados, ${currentNearby.length} cercanos');

    } catch (e) {
      developer.log('❌ Error al cargar servicios: $e');
      emit(HomeError('Error al cargar servicios: ${e.toString()}'));
    } finally {
      developer.Timeline.finishSync();
    }
  }

  /// Optimizar estadísticas de servicios (solo para datos frescos)
  Future<List<ServiceEntity>> _optimizeServiceStats(List<ServiceEntity> services) async {
    return await Future.wait(services.map((service) async {
      try {
        final stats = await _getServiceReviewStatsUseCase(service.id);
        final total = (stats['totalReviews'] ?? 0) as int;
        final avg = (stats['averageRating'] ?? 0.0).toDouble();
        
        if (total == 0) return service; // mantener valores originales
        
        // Si el documento tiene valores desactualizados, usar stats reales
        if (service.reviewCount == 0 && total > 0) {
          return service.copyWith(rating: avg, reviewCount: total);
        }
        
        return service;
      } catch (e) {
        developer.log('⚠️ Error al obtener stats para servicio ${service.id}: $e');
        return service; // devolver servicio original si falla
      }
    }));
  }
}